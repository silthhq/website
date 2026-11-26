---
title: Database
description: Connections, drivers, raw queries and transactions.
---
# Database

Silth ships its **own drivers**, written on top of Crystal's standard library:

| Database | Driver | Notes |
|---|---|---|
| PostgreSQL 12+ | wire protocol v3 | TLS, SCRAM-SHA-256/MD5, pgvector, LISTEN/NOTIFY |
| MySQL 8 / MariaDB 10.6+ | protocol 4.1 | prepared statements (binary protocol), TLS, `mysql_native_password`, `caching_sha2_password` and `sha256_password` (RSA without TLS), MariaDB `ed25519` and `parsec`, see [MySQL & MariaDB](/docs/database/mysql) |
| SQLite 3.35+ | libsqlite3 | WAL mode and foreign keys enabled |

```yaml
# config/database.yml
default: primary
connections:
  primary:
    url: ${DATABASE_URL:-sqlite3://./db/development.sqlite3}
    pool: 10
  analytics:
    url: postgres://user:pass@db.internal:5432/analytics?sslmode=require
```

URLs: `postgres://user:pass@host:5432/db?sslmode=prefer`, `mysql://user:pass@host:3306/db?ssl=true`, `sqlite3://./db/dev.sqlite3`, `sqlite3::memory:`. MySQL also takes `statement_cache_size`, `prepared_statements` and `server_public_key` ([details](/docs/database/mysql#options)).

## Raw queries

Placeholders are always `?`, on every database. Values are sent separately from the SQL (extended protocol on PostgreSQL, prepared statements on MySQL, bound parameters on SQLite).

```crystal
rows = Silth::DB.query("SELECT id, email FROM users WHERE active = ?", [true]).to_hashes
Silth::DB.exec("UPDATE users SET active = ? WHERE id = ?", [false, 42])
Silth::DB.scalar("SELECT COUNT(*) FROM users")
Silth::DB.connection("analytics").query("SELECT …")
```

## Transactions

```crystal
Silth::DB.transaction do
  order.save!
  Payment.create!(order_id: order.id, amount: order.total)
end                                   # rollback on exception

Post.transaction { … }                 # on the model's connection
```

Nested transactions use savepoints. Queries made by the same fiber inside the block reuse the transaction's connection. The transaction commits when the block ends, also with `return` or `break`, and rolls back when it raises. Run code after commit with `Silth::DB.connection.after_commit { … }` (jobs and events have `dispatch_after_commit`).

## Read replicas

```yaml
# config/database.yml
connections:
  primary:
    url: postgres://app@db-primary/app
    replicas:
      - postgres://app@db-replica-1/app
      - postgres://app@db-replica-2/app
    sticky_for: 2        # seconds, default 2
```

Nothing changes in the code: each statement is routed on its own.

| Statement | Runs on |
|---|---|
| `SELECT`, `WITH`, `SHOW`, `EXPLAIN` | a replica, in turn |
| `INSERT`, `UPDATE`, `DELETE`, DDL, `exec_script` | the primary |
| anything inside `transaction { }` | the primary |
| `SELECT … FOR UPDATE` / `FOR SHARE`, `nextval()`, advisory locks, `WITH … DELETE` | the primary |
| reads after a write in the same request, job or live action | the primary |

The last rule is the "sticky" read: once a request wrote to a database, it reads its own writes back from the primary instead of a replica that may lag behind. A cookie (`silth_db_primary`) extends this to the next requests of the same client for `sticky_for` seconds, so the page a form redirects to shows the new record. Force the primary for a block with:

```crystal
order = Silth::DB.on_primary { Order.find(id) }
```

A replica that cannot be reached is skipped for 10 seconds and its reads go to the primary. Replicas share the primary's pool size and must be the same kind of database. The profiler shows where each query ran (`primary (replica 1)`).

## Errors

`Silth::DB::UniqueViolation`, `ForeignKeyViolation`, `NotNullViolation`, `SerializationFailure` (all `QueryError`) are raised consistently across drivers.
