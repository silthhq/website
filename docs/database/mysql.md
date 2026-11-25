---
title: MySQL & MariaDB
description: Prepared statements, authentication plugins and driver options for MySQL 8 and MariaDB.
---
# MySQL & MariaDB

The MySQL driver speaks the client/server protocol 4.1 itself: no libmysqlclient, no shard.

## Prepared statements

Queries with parameters run as **server-side prepared statements** (binary protocol). Values travel in their binary form, never inside the SQL text, so there is nothing to escape and the server parses each statement once per connection.

```crystal
Silth::DB.query("SELECT * FROM users WHERE email = ? AND active = ?", ["ada@example.com", true])
User.where(email: "ada@example.com").first?   # same path through the ORM
```

- Statements are cached per connection (LRU, 256 by default) and reused when the same SQL comes back.
- Queries without parameters (DDL, `SAVEPOINT`, `SET`…) use the text protocol: one round trip, nothing to keep open.
- Statements the server cannot prepare (`HANDLER`…) fall back to client-side interpolation with strict escaping.
- A wrong number of parameters raises `Silth::DB::Error` before anything is sent.

Both protocols return the same Crystal values:

| Column | Crystal value |
|---|---|
| `TINYINT`, `SMALLINT`, `MEDIUMINT`, `INT`, `YEAR` | `Int32` (`Int64` for an `INT UNSIGNED` above `Int32::MAX`) |
| `BIGINT` | `Int64` |
| `FLOAT` / `DOUBLE`, `DECIMAL` | `Float32` / `Float64` |
| `DATE`, `DATETIME`, `TIMESTAMP` | `Time` in UTC (zero dates are `nil`) |
| `TIME` | `String`, e.g. `"-26:03:04.500"` |
| `JSON` | `JSON::Any` |
| `BLOB`, `BINARY`, `VARBINARY` | `Bytes` |
| `BIT` | `Int64` |
| other text types | `String` |

## Authentication

| Plugin | Over TLS | Plain TCP |
|---|---|---|
| `mysql_native_password` | ✓ | ✓ |
| `caching_sha2_password` (MySQL 8 default) | ✓ | ✓ (full authentication with RSA) |
| `sha256_password` | ✓ | ✓ (RSA) |

MySQL asks for the full password when its authentication cache is empty: first login of an account, after a restart or a `FLUSH PRIVILEGES`. Without TLS, Silth then fetches the server's RSA public key and sends the password encrypted with RSA-OAEP, like the official client. Fetching the key over plain TCP can be intercepted by a man in the middle, so in production use TLS or pin the key:

```bash
# once, from a trusted connection (or copy public_key.pem from the MySQL data directory)
mysql -N -e "SHOW STATUS LIKE 'Caching_sha2_password_rsa_public_key'" | cut -f2 > config/mysql_public_key.pem
```

```yaml
# config/database.yml
connections:
  primary:
    url: mysql://app:secret@db.internal:3306/app?server_public_key=config/mysql_public_key.pem
```

MariaDB accounts use `mysql_native_password`; its `ed25519` plugin is not supported yet.

Accounts using `mysql_clear_password` (LDAP, PAM) receive the password as is, so the driver only sends it over TLS. If the server asks for it on plain TCP the connection fails, unless the URL opts in with `allow_cleartext_password=true` (a man in the middle could otherwise request it with an auth switch).

## Options

| URL parameter | Default | Effect |
|---|---|---|
| `ssl=true` | off | TLS (also `sslmode=required`) |
| `statement_cache_size=N` | `256` | prepared statements kept per connection; `0` closes each one after use |
| `prepared_statements=false` | on | interpolate parameters client side and use the text protocol only (for proxies without prepared statement support) |
| `server_public_key=path` | | PEM public key used for RSA authentication instead of asking the server |
| `allow_cleartext_password=true` | off | let `mysql_clear_password` send the password without TLS |

The server caps prepared statements across all connections with `max_prepared_stmt_count` (16 382 by default): keep `pool × statement_cache_size × processes` below it. When the cap is reached, the driver interpolates instead of failing.
