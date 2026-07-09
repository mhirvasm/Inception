#!/bin/sh
# Exit immediately if any command fails
set -e

echo "==> Setting up MariaDB directory permissions..."
# MariaDB needs a place to put its temporary socket file
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

# Ensure the mysql user owns the mounted host volume
chown -R mysql:mysql /var/lib/mysql
chmod -R 755 /var/lib/mysql

# 1. THE IDEMPOTENCY CHECK
# We check if the 'mysql' system folder exists inside the data volume.
# If it does NOT exist, we know this is a completely fresh setup.
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "==> Fresh volume detected. Initializing system tables..."
    
    # Builds the base database structure. We hide the massive output by sending it to /dev/null.
    mariadb-install-db --basedir=/usr --user=mysql --datadir=/var/lib/mysql >/dev/null

    echo "==> Injecting WordPress database and users..."
    
    # 2. THE SECURE BOOTSTRAP
    # We start MariaDB in the background without networking (--bootstrap).
    # We feed it the SQL commands directly via a "Here Document" (EOF).
    mysqld --user=mysql --bootstrap <<EOF
USE mysql;
FLUSH PRIVILEGES;

-- Set the root password (loaded from the .env file)
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Create the empty database for WordPress
CREATE DATABASE IF NOT EXISTS ${WORDPRESS_DATABASE_NAME} CHARACTER SET utf8 COLLATE utf8_general_ci;

-- Create the WordPress application user and give them a password
CREATE USER IF NOT EXISTS '${WORDPRESS_DATABASE_USER}'@'%' IDENTIFIED BY '${WORDPRESS_DATABASE_USER_PASSWORD}';

-- Give the application user full control over only the WordPress database
GRANT ALL PRIVILEGES ON ${WORDPRESS_DATABASE_NAME}.* TO '${WORDPRESS_DATABASE_USER}'@'%';

FLUSH PRIVILEGES;
EOF

else
    # If the folder already exists, we skip the setup to avoid wiping the existing data.
    echo "==> Existing database detected. Skipping initialization."
fi

echo "==> Handing over process control to MariaDB daemon..."

# 3. THE PID 1 HANDOFF
# The 'exec' command destroys this bash shell and replaces it with the mysqld process.
# We do not need the '--defaults-file' flag because we named the config file correctly (.cnf).
exec mysqld --user=mysql --console
