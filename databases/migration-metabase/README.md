# Metabase Migrations

This describes how you can migrate metabase from mysql to postgres.

All  this steps are necessary because currently metabase only supports migrations from/to their non production H2 DB according to [this issue](https://github.com/metabase/metabase/issues/37101)

**Important: SOURCE DB VERSION and METABASE VERSION have to remain the same through out this guide - so adjust version in this repo accordingly**

Steps:
1. Setup a copy of production metabase and run it locally
2. Migrate from mysql to H2
3. Migrate from H2 to postgres

## Setup a copy of production and run locally

* Take a mysqldump from production: `mysqldump -h HOST -u USER -p'${YOUR_PASSWORD}' METABASE_DB > metabase_prd_backup.sql`
* Start mysql:  `docker-compose up -d mysql`
* Restore the data into the mysql container: `mysql -h 127.0.0.1 -u root -psuperuser metabase < metabase_prd_backup.sql`
* Run metabase over mysql: `docker-compose up -d metabase-mysql`
* Once you are able to login in your copy of production on `localhost:3001` you can proceed to next step

## Migrate from mysql to H2

Enter on metabase-mysql: `docker-compose exec metabase-mysql bash`

Migrate DB from mysql to H2: 

```
cd /app
java -jar metabase.jar dump-to-h2 /tmp/metabase_prod.h2.db`
```

Once finished it will generate 2 files with extensions .trace.db and .mv.db

Copy the migrated DB to your laptop for backup: `docker-compose cp metabase-mysql:/tmp/ <PATH_ON_LAPTOP>`


## Migrate from H2 to postgres

We are going to use another metabase instance to migrate the data called metabase-h2. We do this because we cannot start metabase on postgres until the data is fully migrated otherwise you will have errors.

Run postgres: `docker-compose up -d postgres`

Run another metabase instance with H2 DB: `docker-compose up -d metabase-h2`

Copy the H2 DB to this container: `docker-compose cp <PATH_ON_LAPTOP> metabase-h2:/tmp/`

Enter on the container: `docker-compose exec metabase-h2 bash`

Setup postgres on the instance: `export MB_DB_TYPE=postgres MB_DB_PORT=5432 MB_DB_USER=postgres MB_DB_PASS=superuser MB_DB_HOST=postgres MB_DB_DBNAME=postgres`

Import data to postgres. It's important that you don't pass the full name of the file and only a part of it. For example if you use the did the command from previous section it should have generated 2 files: metabase_prod.h2.db.trace.db and metabase_prod.h2.db.mv.db

Upon running the migration command, omit .trace.db and .mv.db extensions:

```
cd /app
java -jar metabase.jar load-from-h2 /tmp/metabase_prod.h2.db
```

Once loaded you can start metabase: `docker-compose up -d metabase-postgres` and test it.

**Using a remote postgres instead local**

If you wish to migrate to a remote postgres instead. Do the same steps above but replace the MB variables on the export command.


## Troubleshooting migration

**If dump-to-h2 or load-from-h2 are too slow or you have out of memory errors**
If command above is slow or if you have out of memory issues, give more memory by adding `-Xmx<NUMBER_OF_GB>g` argument


**During step 1: If you have issues during metabase-mysql start**

During this step metabase might fail to start due to migrations. The table responsable for migrations is called **databasechangelog**.Sometimes you will have errors that this table or others already exists, you might have to rename tables from lower case to upper case.

Remove the metabase instance: `docker-compose down metabase-mysql`

Adjust the tables, for example:

```
RENAME TABLE metabase.databasechangelog TO metabase.DATABASECHANGELOG;
RENAME TABLE metabase.databasechangeloglock TO metabase.DATABASECHANGELOGLOCK;
... # More renames might be required
```

Run: `docker-compose up -d metabase-mysql` & Test: `localhost:3001`


**During step 3: Errors with metabase_field table**

Caused by: org.postgresql.util.PSQLException: ERROR: duplicate key value violates unique constraint "idx_uniq_field_table_id_parent_id_name_2col"
  Detail: Key (table_id, name)=(480, EventCode) already exists.

During migration of postgres the error above was found. The solution according to the [this issue](https://github.com/metabase/metabase/issues/37101) would be to delete the rows affected by such constrain. You can list all violations by executing the following sql in your DB:

`SELECT table_id,name FROM metabase.metabase_field GROUP BY table_id,name HAVING Count(*) > 1;`

Now for each element and delete the older entry of line on the table that has the 2 elements table_id and name.