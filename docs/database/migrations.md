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

  def up
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

  def down
    drop_table :products
  end
end
```

## Column types

`string` (`limit:`), `text`, `integer`, `bigint`, `smallint`, `float`, `real`, `decimal`, `boolean`, `date`, `time`, `timestamp`/`datetime`, `json`/`jsonb`, `binary`, `uuid`, `inet`, `citext`, `string_array`, `integer_array`, `float_array`, `vector(name, dimensions)`, `tsvector(name, from: [...])`. Options: `null:`, `default:` (`:now`, `:uuid`, `:empty_json` or a literal), `unique:`, `index:`, `limit:`, `comment:`.

Types map to the best native type of each database (e.g. `json` → `JSONB` on PostgreSQL, `JSON` on MySQL, `TEXT` on SQLite).

## Schema helpers

`add_column`, `remove_column`, `rename_column`, `change_column`, `add_index` (`using: "gin"`, `opclass:`, `where:`), `remove_index`, `add_foreign_key`, `rename_table`, `drop_table`, `enable_extension "vector"`, `execute "raw SQL"`.

## Commands

```bash
silth db:create        silth db:drop
silth db:migrate       silth db:migrate --step=1
silth db:rollback      silth db:rollback --step=2
silth db:status        silth db:reset       silth db:fresh --seed
silth db:console
```

Migrations run inside a transaction on PostgreSQL and SQLite (MySQL does not support transactional DDL). Applied versions are stored in `silth_migrations` with a batch number; `db:rollback` reverts the last batch.
