
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs
import secrets
import time


PROFILES = {
    "1": {
        "owner": "nahian",
        "email": "nahian@example.test",
        "private_note": "Nahian's private lab note"
    },
    "2": {
        "owner": "rahim",
        "email": "rahim@example.test",
        "private_note": "Rahim's private lab note"
    }
}


USERS = {
    "nahian": {
        "password": "lab123",
        "role": "user"
    },
    "rahim": {
        "password": "rahim123",
        "role": "user"
    },
    "admin": {
        "password": "admin123",
        "role": "admin"
    }
}

# Server-side session storage
IDLE_TIMEOUT = 60
ABSOLUTE_TIMEOUT = 300
SESSION_TIMEOUT = IDLE_TIMEOUT
sessions = {}


class Handler(BaseHTTPRequestHandler):

    def get_valid_session(self):
        cookie = self.headers.get("Cookie")
        session_id = None

        if cookie:
            for item in cookie.split(";"):
                name, separator, value = item.strip().partition("=")

                if separator and name == "session":
                    session_id = value
                    break

        session = sessions.get(session_id)

        if not session:
            return None

        now = time.time()

        if now >= session["expires_at"]:
            sessions.pop(session_id, None)
            return None

        if now - session["last_activity"] >= IDLE_TIMEOUT:
            sessions.pop(session_id, None)
            return None

        session["last_activity"] = now
        return session

    def do_GET(self):

        if self.path == "/":
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.end_headers()

            self.wfile.write(b"""
                <h1>Login Lab</h1>
                <form method="POST" action="/login">
                    <input name="username" placeholder="Username">
                    <input name="password" type="password"
                           placeholder="Password">
                    <button type="submit">Login</button>
                </form>
            """)

        elif self.path == "/headers":
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()

            output = (
                f"Host: {self.headers.get('Host')}\n"
                f"User-Agent: {self.headers.get('User-Agent')}\n"
                f"X-Lab-Test: {self.headers.get('X-Lab-Test')}\n"
                f"Cookie: {self.headers.get('Cookie')}\n"
            )

            self.wfile.write(output.encode())

        elif self.path == "/logout":
            cookie = self.headers.get("Cookie")

            if cookie and cookie.startswith("session="):
                session_id = cookie.split("=", 1)[1]
                sessions.pop(session_id, None)

            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"Logged out")

        elif self.path == "/admin":
            session = self.get_valid_session()

            if not session:
                self.send_response(401)
                self.end_headers()
                self.wfile.write(b"401 Unauthorized")
                return

            if session["role"] != "admin":
                self.send_response(403)
                self.end_headers()
                self.wfile.write(b"403 Forbidden")
                return

            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"Welcome, admin")


        
        elif self.path.startswith("/profile?"):
            from urllib.parse import urlparse, parse_qs

            session = self.get_valid_session()

            if not session:
                self.send_response(401)
                self.end_headers()
                self.wfile.write(b"401 Unauthorized")
                return

            query = parse_qs(urlparse(self.path).query)
            profile_id = query.get("id", [""])[0]
            profile = PROFILES.get(profile_id)

            if not profile:
                self.send_response(404)
                self.end_headers()
                self.wfile.write(b"404 Profile not found")
                return

            if profile["owner"] != session["username"]:
                self.send_response(403)
                self.end_headers()
                self.wfile.write(b"403 Forbidden")
                return

            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()

            output = (
                f"Owner: {profile['owner']}\n"
                f"Email: {profile['email']}\n"
                f"Private note: {profile['private_note']}\n"
            )
            self.wfile.write(output.encode())

        
        elif self.path == "/protected":
            session = self.get_valid_session()

            if not session:
                self.send_response(401)
                self.send_header("Content-Type", "text/html")
                self.end_headers()
                self.wfile.write(
                    b"<h1>401 Unauthorized</h1>"
                    b"<p>You must log in first.</p>"
                )
                return

            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.end_headers()
            self.wfile.write(
                b"<h1>Protected Page</h1>"
                b"<p>Authentication successful.</p>"
            )

        else:
            self.send_error(404)

    def do_POST(self):

        if self.path != "/login":
            self.send_error(404)
            return

        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length).decode()
        data = parse_qs(body)

        username = data.get("username", [""])[0]
        password = data.get("password", [""])[0]

        user = USERS.get(username)
        if user and user["password"] == password:

            session_id = secrets.token_hex(16)
            sessions[session_id] = {
                "username": username,
                "role": user["role"],
                "expires_at": time.time() + ABSOLUTE_TIMEOUT,
                "last_activity": time.time()
            }

            self.send_response(302)
            self.send_header("Location", "/protected")
            self.send_header(
                "Set-Cookie",
                f"session={session_id}; HttpOnly; SameSite=Lax; Secure"
            )
            self.end_headers()

        else:
            self.send_response(401)
            self.send_header("Content-Type", "text/html")
            self.end_headers()

            self.wfile.write(
                b"<h1>401 Unauthorized</h1>"
                b"<p>Invalid username or password.</p>"
            )


server = HTTPServer(("127.0.0.1", 9001), Handler)

print("Auth lab running on http://127.0.0.1:9001")
server.serve_forever()
