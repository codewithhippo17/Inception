#!/bin/sh
echo "[STARTUP] Booting the environment..."

# =========================================================================
# ❌ THE MISTAKE: The Absolute Lifecycle Rule (The Bus Driver)
# =========================================================================
# By using the '&' symbol, we put the worker in the background.
./worker.sh &

echo "[STARTUP] Setup complete! Exiting..."

# ❌ PID 1 is this startup script. The moment it runs 'exit 0', Docker
# sees that PID 1 is dead. It will instantly vaporize the entire container,
# killing the background worker with it. The container will just stop immediately.
exit 0

# =========================================================================
# FIX: Keep the driver in the seat
# =========================================================================
# If you need to run a setup script, use 'exec' at the end to hand over PID 1
# to the actual application.
#
# exec ./worker.sh

