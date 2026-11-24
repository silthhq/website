---
title: Query builder
description: Fluent, dialect-aware SQL for tables and models.
---
# Query builder

`Silth::DB.table("posts")` returns rows as `Hash(String, DB::Value)`; models use the same API and return typed records. Each method returns a **new** query.

```crystal
Silth::DB.table("posts")
  .select(:id, :title)
  .where(published: true)                   # =, IS NULL for nil, IN for arrays, BETWEEN for ranges
  .where(:views, ">", 100)                  # Symbol column + operator
  .where("lower(title) LIKE ?", "%crystal%")# raw SQL fragment
  .or_where(pinned: true)
  .where_not(status: "archived")
  .where_in(:category_id, [1, 2, 3])
  .where_null(:deleted_at)
  .where_between(:created_at, 1.week.ago, Time.utc)
  .where_group { |g| g.where(a: 1).or_where(b: 2) }   # (a = 1 OR b = 2)
  .join("users", "users.id = posts.user_id")
  .order(created_at: :desc)
  .limit(10).offset(20)
  .rows
```

## Aggregates & helpers

```crystal
q.count                 q.exists?               q.pluck(:title)
q.sum(:views)           q.avg(:rating)          q.min(:price)     q.max(:price)
q.first?                q.paginate(page, 20)    q.each_batch(500) { |rows| … }
q.group_by(:status).having("COUNT(*) > ?", 3)
q.with_cte("recent", "SELECT * FROM posts WHERE created_at > ?", 1.day.ago)
q.lock_for_update(skip_locked: true)
q.explain
```

## Writes

```crystal
id = Silth::DB.table("posts").insert(title: "Hi", views: 0)    # returns the id
Silth::DB.table("posts").insert_all(rows)
Silth::DB.table("posts").where(id: id).update(views: 1)
Silth::DB.table("posts").where(id: id).increment(:views)
Silth::DB.table("posts").upsert(rows, conflict: ["slug"], update: ["title"])
Silth::DB.table("posts").where(:views, "<", 1).delete
```

## Search across databases

```crystal
q.search([:title, :body], "fast crystal")   # PostgreSQL websearch_to_tsquery, MySQL MATCH…AGAINST, SQLite LIKE
q.order_by_relevance([:title, :body], "fast crystal")
q.where_json(:settings, "theme.color", "dark")
q.where_json_contains(:tags, ["crystal"])    # PostgreSQL @>, MySQL JSON_CONTAINS
```

> [!NOTE]
> MySQL/MariaDB require a `FULLTEXT` index on exactly the searched columns (`t.fulltext [:title, :body]`), and InnoDB only indexes rows once committed.
