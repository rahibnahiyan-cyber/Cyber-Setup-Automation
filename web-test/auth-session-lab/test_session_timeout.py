import time
import server

class FakeHandler:
    headers = {"Cookie": "session=idle-test"}
    get_valid_session = server.Handler.get_valid_session


session_id = "idle-test"
now = time.time()

server.sessions[session_id] = {
    "username": "rahim",
    "role": "user",
    "expires_at": now + 300,
    "last_activity": now - 61
}

result = FakeHandler().get_valid_session()

assert result is None, "FAIL: Idle session was accepted"
assert session_id not in server.sessions, "FAIL: Idle session was not removed"

print("PASS: Idle timeout rejects and removes inactive session")
