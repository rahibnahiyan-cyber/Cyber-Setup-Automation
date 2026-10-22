
import subprocess
import sys

test_files = [
    "test_session_timeout.py",
    "test_session_rotation.py",
    "test_invalid_login.py",
    "test_logout.py",
    "test_admin_access.py",
    "test_profile_access.py",
    "test_security_headers.py"
]

for test_file in test_files:
    print(f"\n--- Running {test_file} ---", flush=True)

    result = subprocess.run(
        [sys.executable, test_file],
        check=False,
    )

    if result.returncode != 0:
        print(f"\nFAIL: {test_file}")
        sys.exit(result.returncode)

print("\nAll test files passed.")
