#!/bin/sh
set -euo pipefail

# 7. Add trap cleanup to prevent orphaned background processes on interruption
trap 'kill "$temp_pid" 2>/dev/null || true; wait "$temp_pid" 2>/dev/null || true' EXIT INT TERM

if [ ! -d "/var/lib/mysql/mysql" ]; then
  echo "Initializing fresh MariaDB database..."

  # 5. Validate that secret files actually exist before proceeding
  if [ ! -f "/run/secrets/db_root_password" ] || [ ! -f "/run/secrets/db_password" ]; then
    echo "Error: Secret files are missing."
    exit 1
  fi

  DB_ROOT_PWD=$(cat /run/secrets/db_root_password)
  DB_PWD=$(cat /run/secrets/db_password)

  # Validate environment variables (Address Issue 9)
  if [ -z "$DB_ROOT_PWD" ] || [ -z "$DB_PWD" ] || [ -z "${MYSQL_DATABASE:-}" ] || [ -z "${MYSQL_USER:-}" ]; then
    echo "Error: Database credentials or environment variables are empty."
    exit 1
  fi

  # 1. Install raw database files
  mariadb-install-db --user=mysql --datadir=/var/lib/mysql >/dev/null

  # 8. Start server temporarily with --skip-networking to block external access during init
  mariadbd --user=mysql --datadir=/var/lib/mysql --skip-networking &
  temp_pid="$!"

  # 4. Wait with a timeout to prevent infinite loops
  echo "Waiting for temporary MariaDB server..."
  for i in $(seq 1 30); do
    # 10. Specify socket to ensure we ping this specific local instance
    if mariadb-admin ping --socket=/run/mysqld/mysqld.sock --silent; then
      break
    fi
    if [ "$i" -eq 30 ]; then
      echo "Error: Timeout waiting for MariaDB to start."
      exit 1
    fi
    sleep 1
  done

  echo "Applying security and user configurations..."

  # 2 & 9. Securely write SQL to a locked temporary file
  INIT_FILE=$(mktemp)
  chmod 600 "$INIT_FILE"

  cat <<EOF >"$INIT_FILE"
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PWD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS \`${MYSQL_USER}\`@'%' IDENTIFIED BY '${DB_PWD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO \`${MYSQL_USER}\`@'%';
FLUSH PRIVILEGES;
EOF

  # Feed the file to mariadb and remove it immediately
  mariadb -u root --socket=/run/mysqld/mysqld.sock <"$INIT_FILE"
  rm -f "$INIT_FILE"

  # 1. Use a temporary defaults-file to prevent password exposure in `ps` output
  DEFAULTS_FILE=$(mktemp)
  chmod 600 "$DEFAULTS_FILE"
  printf "[client]\npassword=\"%s\"\n" "$DB_ROOT_PWD" >"$DEFAULTS_FILE"

  mariadb-admin --defaults-file="$DEFAULTS_FILE" -u root --socket=/run/mysqld/mysqld.sock shutdown
  rm -f "$DEFAULTS_FILE"

  # Wait for the background process to exit completely
  wait "$temp_pid"

  # Initialization succeeded normally, so we untrap the exit handler
  trap - EXIT INT TERM
  echo "Database initialization complete."
fi

# Hand off PID 1 to the database daemon
echo "Starting MariaDB daemon..."
exec "$@"

