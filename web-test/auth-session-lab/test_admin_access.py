import http.client
import threading
import time
from http.server import HTTPServer

import server


def test_admin_access_control():
    now = time.time()

    server.sessions["test-user-session"] = {
        "username": "rahim",
        "role": "user",
        "expires_at": now + 300,
        "last_activity": now,
    }

    server.sessions["test-admin-session"] = {
        "username": "admin",
        "role": "admin",
        "expires_at": now + 300,
        "last_activity": now,
    }

    httpd = HTTPServer(("127.0.0.1", 0), server.Handler)
    thread = threading.Thread(
        target=httpd.serve_forever,
        daemon=True,
    )
    thread.start()

    try:
        cases = [
            (None, 401, "Unauthenticated request"),
            ("test-user-session", 403, "Regular user denied"),
            ("test-admin-session", 200, "Admin allowed"),
        ]

        for session_id, expected_status, description in cases:
            headers = {}

            if session_id:
                headers["Cookie"] = f"session={session_id}"

            connection = http.client.HTTPConnection(
                "127.0.0.1",
                httpd.server_port,
            )

            connection.request("GET", "/admin", headers=headers)
            response = connection.getresponse()
            response.read()

            assert response.status == expected_status, (
                f"FAIL: {description}: expected {expected_status}, "
                f"got {response.status}"
            )

            print(f"PASS: {description} ({response.status})")
            connection.close()

    finally:
        httpd.shutdown()
        httpd.server_close()
        thread.join()

        server.sessions.pop("test-user-session", None)
        server.sessions.pop("test-admin-session", None)


if __name__ == "__main__":
    test_admin_access_control()
