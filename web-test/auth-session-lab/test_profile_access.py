import http.client
import threading
import time
from http.server import HTTPServer

import server


def test_profile_access_control():
    now = time.time()

    server.sessions["nahian-test-session"] = {
        "username": "nahian",
        "role": "user",
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
            ("/profile?id=1", 200, "Own profile allowed"),
            ("/profile?id=2", 403, "Other user's profile denied"),
            ("/profile?id=999", 404, "Missing profile returns 404"),
        ]

        for path, expected_status, description in cases:
            connection = http.client.HTTPConnection(
                "127.0.0.1",
                httpd.server_port,
            )

            connection.request(
                "GET",
                path,
                headers={
                    "Cookie": "session=nahian-test-session",
                },
            )

            response = connection.getresponse()
            body = response.read().decode()

            assert response.status == expected_status, (
                f"FAIL: {description}: expected {expected_status}, "
                f"got {response.status}. Body: {body}"
            )

            if expected_status == 403:
                assert "Rahim's private lab note" not in body, (
                    "FAIL: Other user's private note was exposed"
                )

            print(f"PASS: {description} ({response.status})")
            connection.close()

    finally:
        httpd.shutdown()
        httpd.server_close()
        thread.join()
        server.sessions.pop("nahian-test-session", None)


if __name__ == "__main__":
    test_profile_access_control()
