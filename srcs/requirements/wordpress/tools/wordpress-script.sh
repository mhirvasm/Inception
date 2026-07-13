#!/bin/sh
set -e

# 1. Check if WordPress is already downloaded
# We check for wp-config.php so we don't accidentally overwrite your site if the container restarts.
if [ -f "/var/www/html/wp-config.php" ]; then
    echo "==> WordPress is already installed and configured."
else
    echo "==> Downloading WordPress core..."
    # Download the core files using the wp-cli tool we installed in the Dockerfile
    wp core download --allow-root --path='/var/www/html'

    echo "==> Generating wp-config.php..."
    # Inject the database credentials from the .env file
    wp config create --allow-root \
        --dbname="${WORDPRESS_DATABASE_NAME}" \
        --dbuser="${WORDPRESS_DATABASE_USER}" \
        --dbpass="${WORDPRESS_DATABASE_USER_PASSWORD}" \
        --dbhost="mariadb:3306" \
        --path='/var/www/html'
	#FOR PORT FORWARDING
	sed -i "s/.*WP_SITEURL.*/define('WP_SITEURL', 'https:\/\/' . \$_SERVER['HTTP_HOST']);/" /var/www/html/wp-config.php
	sed -i "s/.*WP_HOME.*/define('WP_HOME', 'https:\/\/' . \$_SERVER['HTTP_HOST']);/" /var/www/html/wp-config.php
    echo "==> Installing WordPress and creating Admin user..."
    # Set up the site name and the primary administrator
    wp core install --allow-root \
        --url="${DOMAIN_NAME}" \
        --title="${WORDPRESS_TITLE}" \
        --admin_user="${WORDPRESS_ADMIN}" \
        --admin_password="${WORDPRESS_ADMIN_PASSWORD}" \
        --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
        --path='/var/www/html'

    echo "==> Creating standard user..."
    # The subject specifically requires a second, non-admin user
    wp user create --allow-root \
        "${WORDPRESS_USER}" \
        "${WORDPRESS_USER_EMAIL}" \
        --user_pass="${WORDPRESS_USER_PASSWORD}" \
        --role=author \
        --path='/var/www/html'
        
    echo "==> WordPress installation complete."
fi

# 2. Set correct permissions
# Ensure the 'nobody' user (which runs PHP-FPM) owns the files
chown -R nobody:nobody /var/www/html
chmod -R 755 /var/www/html

echo "==> Handing over control to PHP-FPM (PID 1)..."
# 3. The PID 1 Handoff
# Start PHP-FPM in the foreground (-F) so Docker doesn't think the container stopped.
exec php-fpm83 -F
