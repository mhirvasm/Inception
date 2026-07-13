#!/bin/sh
# Stop execution immediately if any command fails
set -e

# Define the target directory for the certificates
SSL_DIR="/etc/nginx/ssl"

# Check if the SSL directory does not exist, then create it
if [ ! -d "$SSL_DIR" ]; then
    mkdir -p "$SSL_DIR"
fi

# Check if the certificate file already exists to prevent overwriting on restarts
if [ ! -f "$SSL_DIR/inception.crt" ]; then
    echo "Generating self-signed SSL/TLS certificate..."
    
    # Generate the self-signed certificate and private key
    # req -x509: Specifies we want a self-signed certificate instead of a certificate request
    # -nodes: Prevents encrypting the private key with a passphrase (NGINX needs to read it automatically)
    # -days 365: Valid for one year
    # -newkey rsa:2048: Generates a new 2048-bit RSA key
    # -keyout / -out: Specifies the exact paths for the key and certificate
    # -subj: Pre-fills the certificate subject data to bypass interactive prompts. CN must match your domain.
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$SSL_DIR/inception.key" \
        -out "$SSL_DIR/inception.crt" \
        -subj "/C=FI/ST=Uusimaa/L=Helsinki/O=Hive/OU=Student/CN=mhirvasm.42.fr"
else
    echo "SSL/TLS certificate already exists. Skipping generation."
fi

# Hand over process control to NGINX
# 'exec' replaces the current bash shell with the NGINX process, making it PID 1.
# '-g "daemon off;"' forces NGINX to run in the foreground, keeping the container alive.
echo "Starting NGINX..."
exec nginx -g "daemon off;"
