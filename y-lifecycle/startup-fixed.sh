#!/bin/sh
echo "[STARTUP] Booting the environment..."

# =========================================================================
# ✅ THE FIX: The 'exec' command (Keep the driver in the seat)
# =========================================================================
# Instead of putting the worker in the background and exiting, we use 'exec'.
# 'exec' completely replaces the current process (this startup script)
# with the new process (the worker). 
# The worker inherits PID 1 and keeps the container alive.

echo "[STARTUP] Setup complete! Handing over PID 1 to the worker..."
exec ./worker.sh

# Anything written below the 'exec' command will never run, because this
# script no longer exists in memory!
echo "You will never see this line."