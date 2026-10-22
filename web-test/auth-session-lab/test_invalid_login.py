
import http.client
import threading
from http.server import HTTPServer
from urllib.parse import urlencode

import server


def test_invalid_password_rejected():
    sessions_before = set(server.sessions.keys())

    httpd = HTTPServer(("127.0.0.1", 0), server.Handler)
    thread = threading.Thread(target=httpd.serve_forever, daemon=True)
    thread.start()

    try:
        connection = http.client.HTTPConnection(
            "127.0.0.1", httpd.server_port
        )

        body = urlencode({
            "username": "rahim",
            "password": "definitely-wrong-password",
        })

        connection.request(
            "POST",
            "/login",
            body=body,
            headers={
                "Content-Type": "application/x-www-form-urlencoded",
            },
        )

        response = connection.getresponse()
        response.read()

        assert response.status == 401, (
            f"FAIL: Expected 401, got {response.status}"
        )

        assert set(server.sessions.keys()) == sessions_before, (
            "FAIL: Invalid login changed the session store"
        )

        assert response.getheader("Set-Cookie") is None, (
            "FAIL: Invalid login issued a session cookie"
        )

        print("PASS: Invalid credentials rejected")
        print("PASS: No new session or session cookie issued")

        connection.close()

    finally:
        httpd.shutdown()
        httpd.server_close()
        thread.join()


if __name__ == "__main__":
    test_invalid_password_rejected()
