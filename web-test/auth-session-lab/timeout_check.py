import time

IDLE_TIMEOUT = 60
ABSOLUTE_TIMEOUT = 300

now = time.time()

# Test 1: Absolute timeout expired
session_absolute = {
    "expires_at": now - 1,
    "last_activity": now
}

if now >= session_absolute["expires_at"]:
    print("PASS: Absolute timeout expired the session")
else:
    print("FAIL: Absolute timeout check")

# Test 2: Idle timeout expired
session_idle = {
    "expires_at": now + 300,
    "last_activity": now - 61
}

if now - session_idle["last_activity"] >= IDLE_TIMEOUT:
    print("PASS: Idle timeout expired the session")
else:
    print("FAIL: Idle timeout check")
