import time
import server


class FakeHandler:
    get_valid_session = server.Handler.get_valid_session

    def __init__(self, session_id):
        self.headers = {"Cookie": f"session={session_id}"}


def test_absolute_timeout():
    session_id = "absolute-test"
    now = time.time()

    server.sessions[session_id] = {
        "username": "rahim",
        "role": "user",
        "expires_at": now - 1,
        "last_activity": now
    }

    result = FakeHandler(session_id).get_valid_session()

    assert result is None
    assert session_id not in server.sessions

    print("PASS: Absolute timeout")


def test_idle_timeout():
    session_id = "idle-test"
    now = time.time()

    server.sessions[session_id] = {
        "username": "rahim",
        "role": "user",
        "expires_at": now + 300,
        "last_activity": now - 61
    }

    result = FakeHandler(session_id).get_valid_session()

    assert result is None
    assert session_id not in server.sessions

    print("PASS: Idle timeout")


def test_valid_session():
    session_id = "valid-test"
    now = time.time()

    server.sessions[session_id] = {
        "username": "rahim",
        "role": "user",
        "expires_at": now + 300,
        "last_activity": now - 10
    }

    result = FakeHandler(session_id).get_valid_session()

    assert result is not None
    assert session_id in server.sessions
    assert result["last_activity"] >= now

    print("PASS: Valid session and activity refresh")


def test_invalid_session():
    session_id = "invalid-test"
    server.sessions.pop(session_id, None)

    result = FakeHandler(session_id).get_valid_session()

    assert result is None
    assert session_id not in server.sessions

    print("PASS: Invalid session")



test_absolute_timeout()
test_idle_timeout()
test_valid_session()
test_invalid_session()

print("All session tests passed.")
