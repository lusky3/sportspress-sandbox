FROM wordpress:6.8.1-php8.3-fpm-alpine

# Install MariaDB, wp-cli, nginx, and supervisord for process management
RUN apk add --no-cache \
    wget \
    mariadb \
    mariadb-client \
    nginx \
    supervisor \
    bash

# Install wp-cli
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Install unzip for plugin extraction
RUN apk add --no-cache unzip

# Configure MariaDB with performance optimizations
RUN mkdir -p /run/mysqld \
    && chown -R mysql:mysql /run/mysqld \
    && mysql_install_db --user=mysql --datadir=/var/lib/mysql --skip-test-db

# Copy WordPress files from source to web directory
RUN cp -r /usr/src/wordpress/* /var/www/html/ \
    && mkdir -p /var/www/html/wp-content/plugins \
    && mkdir -p /var/www/html/wp-content/themes \
    && mkdir -p /var/www/html/wp-content/uploads

# Download and install SportsPress plugin
RUN cd /tmp \
    && wget https://downloads.wordpress.org/plugin/sportspress.2.7.24.zip \
    && unzip sportspress.2.7.24.zip -d /var/www/html/wp-content/plugins/ \
    && rm sportspress.2.7.24.zip

# Copy configuration files from organized directories
COPY config/wordpress/wp-config.php /var/www/html/
COPY config/supervisor/supervisord.conf /etc/supervisord.conf
COPY config/mariadb/init-db.sql /docker-entrypoint-initdb.d/
COPY config/mariadb/my.cnf /etc/my.cnf.d/99-test-optimizations.cnf
COPY config/nginx/nginx.conf /etc/nginx/nginx.conf
COPY config/php/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf

# Create tmpfs mount point for temporary files
RUN mkdir -p /dev/shm && chmod 1777 /dev/shm

# Copy setup script
COPY config/scripts/setup-test-data.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup-test-data.sh

# Create necessary directories and set proper permissions
RUN mkdir -p /var/log/nginx /var/lib/nginx/tmp \
    && touch /var/log/php_errors.log \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chown -R mysql:mysql /var/lib/mysql \
    && chown -R www-data:www-data /var/log/nginx \
    && chown www-data:www-data /var/log/php_errors.log

# Set default sport for SportsPress demo data
ENV SPORTSPRESS_SPORT=ice-hockey

EXPOSE 80 3306

# Use supervisord to manage nginx, php-fpm, and MariaDB
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]