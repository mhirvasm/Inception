FROM alpine:3.23

# 1. Install PHP-FPM, necessary PHP extensions, and download tools
# - php83-fpm: The engine that executes PHP code.
# - php83-mysqli: Allows PHP to communicate with your MariaDB container.
# - php83-phar & php83-mbstring: Required for the WP-CLI tool to function.
# - wget: To download the WordPress installation files.
# - mariadb-client: Allows WP-CLI to test the database connection.
RUN apk update && apk add --no-cache \
    php83 \
    php83-fpm \
    php83-mysqli \
    php83-phar \
    php83-mbstring \
    php83-curl \
    wget \
    mariadb-client


# 2. Symlink PHP for convenience 
# Alpine 3.20 installs the binary as 'php83', but wp-cli expects just 'php'.
RUN ln -s /usr/bin/php83 /usr/bin/php

# 3. Download and install WP-CLI (WordPress Command Line Interface)
# This allows us to configure WordPress without a web browser.
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# 4. Create the web directory and set permissions
RUN mkdir -p /var/www/html && \
    chown -R root:root /var/www/html
RUN echo "memory_limit = 256M" >> /etc/php83/conf.d/wp-memory.ini

# 5. Copy configuration and initialization scripts
COPY ./conf/www.conf /etc/php83/php-fpm.d/www.conf
COPY ./tools/wordpress-script.sh /usr/local/bin/wordpress-script.sh

# 6. Secure the script
RUN chmod +x /usr/local/bin/wordpress-script.sh

# 7. Document the port (PHP-FPM default is 9000)
EXPOSE 9000

# 8. Set the default working directory
WORKDIR /var/www/html

# 9. Execute the initialization script
ENTRYPOINT ["/usr/local/bin/wordpress-script.sh"]
