#!/bin/sh
# Generates srcs/.env and secrets/ files for the Inception project.
# Usage: ./scripts/configure-env.sh <login>
# Execute this on your host machine (Mac), not in the VM.

# Exit immediately if any command fails
set -e

# 1. Strict Input Validation (No fallback fallacies)
if [ -z "$1" ]; then
    echo "Error: Missing login argument."
    echo "Usage: $0 <login>"
    echo "Example: $0 mhirvasm"
    exit 1
fi

LOGIN="$1"

# 2. Dynamic Pathing
# This ensures the script writes to the correct folders regardless of 
# where you execute it from within your repository.
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/srcs/.env"
SECRETS_DIR="${ROOT_DIR}/secrets"

echo "--> Initializing project directories..."
mkdir -p "${ROOT_DIR}/srcs"
mkdir -p "$SECRETS_DIR"

# 3. Safe Password Generation
# We strip out non-alphanumeric characters to prevent breaking bash 
# evaluation in the Docker containers later.
generate_password() {
    if command -v openssl >/dev/null 2>&1; then
        openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 16
    else
        date +%s%N | sha256sum | head -c 16
    fi
}

echo "--> Generating secure alphanumeric credentials..."
DB_USER_PASS=$(generate_password)
ROOT_PASS=$(generate_password)
ADMIN_PASS=$(generate_password)
USER_PASS=$(generate_password)

# 4. Write Evaluation Secrets
echo "--> Writing evaluation reference to ${SECRETS_DIR}/..."
echo "$DB_USER_PASS" > "${SECRETS_DIR}/db_password.txt"
echo "$ROOT_PASS" > "${SECRETS_DIR}/db_root_password.txt"

cat > "${SECRETS_DIR}/credentials.txt" <<EOF
WordPress admin (${LOGIN}_boss): ${ADMIN_PASS}
WordPress user (${LOGIN}): ${USER_PASS}
MariaDB root: ${ROOT_PASS}
MariaDB app user (wp_db_user): ${DB_USER_PASS}
EOF

# Lock down permissions
chmod 600 "${SECRETS_DIR}"/*.txt

# 5. Build the .env File
echo "--> Generating ${ENV_FILE}..."
cat > "$ENV_FILE" <<EOF
# Core Infrastructure
LOGIN=${LOGIN}
DOMAIN_NAME=${LOGIN}.42.fr
DATA_PATH=/home/${LOGIN}/data

# WordPress Configuration
WORDPRESS_TITLE=Inception
WORDPRESS_DATABASE_NAME=wordpress_db

WORDPRESS_DATABASE_USER=wp_db_user
WORDPRESS_DATABASE_USER_PASSWORD=${DB_USER_PASS}

# Admin user (Subject rule: Must not contain 'admin'/'administrator')
WORDPRESS_ADMIN=${LOGIN}_boss
WORDPRESS_ADMIN_PASSWORD=${ADMIN_PASS}
WORDPRESS_ADMIN_EMAIL=${LOGIN}@student.hive.fi

# Standard user
WORDPRESS_USER=${LOGIN}
WORDPRESS_USER_PASSWORD=${USER_PASS}
WORDPRESS_USER_EMAIL=${LOGIN}@student.hive.fi

# MariaDB Configuration
MYSQL_ROOT_PASSWORD=${ROOT_PASS}
EOF

# Lock down permissions
chmod 600 "$ENV_FILE"

echo "--> Success!"
echo "Variables injected for domain: ${DOMAIN_NAME}"
echo "IMPORTANT: The variable DATA_PATH is set to /home/${LOGIN}/data."
echo "You must manually create this directory structure inside your Alpine VM before running docker compose."
