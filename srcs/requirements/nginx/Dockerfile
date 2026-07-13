FROM alpine:3.20.6

# Install NGINX and OpenSSL for TLS certificate generation
RUN apk update && apk add --no-cache nginx openssl

# Copy NGINX configuration to the correct Alpine path
COPY ./conf/nginx.conf /etc/nginx/nginx.conf

# Copy and grant execution rights to the initialization script
COPY ./tools/nginx-script.sh /usr/local/bin/nginx-script.sh
RUN chmod +x /usr/local/bin/nginx-script.sh

# Document the HTTPS port
EXPOSE 443

# Execute using the absolute path
ENTRYPOINT ["/usr/local/bin/nginx-script.sh"]
