import http.client
import threading
from http.server import HTTPServer

import server


def test_content_type_options_header():
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

        connection.request("GET", "/")
        response = connection.getresponse()
        response.read()

        assert response.status == 200, (
            f"Expected 200, got {response.status}"
        )

        header = response.getheader("X-Content-Type-Options")

        assert header == "nosniff", (
            f"Expected 'nosniff', got {header!r}"
        )

        print("PASS: X-Content-Type-Options is nosniff")

        connection.close()

    finally:
        httpd.shutdown()
        httpd.server_close()
        thread.join()


if __name__ == "__main__":
    test_content_type_options_header()
