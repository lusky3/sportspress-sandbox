# Supervisor Configuration

## supervisord.conf

Process management configuration:

1. MariaDB (priority 1)
2. PHP-FPM (priority 2)
3. Nginx (priority 3)
4. Setup script (priority 4, runs once)

Manages all services in the container with proper startup order.
