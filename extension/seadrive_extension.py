import hashlib
import json
import os
import queue
import socket
import struct
import subprocess
import time
import urllib.parse
from collections import deque
from pathlib import Path

import gi

gi.require_version("Nautilus", "4.1")
from gi.repository import GLib, GObject, Nautilus

# Emblemas só em estados “ativos” (Nautilus 46+ coloca após o nome — evitar no idle).
EMBLEM_SYNCING = "emblem-seadrive-syncing"
EMBLEM_LOCKED_ME = "emblem-seadrive-locked-by-me"
EMBLEM_LOCKED_OTHERS = "emblem-seadrive-locked-by-others"

STATUS_ATTR = "seadrive_status"
# Sticky só após Always keep (não renovar com syncing de leitura sob demanda).
STICKY_DOWNLOAD_SEC = 120.0
STICKY_DIR_DOWNLOAD_SEC = 3600.0  # pastas com ISO/grande: sticky até o watch concluir
STATUS_CACHE_SEC = 2.0
# Enquanto o menu está aberto o Nautilus chama get_file_items em loop; reutilizar
# os mesmos MenuItem evita GC do item clicado (activate nunca dispara).
# TTL deslizante: cada cache hit renova — menu aberto > TTL não recria itens.
MENU_CACHE_SEC = 30.0
MENU_REF_GENERATIONS = 32
MENU_CACHE_MAX_PATHS = 64



class Transport:
    def __init__(self, pipe_path):
        self.pipe_path = pipe_path
        self.conn = None

    def connect(self):
        self.conn = socket.socket(socket.AF_UNIX)
        self.conn.connect(self.pipe_path)

    def stop(self):
        if self.conn:
            self.conn.close()
            self.conn = None

    def send(self, name, path):
        body = name + "\t" + path
        body_utf8 = body.encode(encoding="utf-8")
        header = struct.pack("=I", len(body_utf8))
        self.sendall(header)
        self.sendall(body_utf8)

        resp_header = self.recvall(4)
        resp_size, = struct.unpack("=I", resp_header)
        resp = self.recvall(resp_size)
        return resp.decode(encoding="utf-8")

    def recvall(self, total):
        remain = total
        data = bytearray()
        while remain > 0:
            new = self.conn.recv(remain)
            n = len(new)
            if n <= 0:
                raise RuntimeError("Failed to read from socket")
            data.extend(new)
            remain -= n
        return bytes(data)

    def sendall(self, data):
        total = len(data)
        offset = 0
        while offset < total:
            n = self.conn.send(data[offset:])
            if n <= 0:
                raise RuntimeError("Failed to write to socket")
            offset += n


class GuiConnection:
    def __init__(self, pipe_path, pool_size=5):
        self.pipe_path = pipe_path
        self.pool_size = pool_size
        self._pool = queue.Queue(pool_size)

    def _create_transport(self):
        transport = Transport(self.pipe_path)
        transport.connect()
        return transport

    def _get_transport(self):
        try:
            transport = self._pool.get(False)
        except Exception:
            transport = self._create_transport()
        return transport

    def _return_transport(self, transport):
        try:
            self._pool.put(transport, False)
        except queue.Full:
            transport.stop()

    def send(self, name, path):
        transport = self._get_transport()
        try:
            ret_str = transport.send(name, path)
        except Exception:
            transport.stop()
            raise
        self._return_transport(transport)
        return ret_str


class Account:
    def __init__(self, name, signature):
        self.name = name
        self.signature = signature


home_dir = str(Path.home())
mount_dir = home_dir + "/SeaDrive"
seafile_pipe_path = home_dir + "/.seadrive/seadrive_ext.sock"


