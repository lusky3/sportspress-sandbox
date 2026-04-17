FROM wordpress:6.9.4-php8.5-fpm-alpine

# Install MariaDB, wp-cli, nginx, and supervisord for process management
RUN apk add --no-cache \
    wget \
    mariadb \
    mariadb-client \
    nginx \
    supervisor \
    bash \
    git \
    composer \
    py3-pip \
    $PHPIZE_DEPS \
    linux-headers \
    && pip3 install "setuptools==69.5.1" --break-system-packages \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && apk del $PHPIZE_DEPS linux-headers

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

# Download and install SportsPress plugin and dev tools
RUN cd /tmp \
    && wget https://downloads.wordpress.org/plugin/sportspress.2.7.29.zip -O sportspress.zip \
    && unzip sportspress.zip -d /var/www/html/wp-content/plugins/ \
    && rm sportspress.zip \
    && wget https://downloads.wordpress.org/plugin/user-switching.1.11.2.zip -O user-switching.zip \
    && unzip user-switching.zip -d /var/www/html/wp-content/plugins/ \
    && rm user-switching.zip \
    && wget https://downloads.wordpress.org/plugin/query-monitor.4.0.6.zip -O query-monitor.zip \
    && unzip query-monitor.zip -d /var/www/html/wp-content/plugins/ \
    && rm query-monitor.zip \
    && wget https://downloads.wordpress.org/plugin/debug-bar.1.1.8.zip -O debug-bar.zip \
    && unzip debug-bar.zip -d /var/www/html/wp-content/plugins/ \
    && rm debug-bar.zip \
    && wget https://downloads.wordpress.org/plugin/woocommerce.10.7.0.zip -O woocommerce.zip \
    && unzip woocommerce.zip -d /var/www/html/wp-content/plugins/ \
    && rm woocommerce.zip \
    && wget https://github.com/Automattic/wordpress-mcp/archive/295b5cc.zip -O wordpress-mcp.zip \
    && unzip wordpress-mcp.zip -d /var/www/html/wp-content/plugins/ \
    && mv /var/www/html/wp-content/plugins/wordpress-mcp-* /var/www/html/wp-content/plugins/wordpress-mcp \
    && rm wordpress-mcp.zip \
    && wget https://github.com/WordPress/abilities-api/archive/5f64910.zip -O abilities-api.zip \
    && unzip abilities-api.zip -d /var/www/html/wp-content/plugins/ \
    && mv /var/www/html/wp-content/plugins/abilities-api-* /var/www/html/wp-content/plugins/abilities-api \
    && rm abilities-api.zip

# Copy configuration files from organized directories
COPY config/wordpress/wp-config.php /var/www/html/
COPY config/wordpress/mu-plugins/ /var/www/html/wp-content/mu-plugins/
COPY config/supervisor/supervisord.conf /etc/supervisord.conf
COPY config/supervisor/conf.d /etc/supervisor/conf.d
COPY config/mariadb/init-db.sql /docker-entrypoint-initdb.d/
COPY config/mariadb/my.cnf /etc/my.cnf.d/99-test-optimizations.cnf
COPY config/nginx/nginx.conf /etc/nginx/nginx.conf
COPY config/php/php-fpm.conf /usr/local/etc/php-fpm.d/www.conf
COPY config/php/xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
COPY config/php/mailpit.ini /usr/local/etc/php/conf.d/mailpit.ini

# Create tmpfs mount point for temporary files
RUN mkdir -p /dev/shm && chmod 1777 /dev/shm

# Copy setup script
COPY config/scripts/setup-test-data.sh /usr/local/bin/
COPY config/scripts/start.sh /usr/local/bin/
COPY config/scripts/generate-extra-data.php /usr/local/bin/
RUN chmod +x /usr/local/bin/setup-test-data.sh /usr/local/bin/start.sh

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

EXPOSE 80

# Use supervisord to manage nginx, php-fpm, and MariaDB
CMD ["/usr/local/bin/start.sh"]
