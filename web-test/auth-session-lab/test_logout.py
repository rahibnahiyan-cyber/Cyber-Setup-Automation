import http.client
import threading
from http.server import HTTPServer

import server


def test_logout_invalidates_session():
    session_id = "logout-test-session"

    server.sessions[session_id] = {
        "username": "rahim",
        "role": "user",
        "expires_at": 9999999999,
        "last_activity": 9999999999,
    }

    httpd = HTTPServer(("127.0.0.1", 0), server.Handler)
    thread = threading.Thread(
        target=httpd.serve_forever,
        daemon=True,
    )
    thread.start()

    try:
        connection = http.client.HTTPConnection(
            "127.0.0.1",
            httpd.server_port,
        )

        connection.request(
            "GET",
            "/logout",
            headers={"Cookie": f"session={session_id}"},
        )

        response = connection.getresponse()
        response_body = response.read().decode()

        assert response.status == 200, (
            f"Expected 200, got {response.status}"
        )

        assert "Max-Age=0" in response.getheader("Set-Cookie", ""), (
            "Logout cookie-clearing header missing"
        )

        assert session_id not in server.sessions, (
            "Session still exists on the server"
        )

        print("PASS: Logout clears the cookie")
        print("PASS: Logout removes the server-side session")

        connection.request(
            "GET",
            "/protected",
            headers={"Cookie": f"session={session_id}"},
        )

        response = connection.getresponse()
        response.read()

        assert response.status == 401, (
            f"Expected 401 after logout, got {response.status}"
        )

        print("PASS: Old session rejected after logout")

        connection.close()

    finally:
        httpd.shutdown()
        httpd.server_close()
        thread.join()


if __name__ == "__main__":
    test_logout_invalidates_session()
