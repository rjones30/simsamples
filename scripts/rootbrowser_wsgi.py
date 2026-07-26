#!/usr/bin/env python3
#
# rootbrowser_wsgi.py - mod_wsgi application that serves a JSROOT browser
#                       for ROOT files on xrootd. For each unique file URL,
#                       a dedicated ROOT process with THttpServer is spawned
#                       on a random port. Sessions are tracked via files in
#                       /tmp/rootbrowser_sessions/ so all worker processes
#                       can find them. Sessions auto-terminate after idle timeout.
#
# Apache config snippet (in each VirtualHost):
#   WSGIScriptAliasMatch ^/rootbrowser(.*) /home/www/wsgi-scripts/rootbrowser_wsgi.py
#
# Usage:
#   https://gryphn.phys.uconn.edu/rootbrowser/?file=root://nod65.phys.uconn.edu//Gluex/.../file.root
#
# author: richard.t.jones at uconn.edu
# version: july 25, 2026

import hashlib
import html
import json
import os
import random
import re
import socket
import subprocess
import threading
import time
import traceback
import urllib.request
from urllib.parse import parse_qs

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

ALLOWED_HOSTS = [
    r".*\.phys\.uconn\.edu",
    r".*\.storrs\.hpc\.uconn\.edu",
]

PORT_RANGE = (18000, 19000)
SESSION_TIMEOUT = 600
ROOTSYS = "/usr"
SESSION_DIR = "/tmp/rootbrowser_sessions"

# ---------------------------------------------------------------------------
# Security
# ---------------------------------------------------------------------------

def validate_url(file_url):
    if not file_url:
        raise ValueError("Missing 'file' parameter")
    m = re.match(r'^(root|roots|http|https)://([^/:]+)', file_url)
    if not m:
        raise ValueError(f"Unsupported URL scheme: {file_url}")
    hostname = m.group(2)
    for pattern in ALLOWED_HOSTS:
        if re.match(pattern, hostname):
            return file_url
    raise ValueError(f"Access denied: host '{hostname}' not in allowed list")

# ---------------------------------------------------------------------------
# Session registry (file-based, shared across all worker processes)
# ---------------------------------------------------------------------------

def session_id(file_url):
    return hashlib.sha256(file_url.encode()).hexdigest()[:16]

def session_path(sid):
    os.makedirs(SESSION_DIR, exist_ok=True)
    return os.path.join(SESSION_DIR, sid + ".json")

def load_session(sid):
    """Load session info from disk. Returns dict or None."""
    try:
        with open(session_path(sid)) as f:
            return json.load(f)
    except Exception:
        return None

def save_session(sid, port, pid):
    import fcntl
    p = session_path(sid)
    with open(p, 'w') as f:
        fcntl.flock(f, fcntl.LOCK_EX)
        json.dump({'port': port, 'pid': pid, 'last_access': time.time()}, f)
        fcntl.flock(f, fcntl.LOCK_UN)

def touch_session(sid):
    import fcntl
    p = session_path(sid)
    try:
        with open(p, 'r+') as f:
            fcntl.flock(f, fcntl.LOCK_EX)
            try:
                sess = json.load(f)
                sess['last_access'] = time.time()
                f.seek(0)
                f.truncate()
                json.dump(sess, f)
            finally:
                fcntl.flock(f, fcntl.LOCK_UN)
    except Exception:
        pass

def session_alive(sid):
    sess = load_session(sid)
    if not sess:
        return False
    try:
        os.kill(sess['pid'], 0)
        return True
    except OSError:
        return False

def find_free_port():
    for _ in range(100):
        port = random.randint(*PORT_RANGE)
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            if s.connect_ex(('localhost', port)) != 0:
                return port
    raise RuntimeError("No free port found")

# ---------------------------------------------------------------------------
# ROOT macro generator
# ---------------------------------------------------------------------------

