---
title: PostgreSQL superpowers
description: Vector similarity search, full-text search, JSONB and more.
---
# PostgreSQL superpowers

Silth targets every database, but it goes further on PostgreSQL.

## Vector search (pgvector)

```crystal
class CreateDocuments < Silth::Migration
  version 2026_11_24_130000

  def up
    enable_extension "vector"
    create_table :documents do |t|
      t.id
      t.text :content, null: false
      t.vector :embedding, 1536
      t.timestamps
      t.index :embedding, using: "hnsw", opclass: "vector_cosine_ops"
    end
  end
end

class Document < ApplicationModel
  primary_key
  column content : String
  column embedding : Array(Float32)?
  timestamps
end
```

```crystal
query = embed("How do I deploy?")             # Array(Float32) from your embedding model
Document.nearest(:embedding, query, metric: :cosine).limit(5).to_a
Document.select_distance(:embedding, query).nearest(:embedding, query).limit(5).each do |doc|
  puts "#{doc.content} (#{doc["distance"]})"
end
Document.where_distance(:embedding, query, max: 0.3)
```

Metrics: `:cosine` (`<=>`), `:l2` (`<->`), `:inner_product` (`<#>`), `:l1` (`<+>`). This is everything you need for retrieval-augmented generation (RAG).

## Full-text search

```crystal
create_table :articles do |t|
  t.id
  t.string :title
  t.text :body
  t.tsvector :search, from: [:title, :body], language: "english"   # generated column + GIN index
end
```

```crystal
Article.search([:title, :body], %("crystal web" -rails))          # websearch syntax
Article.search(:title, "crystal", vector: :search).order_by_relevance(:title, "crystal", vector: :search)
```

## JSONB, arrays and more

```crystal
t.jsonb :settings, default: :empty_json
t.string_array :tags
Product.where_json(:settings, "shipping.express", "true")
Product.where_json_contains(:settings, {"featured" => true})
Product.where("? = ANY(tags)", "sale")
Product.where("settings ?? ?", "discount")        # `??` escapes the jsonb `?` operator
```

## Prepared statements

Each statement is prepared once per connection and reused: PostgreSQL parses and plans it the first time, later executions only send the parameters. A small LRU cache keeps the last 256 statements of each connection.

```yaml
url: postgres://app@db/app?statement_cache_size=512     # larger cache
url: postgres://app@pgbouncer/app?prepared_statements=false
```

Turn them off behind PgBouncer in transaction mode before 1.21 (a statement prepared on one server connection is unknown to the next). When a migration changes a table that a cached `SELECT *` reads, the statement is prepared again automatically; inside a transaction the error is raised instead (PostgreSQL aborted the transaction), and the next attempt succeeds.

## Locks, CTEs and LISTEN/NOTIFY

`lock_for_update(skip_locked: true)` powers the database queue. `with_cte` builds common table expressions. The PostgreSQL connection exposes `wait_for_notification` for `LISTEN/NOTIFY` based integrations, and `pubsub: postgres` (config/realtime.yml) relays live components and channels between server nodes over it.

## UNLOGGED tables: cache, sessions, logs

An UNLOGGED table skips the write-ahead log: writes cost a fraction of a regular table's, and PostgreSQL empties the table after a crash (a clean restart keeps it). That is the right trade for data you can rebuild, and it saves running Redis next to the database.

```yaml
# config/cache.yml
default: postgres
stores:
  postgres: { connection: primary }        # table silth_unlogged_cache

# config/session.yml
driver: postgres                           # table silth_sessions, the cookie holds a signed id
# connection: primary

# config/logging.yml
postgres:                                  # table silth_logs, written in batches
  connection: primary
  level: info
  retention_days: 14
```

- **Cache**: every operation is one statement (`INSERT … ON CONFLICT`), `add` and `increment` included, so locks, unique jobs and rate limits stay atomic across servers. Expired rows are pruned as you write.
- **Sessions**: data stays on the server; `regenerate` and `invalidate` delete the previous row, so an old cookie stops working at logout. A crash signs everybody out.
- **Logs**: entries are buffered and inserted by a background fiber (every second or 200 entries), never inside the request's transaction; entries from the database layer itself are skipped. Query them with SQL: `SELECT * FROM silth_logs WHERE level = 'error' ORDER BY id DESC`.

Your own tables can be UNLOGGED too: `create_table :page_views, unlogged: true do |t| … end` (ignored by other databases; `db/schema.cr` keeps the flag). The tables above are created on first use and left out of `db/schema.cr`.
