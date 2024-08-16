# MYSQL
Connect from host with `localhost:3306`

# Metabase
http://localhost:3001

## Migration
When migrating data, we cannot start metabase and mysql together otherwise metabase bootstrap and we will have foreign keys errors.

1. Make sure metabase source and target have the same version as well for the DB itself
2. Start mysql: `docker-compose up mysql -d`
2. Restore DB: `mysql -h 127.0.0.1 -u root -psuperuser mydb < backup.sql`
3. After restoring, start metabase `docker-compose up metabase-mysql -d`

