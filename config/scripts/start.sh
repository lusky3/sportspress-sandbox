#!/bin/bash
set -e

DB_HOST=${WORDPRESS_DB_HOST:-localhost}

if [[ "$DB_HOST" != "localhost"* ]] && [[ "$DB_HOST" != "127.0.0.1"* ]]; then
    echo "Using external database at $DB_HOST"
    if [ -f /etc/supervisor/conf.d/mariadb.conf ]; then
        mv /etc/supervisor/conf.d/mariadb.conf /etc/supervisor/mariadb.conf.disabled
    fi
else
    echo "Using internal MariaDB"
    if [ -f /etc/supervisor/mariadb.conf.disabled ]; then
        mv /etc/supervisor/mariadb.conf.disabled /etc/supervisor/conf.d/mariadb.conf
    fi
fi

exec /usr/bin/supervisord -c /etc/supervisord.conf
