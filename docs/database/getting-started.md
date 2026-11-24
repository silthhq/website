---
title: Database
description: Connections, drivers, raw queries and transactions.
---
# Database

Silth ships its **own drivers**, written on top of Crystal's standard library:

| Database | Driver | Notes |
|---|---|---|
| PostgreSQL 12+ | wire protocol v3 | TLS, SCRAM-SHA-256/MD5, pgvector, LISTEN/NOTIFY |
| MySQL 8 / MariaDB 10.6+ | protocol 4.1 | TLS, `mysql_native_password`, `caching_sha2_password` |
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

URLs: `postgres://user:pass@host:5432/db?sslmode=prefer`, `mysql://user:pass@host:3306/db?ssl=true`, `sqlite3://./db/dev.sqlite3`, `sqlite3::memory:`.

## Raw queries

Placeholders are always `?`, on every database.

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

Nested transactions use savepoints. Queries made by the same fiber inside the block reuse the transaction's connection. Run code after commit with `Silth::DB.connection.after_commit { … }` (jobs and events have `dispatch_after_commit`).

## Errors

`Silth::DB::UniqueViolation`, `ForeignKeyViolation`, `NotNullViolation`, `SerializationFailure` (all `QueryError`) are raised consistently across drivers.
