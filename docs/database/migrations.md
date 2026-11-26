---
title: Migrations
description: Versioned schema changes for PostgreSQL, MySQL/MariaDB and SQLite.
---
# Migrations

```bash
silth g migration create_products name:string price:decimal 'description:text?'
silth g migration add_sku_to_products sku:string
```

```crystal
class CreateProducts < Silth::Migration
  version 2026_11_24_120000

  def change
    create_table :products do |t|
      t.id                                   # BIGINT identity / AUTO_INCREMENT / INTEGER PK
      t.string :name, null: false
      t.decimal :price, precision: 10, scale: 2
      t.text :description
      t.boolean :active, null: false, default: true
      t.jsonb :attributes, default: :empty_json
      t.references :category, on_delete: :nullify, null: true
      t.timestamps
      t.soft_deletes
      t.index [:category_id, :active]
      t.unique :name
      t.fulltext [:name, :description]
    end
  end
end
```

## Reversible migrations

Rolling back a `change` migration replays it backwards: each command is recorded, then its inverse runs, last command first.

| Command | Rolled back with |
|---|---|
| `create_table :t do … end` | `drop_table :t` |
| `drop_table :t do … end` (block describes the table) | `create_table :t do … end` |
| `add_column :t, :c, :type` | `remove_column :t, :c` |
| `remove_column :t, :c, :type, **options` | `add_column :t, :c, :type, **options` |
| `rename_table`, `rename_column` | the opposite rename |
| `add_index :t, :c` | `remove_index` (same name) |
| `remove_index :t, columns: :c` | `add_index :t, :c` |
| `add_foreign_key :t, :c, :other` | `remove_foreign_key :t, :c` |
| `remove_foreign_key :t, :c, :other` | `add_foreign_key :t, :c, :other` |
| `enable_extension` / `disable_extension` | the other one |

`execute`, `change_column`, `remove_index` by name, `drop_table` without a block and `remove_column` without its type cannot be reversed: rolling back raises `Silth::Migration::Irreversible`. Wrap direction-specific code in `reversible`, or write `up`/`down` instead:

```crystal
def change
  add_column :products, :slug, :string
  reversible do |dir|
    dir.up { execute "UPDATE products SET slug = lower(name)" }
    dir.down { execute "UPDATE products SET name = slug" }
  end
end
```

Generators write `change` for `create_*` and `add_*_to_*` migrations, `up`/`down` for the others.

## Schema file

`db/schema.cr` describes the whole database with the same DSL:

```crystal
Silth::DB::SchemaDefinition.define(version: 20261124120000) do |s|
  s.create_table "products" do |t|
    t.id
    t.string "name", null: false, limit: 255
    t.decimal "price", precision: 10, scale: 2
    t.index ["category_id", "active"], name: "index_products_on_category_id_and_active"
  end

  s.add_foreign_key "products", "category_id", "categories", on_delete: :nullify, name: "products_category_id_fkey"
end
```

It is rewritten after `db:migrate`, `db:rollback`, `db:reset` and `db:fresh` in development (`schema_dump: true|false` in `config/database.yml` changes that), or on demand with `silth db:schema:dump`. Commit it: `silth db:schema:load` drops every table and recreates the database from it in one go, much faster than replaying years of migrations (CI, new machines), and marks the migrations up to its version as applied.

Tables, columns, defaults, primary keys (composite too), indexes (partial, GIN, opclasses), foreign keys, generated columns and PostgreSQL extensions are dumped. Indexes on expressions are kept as raw SQL. Check constraints, views, triggers and functions are not: keep those in migrations. Other connections are dumped to `db/<name>_schema.cr` (`--connection=analytics`); require the file from `src/cli.cr`.


## Column types

`string` (`limit:`), `text`, `integer`, `bigint`, `smallint`, `float`, `real`, `decimal`, `boolean`, `date`, `time`, `timestamp`/`datetime`, `json`/`jsonb`, `binary`, `uuid`, `inet`, `citext`, `string_array`, `integer_array`, `float_array`, `vector(name, dimensions)`, `tsvector(name, from: [...])`. Options: `null:`, `default:` (`:now`, `:uuid`, `:empty_json` or a literal), `unique:`, `index:`, `limit:`, `comment:`.

Types map to the best native type of each database (e.g. `json` → `JSONB` on PostgreSQL, `JSON` on MySQL, `TEXT` on SQLite).

## Schema helpers

`add_column`, `remove_column`, `rename_column`, `change_column`, `add_index` (`using: "gin"`, `opclass:`, `where:`), `remove_index`, `add_foreign_key` (`on_delete:`, `on_update:`, `name:`), `remove_foreign_key`, `rename_table`, `drop_table`, `enable_extension "vector"`, `disable_extension`, `execute "raw SQL"`. `create_table :x, unlogged: true` (PostgreSQL UNLOGGED table). In `create_table`: `t.foreign_key :author_id, :users`, `t.primary_key [:post_id, :tag_id]`, `generated: "expression"` on any column, `default: Silth::DB::Raw.new("SQL expression")`.

## Commands

```bash
silth db:create        silth db:drop
silth db:migrate       silth db:migrate --step=1
silth db:rollback      silth db:rollback --step=2
silth db:status        silth db:reset       silth db:fresh --seed
silth db:schema:dump   silth db:schema:load
silth db:console       silth db:console --connection=analytics --replica
```

`db:console` opens the database's own client on the configured URL: `psql`, `mariadb` (or `mysql`) or `sqlite3`. The password goes through the environment (`PGPASSWORD`, `MYSQL_PWD`), never the command line; TLS settings follow the URL (`sslmode`, `ssl=true`). `--replica` opens the first read replica, `--print` shows the command without running it.

Migrations run inside a transaction on PostgreSQL and SQLite (MySQL does not support transactional DDL). Applied versions are stored in `silth_migrations` with a batch number; `db:rollback` reverts the last batch.
