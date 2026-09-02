# Docker PID 1 Lifecycle & Zombie Prevention Guide

This document serves as the definitive reference for preventing graceful shutdown failures and zombie process leaks in Docker containers.

## The Diagnostic Commands

Never trust host-level tools blindly. To prove if your container is architecturally sound, run these commands:

1. **Check for Signal Routing (Shell Hijacking):**
   ```bash
   docker top <container_name>
   ```
   *If PID 1's command is `/bin/sh -c`, your container will fail to gracefully shut down. It will hang for 10 seconds and be SIGKILL'd.*

2. **Check for Zombie Leaks (Internal Namespace):**
   ```bash
   # Requires procps installed in the container
   docker exec <container_name> ps ax -o pid,ppid,stat,command
   ```
   *If you see the `Z` status or `[process] <defunct>`, your container is leaking processes and will eventually crash the host node.*

---

## FIX 1: Exec Form Syntax (Signal Routing)

**The Problem:** Using bare strings in Dockerfiles (Shell Form) forces Docker to wrap your application in `/bin/sh -c`. Shells swallow termination signals (`SIGTERM`), preventing your app from executing graceful shutdown logic.

**The Fix:** Always use JSON arrays (Exec Form). This bypasses the shell and places your application directly at PID 1.

```dockerfile
# ❌ BAD: Shell Form (Creates a /bin/sh wrapper)
CMD python server.py

# ✅ GOOD: Exec Form (Python becomes PID 1)
CMD ["python", "-u", "server.py"]
```

---

## FIX 2: The Init Wrapper (Zombie Reaping)

**The Problem:** Even with Fix 1 applied, raw applications like Node.js, Python, or Java are not operating systems. If they spawn a background process (or use a third-party library that does), and that process orphans itself and dies, the raw application will not know how to run a C-level `waitpid()` system call to clean it up. The dead process becomes a permanent Zombie.

**The Fix:** Inject a lightweight C-binary supervisor like `dumb-init` or `tini` to sit at PID 1. It will forward all signals perfectly to your app (PID 2) while acting as a permanent janitor to reap any orphaned zombies.

```dockerfile
FROM python:3.11-slim
WORKDIR /app

# 1. Install the init wrapper
RUN apt-get update && apt-get install -y dumb-init

COPY server.py .

# 2. Assign dumb-init to PID 1
ENTRYPOINT ["dumb-init", "--"]

# 3. Your application safely runs as PID 2
CMD ["python", "-u", "server.py"]
```

**Alternative (Docker CLI / Compose):**
If you cannot modify the Dockerfile, you can force Docker to inject `tini` dynamically:
- **CLI:** `docker run --init -d my-image`
- **Compose:** Add `init: true` to the service block in `docker-compose.yml`.
---

## Case Study: The Python Wait() Trap

Here is a practical breakdown of why simply calling `wait()` inside your application code is not enough to prevent zombies, referencing the `server.py` example:

**STORY EXPLANATION:**
1. When your Python script starts (let's assume it runs as PID 1), it spawns an intermediate shell `sh` (PID 8).
2. Inside that shell, it runs `sleep 2 &`. The `&` pushes `sleep` into the background (PID 9).
3. The `sh` (PID 8) immediately exits because its job is done. 
4. Your Python script correctly calls `p.wait()`, which successfully reaps `sh` (PID 8). So far, so good.
5. **The Trap:** `sleep 2` (PID 9) is still running. But its parent (`sh`) just died. It is now an orphan.
6. By Linux kernel rules, any orphaned process is instantly adopted by PID 1.
7. So, Python (PID 1) suddenly becomes the parent of `sleep 2` (PID 9) behind the scenes, but your script has no code written to handle `SIGCHLD` signals for adopted processes.
8. Two seconds later, `sleep 2` finishes. It sends a `SIGCHLD` to PID 1 and waits to be reaped. But Python is stuck in a `while True: time.sleep(1)` loop. It ignores the signal.
9. Because PID 1 never calls `waitpid()` for it, `sleep 2` becomes a `<defunct>` zombie process, permanently consuming a slot in the container's PID table.

**How to fix it:**
This is exactly why your Dockerfile includes `dumb-init`. If you run the container normally (using the `ENTRYPOINT ["dumb-init", "--"]`), `dumb-init` becomes PID 1, and Python becomes PID 2. 
When `sleep 2` is orphaned, it gets adopted by `dumb-init` (PID 1). Because `dumb-init` is a proper init system, it immediately catches the `SIGCHLD` signal and reaps the zombie for you, keeping the container perfectly clean!
