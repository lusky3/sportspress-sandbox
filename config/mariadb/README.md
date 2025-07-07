# MariaDB Configuration

## my.cnf

Performance-optimized MariaDB configuration:
- 128MB buffer pool
- Query cache enabled
- Memory-based temp directory
- Reduced sync overhead for testing

## init-db.sql

Database initialization script:
- Creates `wordpress` database
- Creates `wordpress` user with full privileges