def make_macro(file_url, port, timeout, sid):
    escaped_url = file_url.replace('\\', '\\\\').replace('"', '\\"')
    return f"""
#include <THttpServer.h>
#include <TFile.h>
#include <TKey.h>
#include <TDirectory.h>
#include <TSystem.h>
#include <iostream>
#include <ctime>

void registerDir(THttpServer *serv, TDirectory *dir, TString path) {{
    TIter next(dir->GetListOfKeys());
    TKey *key;
    while ((key = (TKey*)next())) {{
        TObject *obj = key->ReadObj();
        if (!obj) continue;
        TString objpath = path + "/" + obj->GetName();
        serv->Register(objpath.Data(), obj);
        if (obj->InheritsFrom("TDirectory"))
            registerDir(serv, (TDirectory*)obj, objpath);
    }}
}}

void rootbrowser_session_{port}() {{
    auto serv = new THttpServer("http:{port};readonly;loopback");
    serv->SetCors("*");
    serv->SetJSROOT("/rootbrowser/session/{sid}/jsrootsys");
    serv->AddLocation("jsrootsys/", "/usr/share/javascript/jsroot");

    const char* url = "{escaped_url}";
    auto f = TFile::Open(url, "READ");
    if (!f || f->IsZombie()) {{
        std::cerr << "Error: Could not open file: " << url << std::endl;
        gSystem->Exit(1);
    }}
    serv->Register("/", f);
    registerDir(serv, f, "");

    std::cout << "rootbrowser_session: ready on port {port}" << std::endl;
    std::cout.flush();

    time_t last_request = time(nullptr);

    while (true) {{
        gSystem->ProcessEvents();
        gSystem->Sleep(500);

        TString sentinel_path = TString::Format("{SESSION_DIR}/touch_%d", {port});
        if (!gSystem->AccessPathName(sentinel_path.Data())) {{
            last_request = time(nullptr);
        }}

        if (time(nullptr) - last_request > {timeout}) {{
            std::cout << "rootbrowser_session: idle timeout, exiting." << std::endl;
            gSystem->Exit(0);
        }}
    }}
}}
"""

# ---------------------------------------------------------------------------
# Start a ROOT session
# ---------------------------------------------------------------------------

_start_lock = threading.Lock()

