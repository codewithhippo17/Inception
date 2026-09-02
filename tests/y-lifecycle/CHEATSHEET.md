# 🐳 Docker Lifecycle & PID 1 Cheat Sheet

## The Core Rule: The Bus Driver (PID 1)
In Docker, the lifespan of a container is strictly tied to **Process ID 1 (PID 1)**. 
Think of PID 1 as the driver of a bus. If the driver leaves the seat (the process exits), Docker immediately destroys the entire bus (the container), regardless of who else is in the back (background tasks).

---

## ❌ The Mistake: Backgrounding & Exiting
When writing an entrypoint or startup script, a common mistake is putting the main application in the background and letting the script finish.

```bash
#!/bin/sh
# 1. Start the actual app in the background
./worker.sh & 

# 2. The script finishes and naturally exits. 
# Docker sees PID 1 is dead, and INSTANTLY kills the container!
exit 0 
```
**Result:** The container starts, but stops immediately. The background worker is destroyed before it can do its job.

---

## ✅ The Fix: Using `exec`
To keep the container alive, your long-running application must *become* PID 1. We do this using the `exec` command.

```bash
#!/bin/sh
# 1. Do any setup needed first (creating folders, setting permissions)
echo "Booting environment..."

# 2. Hand over PID 1 to the application using 'exec'
exec ./worker.sh

# 3. Anything below 'exec' will NEVER run, because this script no longer exists.
```
**Result:** The `exec` command replaces the `startup.sh` process in memory with `worker.sh`. `worker.sh` inherits PID 1. Since `worker.sh` is a long-running process, the container stays alive.

---

## 🧠 Key Takeaways
* **Never let your entrypoint script finish** if it's supposed to keep a service running.
* **Always use `exec`** at the very end of your Docker entrypoint scripts to launch the primary daemon (like `nginx`, `mysqld`, or `php-fpm`).
* **Background processes (`&`) will NOT keep a container alive.** Docker only cares about PID 1.
## 🧪 How to Test This Yourself
You can observe this behavior directly by running the following commands in your terminal inside this folder:

### 1. Test the Mistake
Build and run the flawed container:
```bash
docker build -t test-mistake -f Dockerfile .
docker run --name mistake-run --rm test-mistake
```
**Observation:** The terminal prints the startup logs and immediately returns your prompt. The container died because `startup.sh` finished.

### 2. Test the Fix
Build and run the fixed container (using `exec`):
```bash
docker build -t test-fix -f Dockerfile-fixed .
docker run --name fix-run --rm test-fix
```
**Observation:** The terminal prints the setup logs and then "hangs" (or prints the worker's output). The container stays alive indefinitely because `worker.sh` took over PID 1! Press `Ctrl + C` to kill it.
