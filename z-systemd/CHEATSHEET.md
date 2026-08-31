# ⚙️ Docker vs. systemd Cheat Sheet

## The Bare Metal World (How Servers Work)
When a physical Linux server (or VM) boots, the Linux Kernel launches a master initialization program at **PID 1**, which is almost always **`systemd`**.
* `systemd` is the ultimate manager: it configures the network, starts SSH, boots databases, and manages background daemons.
* You control it using commands like `systemctl start nginx` or `service mysql restart`.

---

## 🐳 The Docker Reality (Why `systemctl` Fails)
A Docker container is **not a virtual machine**. It does not boot a kernel, and it skips the entire Linux boot sequence. 
* **There is no `systemd` running inside a standard Docker container.**
* Your application (e.g., NGINX, Python, Node) becomes PID 1 directly.
* Because there is no manager, running `systemctl` or `service` inside a container will result in an error: *"System has not been booted with systemd as init system"*.

---

## ❌ The Anti-Pattern: Forcing systemd into Docker
Beginners migrating from bare-metal servers often try to force `systemd` into Docker (by installing it and setting `CMD ["/sbin/init"]`) so they can cram multiple services (like NGINX + PHP + MySQL) into a single container.
    
**Why this is terrible:**
1. **Breaks Isolation:** Containers are meant to isolate a single concern.
2. **Security Risk:** `systemd` requires deep system privileges (like mounting cgroups). To run it in Docker, you often have to use the dangerous `--privileged` flag, completely destroying container security.
3. **Bloat:** It makes your container image massive and slows down startup times.

---

## ✅ The Docker Way: One Process Per Container
Instead of using `systemd` inside a container to manage multiple background services:
1. **Split your architecture:** Put NGINX in one container, PHP in a second, and MySQL in a third. Connect them via a Docker network.
2. **Run in the foreground:** Configure your apps to run in the foreground (e.g., `nginx -g "daemon off;"`) so they hold onto PID 1 and keep the container alive.
3. **Let Docker be the manager:** If a service crashes, let the container die. Configure Docker Compose to automatically restart it using `restart: always`.