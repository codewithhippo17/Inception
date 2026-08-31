FROM debian:latest

# Install both nginx and systemd for testing purposes
RUN apt-get update && apt-get install -y nginx systemd

# =========================================================================
# ❌ THE MISTAKE: The System Initialization Myth
# =========================================================================
# Attempting to use systemd commands in a container.
# This crashes because Docker skips the OS boot sequence, so systemd is not running.

CMD systemctl start nginx && tail -f /dev/null

# =========================================================================
#FIX: Run in the Foreground
# =========================================================================
# To fix this container, comment out the CMD above, and uncomment the one below.
# Docker wants your app to run directly as PID 1, not managed by systemd.
#
# CMD ["nginx", "-g", "daemon off;"]
