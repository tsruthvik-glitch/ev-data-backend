
import mysql.connector

ATTEMPTS = [
    # (user, password, host)
    ("RUTHVIK SRINATH", "Ruthvik@5", "127.0.0.1"),
    ("RUTHVIK SRINATH", "Ruthvik@5", "localhost"),
    ("root", "Ruthvik@5", "127.0.0.1"),
    ("root", "Ruthvik@5", "localhost"),
    ("root", "", "127.0.0.1"),
    ("root", "", "localhost"),
    ("root", "root", "127.0.0.1"),
    ("root", "root", "localhost"),
    ("root", "password", "127.0.0.1"),
    ("admin", "admin", "127.0.0.1"),
]

def try_connect(user, password, host):
    try:
        conn = mysql.connector.connect(
            user=user,
            password=password,
            host=host,
            port=3306
        )
        print(f"SUCCESS: Connected with User='{user}', Password='{password}', Host='{host}'")
        conn.close()
        return True
    except mysql.connector.Error as err:
        # print(f"FAILED: User='{user}', Password='{password}', Host='{host}' -> {err}")
        return False

print("Starting credential diagnosis...")
worked = False
for user, password, host in ATTEMPTS:
    if try_connect(user, password, host):
        worked = True
        break

if not worked:
    print("All common combinations failed.")
