import http.client
import threading
from http.server import HTTPServer
from urllib.parse import urlencode

import server


def test_login_rotates_session_id():
    httpd = HTTPServer(("127.0.0.1", 0), server.Handler)
    thread = threading.Thread(target=httpd.serve_forever, daemon=True)
    thread.start()

    try:
        connection = http.client.HTTPConnection(
            "127.0.0.1", httpd.server_port
        )

        body = urlencode({
            "username": "rahim",
            "password": "rahim123",
        })

        connection.request(
            "POST",
            "/login",
            body=body,
            headers={
                "Content-Type": "application/x-www-form-urlencoded",
                "Cookie": "session=prelogin-test-123",
            },
        )

        response = connection.getresponse()
        response.read()

        assert response.status == 302, (
            f"FAIL: Expected 302, got {response.status}"
        )

        cookie = response.getheader("Set-Cookie")
        assert cookie is not None, "FAIL: Set-Cookie header missing"

        new_session_id = cookie.split(";", 1)[0].split("=", 1)[1]

        assert new_session_id != "prelogin-test-123", (
            "FAIL: Login reused the pre-login session ID"
        )
        assert new_session_id in server.sessions, (
            "FAIL: New session ID was not stored on the server"
        )

        print("PASS: Login creates a fresh session ID")

        connection.close()

    finally:
        httpd.shutdown()
        httpd.server_close()
        thread.join()


if __name__ == "__main__":
    test_login_rotates_session_id()