def start_session(file_url):
    """Start a ROOT THttpServer session. Returns (sid, port)."""
    sid = session_id(file_url)

    with _start_lock:
        if session_alive(sid):
            sess = load_session(sid)
            touch_session(sid)
            return sid, sess['port']

        port = find_free_port()
        macro_content = make_macro(file_url, port, SESSION_TIMEOUT, sid)

        os.makedirs(SESSION_DIR, exist_ok=True)
        macro_path = os.path.join(SESSION_DIR, f"rootbrowser_session_{port}.C")
        with open(macro_path, 'w') as f:
            f.write(macro_content)

        env = os.environ.copy()
        env['ROOTSYS'] = ROOTSYS

        proc = subprocess.Popen(
            ['root', '-l', '-b', '-q', f'{macro_path}+'],
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

        ready = False
        output_lines = []
        deadline = time.time() + 60
        while time.time() < deadline:
            line = proc.stdout.readline().decode(errors='replace')
            output_lines.append(line)
            if 'ready on port' in line:
                ready = True
                break
            if proc.poll() is not None:
                remaining = proc.stdout.read().decode(errors='replace')
                err = proc.stderr.read().decode(errors='replace')
                output_lines.append(remaining)
                output_lines.append(err)
                break
            time.sleep(0.1)

        # Clean up macro and compiled files
        for ext in ['', '_C.so', '_C.d', '_C_ACLiC_dict_rdict.pcm']:
            p = macro_path.replace('.C', ext) if ext else macro_path
            try:
                os.unlink(p)
            except Exception:
                pass

        if not ready:
            proc.kill()
            log_path = os.path.join(SESSION_DIR, f"error_{port}.log")
            with open(log_path, 'w') as lf:
                lf.write(''.join(output_lines))
            raise RuntimeError(f"ROOT session failed. See {log_path}")

        save_session(sid, port, proc.pid)
        # Touch sentinel
        open(os.path.join(SESSION_DIR, f"touch_{port}"), 'w').close()
        return sid, port

# ---------------------------------------------------------------------------
# WSGI application
# ---------------------------------------------------------------------------

def application(environ, start_response):
    path = environ.get("PATH_INFO", "/")
    query = parse_qs(environ.get("QUERY_STRING", ""))
    file_param = query.get("file", [None])[0]

    # Strip /rootbrowser prefix
    if path.startswith("/rootbrowser"):
        path = path[len("/rootbrowser"):]
    if not path:
        path = "/"

    os.makedirs(SESSION_DIR, exist_ok=True)

    def respond(status, ctype, body):
        if isinstance(body, str):
            body = body.encode()
        start_response(status, [("Content-Type", ctype),
                                 ("Content-Length", str(len(body)))])
        return [body]

    def proxy(port, rest, qs, sid=None):
        upstream_url = f"http://localhost:{port}{rest}"
        if qs:
            upstream_url += "?" + qs
        try:
            req = urllib.request.Request(upstream_url)
            req.add_header("Accept-Encoding", "identity")
            if "HTTP_RANGE" in environ:
                req.add_header("Range", environ["HTTP_RANGE"])
            with urllib.request.urlopen(req, timeout=30) as resp:
                data = resp.read()
                ctype = resp.headers.get("Content-Type", "")
                # Rewrite HTML to inject session ID into relative URLs
                if sid and "text/html" in ctype:
                    session_prefix = f"session/{sid}/".encode()
                    data = data.replace(b'"jsrootsys/', b'"' + session_prefix + b'jsrootsys/')
                    data = data.replace(b"'jsrootsys/", b"'" + session_prefix + b'jsrootsys/')
                    data = data.replace(b'./jsrootsys/', session_prefix + b'jsrootsys/')
                    data = data.replace(b'"currentdir/', b'"' + session_prefix + b'currentdir/')
                    data = data.replace(b'"rootsys/', b'"' + session_prefix + b'rootsys/')
                resp_headers = [("Access-Control-Allow-Origin", "*")]
                for key in ("Content-Type", "Content-Range", "Accept-Ranges", "Content-Encoding"):
                    val = resp.headers.get(key)
                    if val:
                        resp_headers.append((key, val))
                resp_headers.append(("Content-Length", str(len(data))))
                status_str = f"{resp.status} {'Partial Content' if resp.status == 206 else 'OK'}"
                start_response(status_str, resp_headers)
                return [data]
        except Exception as e:
            return respond("502 Bad Gateway", "text/plain", str(e))

    try:
        qs = environ.get("QUERY_STRING", "")

        # ---- /session/<sid>/... - proxy to ROOT session ----
        if path.startswith("/session/"):
            parts = path[len("/session/"):].split("/", 1)
            sid = parts[0]
            rest = "/" + parts[1] if len(parts) > 1 else "/"
            sess = load_session(sid)
            if not sess:
                return respond("404 Not Found", "text/plain", "Session not found or expired")
            touch_session(sid)
            open(os.path.join(SESSION_DIR, f"touch_{sess['port']}"), 'w').close()
            return proxy(sess['port'], rest, qs)

        # ---- /?file=... - start session and redirect ----
        elif file_param:
            try:
                file_url = validate_url(file_param)
            except ValueError as e:
                return respond("400 Bad Request", "text/html",
                               f"<html><body><p>{html.escape(str(e))}</p></body></html>")
            try:
                sid, port = start_session(file_url)
            except RuntimeError as e:
                # Session may still be starting - if JSON exists, show waiting page
                sid = session_id(file_url)
                if load_session(sid):
                    body = f"""<!DOCTYPE html>
<html><head><meta http-equiv="refresh" content="3;url=/rootbrowser/?file={html.escape(file_url)}">
<style>body{{font-family:monospace;margin:2em;}}</style>
</head><body><p>ROOT session starting, please wait...</p></body></html>"""
                    return respond("200 OK", "text/html", body)
                return respond("500 Internal Server Error", "text/html",
                               f"<html><body><p>{html.escape(str(e))}</p></body></html>")
            redirect_url = f"/rootbrowser/session/{sid}/"
            start_response("302 Found", [("Location", redirect_url)])
            return [b""]

        else:
            return respond("400 Bad Request", "text/html",
                           "<html><body><p>Please provide a ?file= parameter.</p></body></html>")

    except Exception:
        tb = traceback.format_exc()
        return respond("500 Internal Server Error", "text/plain", tb)
