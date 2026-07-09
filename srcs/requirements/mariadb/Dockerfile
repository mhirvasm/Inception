FROM alpine:3.20.6

# Install MariaDB
RUN apk update && apk add --no-cache mariadb mariadb-client

# Copy and secure configuration (Must end in .cnf)
COPY ./conf/mariadb-server.cnf /etc/my.cnf.d/mariadb-server.cnf
RUN chmod 644 /etc/my.cnf.d/mariadb-server.cnf

# Copy and grant execution rights to the initialization script
COPY ./tools/mariadb-script.sh /usr/local/bin/mariadb-script.sh
RUN chmod +x /usr/local/bin/mariadb-script.sh

# Document the port
EXPOSE 3306

# Execute using the absolute path
ENTRYPOINT ["/usr/local/bin/mariadb-script.sh"]
