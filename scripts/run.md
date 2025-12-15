
Create database

```bash
psql -U postgres -c "CREATE DATABASE library_db;"
```

Create tables and insert sample data

```bash
psql -U postgres -d library_db -f create_tables.sql
```

```bash
psql -U postgres -d library_db -f insert_data.sql
```

Create logic

```bash
psql -U postgres -d library_db -f create_logic.sql
```

Run queries

```bash
psql -U postgres -d library_db -f queries.sql
```

Cleanup database 

```bash
psql -U postgres -d library_db -f drop_objects.sql
```

```bash
psql -U postgres -c "DROP DATABASE library_db;"
```