class SeaDriveFileExtension(
    GObject.GObject,
    Nautilus.MenuProvider,
    Nautilus.InfoProvider,
    Nautilus.ColumnProvider,
):

    def __init__(self):
        super().__init__()
        self.conn = GuiConnection(seafile_pipe_path)
        # path -> expires_at: só setado por Always keep
        self._download_sticky = {}
        # path -> (expires_at, label, emblem)
        self._status_cache = {}
        # Evita GC dos MenuItem (Nautilus GTK4: clique sem efeito se o Python liberar).
        # Guarda várias gerações: get_file_items é chamado em loop com o menu aberto.
        self._menu_item_refs = deque(maxlen=MENU_REF_GENERATIONS)
        # path -> (expires_at, items)
        self._menu_cache = {}
        # path -> Nautilus.File visto em update_file_info (para invalidar filhos após pin/free)
        self._seen_files = {}

    def _remember_file(self, file_path, file_obj):
        if not file_obj or not hasattr(file_obj, "invalidate_extension_info"):
            return
        self._seen_files[file_path] = file_obj
        if len(self._seen_files) > 256:
            # remove entradas antigas (FIFO aproximado)
            for key in list(self._seen_files.keys())[:64]:
                self._seen_files.pop(key, None)

    def _path_to_uri(self, path):
        return Path(path).as_uri()

    def _lookup_file_info(self, path):
        """Obtém o FileInfo vivo do Nautilus (refs antigas não redesenham a coluna)."""
        uri = self._path_to_uri(path)
        try:
            fi = Nautilus.FileInfo.lookup_for_uri(uri)
            if fi is not None and not (hasattr(fi, "is_gone") and fi.is_gone()):
                return fi
        except Exception:
            pass
        fi = self._seen_files.get(path)
        if fi is not None:
            try:
                if hasattr(fi, "is_gone") and fi.is_gone():
                    self._seen_files.pop(path, None)
                    return None
            except Exception:
                pass
            return fi
        return None

    def _apply_label_to_path(self, path):
        self._status_cache.pop(path, None)
        label, _emblem = self._status_label(path)
        fi = self._lookup_file_info(path)
        if fi is None:
            return False
        try:
            fi.add_string_attribute(STATUS_ATTR, label)
            try:
                fi.invalidate_extension_info()
            except Exception:
                pass
            self._remember_file(path, fi)
            return True
        except Exception:
            return False

    def _refresh_seen_under(self, root_path):
        """Recalcula e empurra labels em root + filhos (pastas e arquivos)."""
        paths = {root_path}
        paths.update(
            p for p in self._seen_files if p == root_path or p.startswith(root_path + os.sep)
        )
        try:
            for dirpath, _dirnames, filenames in os.walk(root_path):
                paths.add(dirpath)
                for name in filenames:
                    paths.add(os.path.join(dirpath, name))
                if len(paths) > 400:
                    break
        except Exception:
            pass

        ok = 0
        for p in sorted(paths, key=lambda x: (os.path.isdir(x), -len(x))):
            if self._apply_label_to_path(p):
                ok += 1
        return ok

    def _retain_menu_items(self, items):
        self._menu_item_refs.append(list(items))

    def _cached_menu(self, file_path):
        row = self._menu_cache.get(file_path)
        if not row:
            return None
        expires, items = row
        if time.monotonic() > expires:
            self._menu_cache.pop(file_path, None)
            return None
        # Renova TTL enquanto o Nautilus fica pedindo o menu (evita rebuild no meio do clique).
        self._menu_cache[file_path] = (time.monotonic() + MENU_CACHE_SEC, items)
        return items

    def _store_menu(self, file_path, items):
        if len(self._menu_cache) >= MENU_CACHE_MAX_PATHS and file_path not in self._menu_cache:
            # Descarta a entrada mais antiga (aproximação FIFO pela ordem de inserção).
            oldest = next(iter(self._menu_cache))
            self._menu_cache.pop(oldest, None)
        self._menu_cache[file_path] = (time.monotonic() + MENU_CACHE_SEC, items)
        self._retain_menu_items(items)
        return items

    def _invalidate_menu(self, file_path):
        self._menu_cache.pop(file_path, None)

    def _item_name(self, suffix, file_path):
        digest = hashlib.sha1(file_path.encode("utf-8", errors="replace")).hexdigest()[:12]
        return f"SeaDriveExt::{suffix}::{digest}"

    def _notify(self, title, body):
        """Feedback visível sem Transfer Progress (que crasha o daemon 3.0.23)."""
        try:
            subprocess.Popen(
                ["notify-send", "-a", "SeaDrive", title, body],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except Exception:
            pass

    def _bind(self, item, handler, *user_args):
        def _on_activate(menu_item, *ignored, _handler=handler, _args=user_args):
            def _run():
                try:
                    _handler(menu_item, *_args)
                except Exception as e:
                    print(f"SeaDrive menu handler error {_handler.__name__}: {e}")
                return False

            # Devolve o controle ao GTK para o menu fechar; RPC pode ser lento.
            GLib.idle_add(_run)

        item.connect("activate", _on_activate)
        return item

    def get_columns(self):
        return [
            Nautilus.Column(
                name="SeaDriveExt::status",
                attribute=STATUS_ATTR,
                label="SeaDrive",
                description="Estado online / local / baixando",
            )
        ]

    def _mark_downloading(self, file_path, ttl=None):
        self._download_sticky[file_path] = time.monotonic() + (
            STICKY_DOWNLOAD_SEC if ttl is None else ttl
        )
        self._status_cache.pop(file_path, None)

    def _clear_downloading(self, file_path):
        self._download_sticky.pop(file_path, None)
        self._status_cache.pop(file_path, None)

    def _mark_tree_downloading(self, root_path):
        """Marca sticky na pasta e em todos os filhos (UI); o daemon já faz cache recursivo."""
        marked = 0
        self._mark_downloading(root_path, ttl=STICKY_DIR_DOWNLOAD_SEC)
        marked += 1
        try:
            for dirpath, dirnames, filenames in os.walk(root_path):
                self._mark_downloading(dirpath, ttl=STICKY_DIR_DOWNLOAD_SEC)
                marked += 1
                for name in filenames:
                    self._mark_downloading(
                        os.path.join(dirpath, name), ttl=STICKY_DIR_DOWNLOAD_SEC
                    )
                    marked += 1
        except Exception:
            pass
        return marked

    def _clear_tree_downloading(self, root_path):
        to_clear = [
            p
            for p in self._download_sticky
            if p == root_path or p.startswith(root_path + os.sep)
        ]
        for p in to_clear:
            self._clear_downloading(p)

    def _invalidate_status_tree(self, root_path):
        """Limpa cache de label da pasta e de todos os descendentes."""
        to_clear = [
            p
            for p in list(self._status_cache)
            if p == root_path or p.startswith(root_path + os.sep)
        ]
        for p in to_clear:
            self._status_cache.pop(p, None)

    def _is_download_sticky(self, file_path):
        expires = self._download_sticky.get(file_path)
        if expires is None:
            return False
        if time.monotonic() > expires:
            self._download_sticky.pop(file_path, None)
            return False
        return True

    def _tree_has_uncached_files(self, root_path):
        try:
            for dirpath, _dirnames, filenames in os.walk(root_path):
                for name in filenames:
                    fp = os.path.join(dirpath, name)
                    if self.conn.send("is-file-cached", fp) != "cached":
                        return True
            return False
        except Exception:
            return True

    def _dir_children_cache_counts(self, root_path):
        """Conta arquivos cached vs total sob a pasta (daemon mente em is-file-cached de dir)."""
        total = 0
        cached_n = 0
        try:
            for dirpath, _dirnames, filenames in os.walk(root_path):
                for name in filenames:
                    total += 1
                    fp = os.path.join(dirpath, name)
                    if self.conn.send("is-file-cached", fp) == "cached":
                        cached_n += 1
        except Exception:
            return -1, -1
        return cached_n, total

    def _status_label(self, file_path):
        now = time.monotonic()
        # Sticky tem prioridade sobre cache antigo (senão pasta fica "Só online" após pin).
        if self._is_download_sticky(file_path):
            self._status_cache.pop(file_path, None)
        else:
            cached_row = self._status_cache.get(file_path)
            if cached_row and cached_row[0] > now:
                return cached_row[1], cached_row[2]

        status = self.conn.send("get-file-status", file_path)
        is_dir = os.path.isdir(file_path)
        if status == "locked":
            label, emblem = "Bloqueado", EMBLEM_LOCKED_OTHERS
        elif status == "locked_by_me":
            label, emblem = "Bloqueado por mim", EMBLEM_LOCKED_ME
        elif is_dir:
            # Pasta: get-file-status=partial_synced e is-file-cached=uncached mesmo com
            # todos os filhos locais. Status real = agregação dos arquivos.
            if self._is_download_sticky(file_path) and self._tree_has_uncached_files(file_path):
                label, emblem = "Baixando…", EMBLEM_SYNCING
            else:
                cached_n, total = self._dir_children_cache_counts(file_path)
                if total < 0:
                    label, emblem = "Só online", None
                elif total == 0:
                    # Pasta vazia ou listing falhou: confiar no daemon, não forçar Neste PC.
                    if status in ("cloud", ""):
                        label, emblem = "Só online", None
                    else:
                        label, emblem = "Neste PC", None
                elif cached_n == total:
                    self._clear_downloading(file_path)
                    label, emblem = "Neste PC", None
                elif cached_n == 0:
                    self._clear_downloading(file_path)
                    label, emblem = "Só online", None
                else:
                    label, emblem = "Parcial neste PC", None
        else:
            cached = self.conn.send("is-file-cached", file_path)
            if cached == "cached" or status == "synced":
                self._clear_downloading(file_path)
                label, emblem = "Neste PC", None
            elif self._is_download_sticky(file_path):
                label, emblem = "Baixando…", EMBLEM_SYNCING
            elif status == "syncing":
                label, emblem = "Só online", None
            else:
                label, emblem = "Só online", None

        ttl = 1.5 if is_dir else STATUS_CACHE_SEC
        self._status_cache[file_path] = (now + ttl, label, emblem)
        return label, emblem

    def get_file_items(self, *args):
        files = args[-1]
        if files is None or len(files) != 1:
            return []

        file = files[0]
        file_path = self.uri_to_local_path(file.get_uri())
        if not file_path.startswith(mount_dir) or file_path == mount_dir:
            return []

        cached_items = self._cached_menu(file_path)
        if cached_items is not None:
            return cached_items

        try:
            is_in_repo = self.conn.send("is-file-in-repo", file_path)
            if is_in_repo != "true":
                return []
        except Exception:
            return []

        # Itens planos: no Nautilus GTK4 submenu "SeaDrive" não abre bem no clique.
        items = []

        free_item = Nautilus.MenuItem(
            name=self._item_name("FreeUpSpace", file_path),
            label="SeaDrive: Free up space",
        )
        self._bind(free_item, self.on_free_up_space, file_path, file)
        items.append(free_item)

        keep_item = Nautilus.MenuItem(
            name=self._item_name("AlwaysKeep", file_path),
            label="SeaDrive: Always keep on this device",
        )
        self._bind(keep_item, self.on_always_keep, file_path, file)
        items.append(keep_item)


        if file.is_directory():
            upload_item = Nautilus.MenuItem(
                name=self._item_name("UploadLink", file_path),
                label="SeaDrive: Get Upload Link",
            )
            self._bind(upload_item, self.on_get_upload_link, file_path)
            items.append(upload_item)

        # Só pin/free(+upload em pasta): evita RPC de lock/share a cada rebuild do menu.
        return self._store_menu(file_path, items)

    def _arm_download_watch(self, file_path, file):
        """Reconsulta o cache e atualiza a coluna quando o pin terminar."""
        state = {"n": 0}
        is_dir = os.path.isdir(file_path)

        def _tick():
            state["n"] += 1
            try:
                cached = self.conn.send("is-file-cached", file_path)
                status = self.conn.send("get-file-status", file_path)
                done = False
                if is_dir:
                    # Pastas: is-file-cached quase nunca é "cached"; checa filhos a cada 2s.
                    if state["n"] % 4 == 0 and not self._tree_has_uncached_files(file_path):
                        done = True
                elif cached == "cached" or status == "synced":
                    done = True
                # Enquanto baixa pasta, atualiza filhos visíveis (ex.: subpasta "1").
                if is_dir and state["n"] % 4 == 0:
                    self._invalidate_status_tree(file_path)
                    self._refresh_seen_under(file_path)
                if done:
                    if is_dir:
                        self._clear_tree_downloading(file_path)
                    else:
                        self._clear_downloading(file_path)
                    self._invalidate_status_tree(file_path)
                    self._refresh_file_info(file_path, file, b"synced")
                    self._refresh_seen_under(file_path)
                    self._notify(
                        "SeaDrive",
                        f"“{os.path.basename(file_path)}” está neste PC",
                    )
                    return False
            except Exception:
                pass
            # Pastas grandes (ISO etc.): até ~30 min; arquivos: ~45s.
            limit = 3600 if is_dir else 90
            if state["n"] >= limit:
                if is_dir:
                    self._clear_tree_downloading(file_path)
                else:
                    self._clear_downloading(file_path)
                try:
                    self._refresh_file_info(file_path, file, b"cloud")
                except Exception:
                    pass
                return False
            return True

        GLib.timeout_add(500, _tick)

    def on_free_up_space(self, menu_item, file_path, file):
        try:
            self.conn.send("uncache", file_path)
            if os.path.isdir(file_path):
                self._clear_tree_downloading(file_path)
            else:
                self._clear_downloading(file_path)
            # Sempre limpar labels em cache da árvore (senão fica "Neste PC" por vários segundos).
            self._invalidate_status_tree(file_path)
            self._refresh_file_info(file_path, file, b"uncached")
            name = os.path.basename(file_path) or file_path
            self._notify("SeaDrive", f"Espaço liberado: “{name}”")
            # Re-invalida a coluna algumas vezes: Nautilus pode manter atributo antigo.
            self._arm_status_refresh(file_path, file, rounds=6)
        except Exception as e:
            print(f"Failed to free up space for {file_path}: {e}")

    def _arm_status_refresh(self, file_path, file, rounds=4):
        state = {"n": 0}

        def _tick():
            state["n"] += 1
            self._invalidate_status_tree(file_path)
            try:
                self._refresh_file_info(file_path, file, b"refresh")
            except Exception:
                pass
            self._refresh_seen_under(file_path)
            return state["n"] < rounds

        GLib.timeout_add(400, _tick)

    def on_always_keep(self, menu_item, file_path, file):
        self._invalidate_menu(file_path)
        is_dir = os.path.isdir(file_path)
        try:
            self.conn.send("download", file_path)
            self._invalidate_status_tree(file_path)
            if is_dir:
                marked = self._mark_tree_downloading(file_path)
            else:
                self._mark_downloading(file_path)
                marked = 1
            # NÃO abrir Transfer Progress aqui: o diálogo faz poll de progresso e
            # o daemon AppImage 3.0.23 crasha (SIGSEGV / "unable to decode byte").
            self._refresh_file_info(file_path, file, b"syncing")
            name = os.path.basename(file_path) or file_path
            if is_dir:
                self._notify(
                    "SeaDrive",
                    f"Baixando pasta “{name}” e subpastas ({marked} itens)…",
                )
            else:
                self._notify(
                    "SeaDrive",
                    f"Baixando “{name}” para este PC…",
                )
            self._arm_download_watch(file_path, file)
            self._arm_status_refresh(file_path, file, rounds=8)
        except Exception as e:
            print(f"Failed to keep on device for {file_path}: {e}")
            self._notify("SeaDrive", f"Falha ao manter no dispositivo: {e}")

    def _refresh_file_info(self, file_path, file, status_bytes):
        try:
            os.setxattr(file_path, "user.seafile-status", status_bytes)
        except Exception:
            pass
        try:
            if hasattr(file, "invalidate_extension_info"):
                file.invalidate_extension_info()
        except Exception:
            pass
    def on_get_upload_link(self, menu_item, file_path):
        try:
            self.conn.send("get-upload-link", file_path)
        except Exception as e:
            print(f"Failed to get upload link for {file_path}: {e}")

    def on_get_share_link(self, menu_item, file_path):
        try:
            self.conn.send("get-share-link", file_path)
        except Exception as e:
            print(f"Failed to get share link for {file_path}: {e}")

    def on_get_internal_link(self, menu_item, file_path):
        try:
            self.conn.send("get-internal-link", file_path)
        except Exception as e:
            print(f"Failed to get internal link for {file_path}: {e}")

    def on_show_file_history(self, menu_item, file_path):
        try:
            self.conn.send("show-history", file_path)
        except Exception as e:
            print(f"Failed to show file history for {file_path}: {e}")

    def on_unlock_file(self, menu_item, file_path, file):
        try:
            self.conn.send("unlock-file", file_path)
            self._refresh_file_info(file_path, file, b"unlocked")
        except Exception as e:
            print(f"Failed to unlock file {file_path}: {e}")

    def on_lock_file(self, menu_item, file_path, file):
        try:
            self.conn.send("lock-file", file_path)
            self._refresh_file_info(file_path, file, b"locked-by-me")
        except Exception as e:
            print(f"Failed to lock file {file_path}: {e}")

    def uri_to_local_path(self, uri):
        # Não usar Path.resolve() no FUSE — pode alterar o path e quebrar o socket.
        if uri.startswith("file://"):
            return urllib.parse.unquote(uri[7:])
        return uri

    def update_file_info(self, file_info):
        file_path = self.uri_to_local_path(file_info.get_uri())
        if not file_path.startswith(mount_dir):
            return
        self._remember_file(file_path, file_info)
        try:
            label, emblem = self._status_label(file_path)
            file_info.add_string_attribute(STATUS_ATTR, label)
            if emblem:
                file_info.add_emblem(emblem)
            # Propaga status da pasta pai quando um filho é atualizado.
            if not file_info.is_directory():
                try:
                    parent = file_info.get_parent_info()
                    if parent:
                        pp = self.uri_to_local_path(parent.get_uri())
                        if pp.startswith(mount_dir):
                            self._remember_file(pp, parent)
                            self._status_cache.pop(pp, None)
                            plabel, _ = self._status_label(pp)
                            parent.add_string_attribute(STATUS_ATTR, plabel)
                except Exception:
                    pass
        except Exception:
            # Socket ocupado/quebrado: não derrubar o Nautilus nem spammar log.
            try:
                file_info.add_string_attribute(STATUS_ATTR, "Só online")
            except Exception:
                pass

    def get_background_items(self, *args):
        folder = args[-1]
        folder_path = self.uri_to_local_path(folder.get_uri())
        if folder_path != mount_dir:
            return None
        seadrive_menu_item = Nautilus.MenuItem(
            name="SeaDriveExt::SeaDrive",
            label="SeaDrive",
            tip="SeaDrive menus",
        )
        seadrive_menu = Nautilus.Menu()

        progress_item = Nautilus.MenuItem(
            name="SeaDriveExt::TransferProgress",
            label="Transfer Progress",
            tip="Click to get transfer progress",
        )
        progress_item.connect("activate", self.on_transfer_progress)
        seadrive_menu.append_item(progress_item)

        sync_errors_item = Nautilus.MenuItem(
            name="SeaDriveExt::FileSyncErrors",
            label="Show File Sync Errors",
            tip="Click to show file sync errors",
        )
        sync_errors_item.connect("activate", self.on_show_file_sync_errors)
        seadrive_menu.append_item(sync_errors_item)

        enc_libs_item = Nautilus.MenuItem(
            name="SeaDriveExt::EncLibs",
            label="Show Encrypted Libraries",
            tip="Click to show encrypted libraries",
        )
        enc_libs_item.connect("activate", self.on_show_enc_libs)
        seadrive_menu.append_item(enc_libs_item)

        open_logs_folder_item = Nautilus.MenuItem(
            name="SeaDriveExt::OpenLogsFolder",
            label="Open Logs Folder",
            tip="Click to open logs folder",
        )
        open_logs_folder_item.connect("activate", self.on_open_logs_folder)
        seadrive_menu.append_item(open_logs_folder_item)

        settings_item = Nautilus.MenuItem(
            name="SeaDriveExt::ShowSettings",
            label="Settings",
            tip="Click to open settings",
        )
        settings_item.connect("activate", self.on_show_settings)
        seadrive_menu.append_item(settings_item)

        accounts = []
        try:
            rsp = self.conn.send("show-accounts", "")
            if rsp != "":
                data = json.loads(rsp)
                for account in data:
                    accounts.append(Account(account["name"], account["signature"]))
        except Exception as e:
            print(f"Failed to get accounts: {e}")

        accounts_menu_item = Nautilus.MenuItem(
            name="SeaDriveExt::Accounts",
            label="Accounts",
            tip="Accounts menus",
        )
        accounts_menu = Nautilus.Menu()
        for account in accounts:
            account_menu_item = Nautilus.MenuItem(
                name="SeaDriveExt::Account",
                label=account.name,
                tip="Account menus",
            )
            accounts_menu.append_item(account_menu_item)

            account_menu = Nautilus.Menu()
            resync_account_item = Nautilus.MenuItem(
                name="SeaDriveExt::ResyncAccount",
                label="Resync",
                tip="Click to resync account",
            )
            resync_account_item.connect("activate", self.on_resync_account, account)
            account_menu.append_item(resync_account_item)

            delete_account_item = Nautilus.MenuItem(
                name="SeaDriveExt::DeleteAccount",
                label="Delete",
                tip="Click to delete account",
            )
            delete_account_item.connect("activate", self.on_delete_account, account)
            account_menu.append_item(delete_account_item)

            account_menu_item.set_submenu(account_menu)

        add_account_item = Nautilus.MenuItem(
            name="SeaDriveExt::AddAccount",
            label="Add an account",
            tip="Click to add an account",
        )
        add_account_item.connect("activate", self.on_add_account)
        accounts_menu.append_item(add_account_item)
        accounts_menu_item.set_submenu(accounts_menu)
        seadrive_menu.append_item(accounts_menu_item)

        about_item = Nautilus.MenuItem(
            name="SeaDriveExt::ShowAbout",
            label="About",
            tip="Click to open about",
        )
        about_item.connect("activate", self.on_show_about)
        seadrive_menu.append_item(about_item)

        help_item = Nautilus.MenuItem(
            name="SeaDriveExt::ShowHelp",
            label="Online Help",
            tip="Click to open online help",
        )
        help_item.connect("activate", self.on_show_help)
        seadrive_menu.append_item(help_item)

        quit_item = Nautilus.MenuItem(
            name="SeaDriveExt::Quit",
            label="Quit",
            tip="Click to quit seadrive",
        )
        quit_item.connect("activate", self.on_quit)
        seadrive_menu.append_item(quit_item)

        seadrive_menu_item.set_submenu(seadrive_menu)
        return [seadrive_menu_item]

    def on_transfer_progress(self, menu_item):
        try:
            self.conn.send("show-transfer-progress", "")
        except Exception as e:
            print(f"Failed to get transfer progress: {e}")

    def on_show_file_sync_errors(self, menu_item):
        try:
            self.conn.send("show-file-sync-errors", "")
        except Exception as e:
            print(f"Failed to show file sync errors: {e}")

    def on_show_enc_libs(self, menu_item):
        try:
            self.conn.send("show-encrypted-libraries", "")
        except Exception as e:
            print(f"Failed to show encrypted libraries: {e}")

    def on_open_logs_folder(self, menu_item):
        try:
            self.conn.send("open-logs-folder", "")
        except Exception as e:
            print(f"Failed to open logs folder: {e}")

    def on_show_settings(self, menu_item):
        try:
            self.conn.send("show-settings", "")
        except Exception as e:
            print(f"Failed to show settings: {e}")

    def on_add_account(self, menu_item):
        try:
            self.conn.send("add-account", "")
        except Exception as e:
            print(f"Failed to add account: {e}")

    def on_resync_account(self, menu_item, account):
        try:
            self.conn.send("resync-account", account.signature)
        except Exception as e:
            print(f"Failed to resync account: {e}")

    def on_delete_account(self, menu_item, account):
        try:
            self.conn.send("delete-account", account.signature)
        except Exception as e:
            print(f"Failed to delete account: {e}")

    def on_show_about(self, menu_item):
        try:
            self.conn.send("show-about", "")
        except Exception as e:
            print(f"Failed to show about: {e}")

    def on_show_help(self, menu_item):
        try:
            self.conn.send("show-help", "")
        except Exception as e:
            print(f"Failed to show online help: {e}")

    def on_quit(self, menu_item):
        try:
            self.conn.send("quit", "")
        except Exception as e:
            print(f"Failed to quit seadrive: {e}")
