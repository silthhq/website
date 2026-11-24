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

## Locks, CTEs and LISTEN/NOTIFY

`lock_for_update(skip_locked: true)` powers the database queue. `with_cte` builds common table expressions. The PostgreSQL connection exposes `wait_for_notification` for `LISTEN/NOTIFY` based integrations.
