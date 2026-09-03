#!/bin/sh

# Wait for MariaDB to be fully initialized and accessible
echo "Waiting for MariaDB..."
while ! mariadb -h mariadb -u "${MYSQL_USER}" -p"$(cat /run/secrets/db_password)" "${MYSQL_DATABASE}" -e "SELECT 1;" --silent; do
  sleep 2
done
echo "MariaDB is ready!"

# If wp-config.php doesn't exist, this is a fresh volume that needs installation
if [ ! -f "/var/www/html/wp-config.php" ]; then
  echo "Installing WordPress via WP-CLI..."

  # Download WordPress core files
  wp core download --allow-root

  # Create the wp-config.php dynamically injecting credentials from Secrets
  wp config create \
    --dbname="${MYSQL_DATABASE}" \
    --dbuser="${MYSQL_USER}" \
    --dbpass="$(cat /run/secrets/db_password)" \
    --dbhost="mariadb" \
    --allow-root

  # Subject constraint: "The administrator’s username can’t contain admin/Admin..."
  # The variable WP_ADMIN_USER will be set in .env to comply with this.
  wp core install \
    --url="${DOMAIN_NAME}" \
    --title="Inception" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="$(cat /run/secrets/wp_admin_password)" \
    --admin_email="${WP_ADMIN_EMAIL}" \
    --allow-root

  # Subject constraint: "...there must be two users, one of them being the administrator."
  wp user create \
    "${WP_USER}" \
    "${WP_USER_EMAIL}" \
    --user_pass="$(cat /run/secrets/wp_password)" \
    --role=author \
    --allow-root

  echo "WordPress successfully installed and configured!"
fi

# Subject constraint: No hacky patches. Hand over PID 1 to php-fpm in the foreground.
echo "Starting PHP-FPM..."
exec "$@"

