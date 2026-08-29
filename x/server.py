import subprocess
import time

print("[APP] Python Application started.")
print("[APP] Spawning an intermediate shell...")

# 1. We spawn an intermediate shell.
# 2. The shell spawns 'sleep 2' in the background.
# 3. The shell exits immediately.
p = subprocess.Popen(["sh", "-c", "sleep 2 &"])

# We act like a good parent and call wait() on the intermediate shell.
# This prevents the shell itself from becoming a zombie.
p.wait() 

print("[APP] Shell reaped. The 'sleep 2' process is now ORPHANED to PID 1.")
print("[APP] Running normal loop...")

while True:
    time.sleep(1)