---
title: Models
description: Columns, validations, scopes, hooks, dirty tracking and serialization.
---
# Models

```crystal
class Post < ApplicationModel
  # table posts             (default: pluralized class name)
  # connection analytics    (default: primary)
  primary_key                               # id : Int64, auto increment
  column title : String
  column slug : String
  column body : String?
  column views : Int32 = 0
  column published : Bool = false
  column metadata : JSON::Any?
  column settings : PostSettings?           # any JSON::Serializable type
  column status : Status = Status::Draft    # enums (stored as integers)
  column api_secret : String, hidden: true  # excluded from to_json
  timestamps                                # created_at / updated_at
  soft_deletes                              # deleted_at

  validates title, presence: true, length: {min: 3, max: 120}
  validates slug, format: /\A[a-z0-9-]+\z/, uniqueness: true
  validates views, numericality: {greater_than: -1, integer: true}

  scope published { where(published: true) }
  scope popular { |min| where(:views, ">=", min) }

  def before_save
    self.slug = Silth::Inflector.parameterize(title) if slug?.nil?
  end
end
```

## Reading attributes

Non-nilable columns return their type and **raise** when the value is missing (not loaded or never set). Use the `?` variant for a nilable read: `post.title` → `String`, `post.title?` → `String?`. For `Bool` columns, `post.published?` returns `Bool`.

## CRUD

```crystal
post = Post.new(title: "Hello")      # unknown attributes are compile errors
post.save                            # => Bool (runs validations)
post.save!                           # raises RecordInvalid
Post.create!(title: "Hi")
post.update(title: "New")
post.destroy                         # soft delete when enabled
Post.find(1)                         # raises RecordNotFound (404 in controllers)
Post.find?(1)  Post.find_by(slug: "hi")  Post.first_or_create(slug: "hi")
post.reload  post.touch  post.increment!(:views)
```

## Querying

Every query builder method works on models and returns typed records:

```crystal
Post.published.popular(100).latest.limit(5).to_a        # Array(Post)
Post.where(user_id: user.id).count
Post.with_trashed / Post.only_trashed
Post.paginate(params.int("page", 1), 20)                  # Silth::DB::Page(Post)
Post.cursor_paginate(20, params["cursor"]?)               # keyset pagination
Post.find_each(500) { |post| … }
Post.find_by_sql("SELECT * FROM posts WHERE …", [1])
```

Scopes are chainable on any query: `Post.where(…).published`.

## Validations

`presence`, `length` (`{min:, max:, is:}` or a range), `format`, `email`, `url`, `inclusion`, `exclusion`, `numericality` (`{greater_than:, less_than:, integer:}`), `uniqueness` (`{scope: [:user_id]}`), `confirmation`, `acceptance`, plus `if: :method_name` and `message:`. Custom rules: override `validate` and add to `errors`.

```crystal
def validate
  errors.add("ends_at", "must be after starts_at") if ends_at < starts_at
end
```

Error messages are translated (`errors.messages.*` keys).

## Hooks

Override any of: `before_validation`, `after_validation`, `before_save`, `after_save`, `before_create`, `after_create`, `before_update`, `after_update`, `before_destroy`, `after_destroy`. Saves run inside a transaction.

## Dirty tracking

```crystal
post.title = "New"
post.changed?                  # true
post.changes                   # {"title" => {"Old", "New"}}
post.attribute_changed?(:title)
```

Updates only write changed columns.

## Mass assignment

```crystal
post.assign(params.permit(:title, :body, from: :post))   # strings are cast to column types
post.assign(title: "x", views: 3)                         # typed
```

## Optimistic locking

```crystal
class Order < ApplicationModel
  primary_key
  column total : Float64
  optimistic_locking               # needs `t.lock_version` in the migration
end

a = Order.find(1)
b = Order.find(1)
a.update!(total: 10.0)             # lock_version 0 → 1
b.update!(total: 12.0)             # raises Silth::ORM::StaleObjectError
```

Every update and destroy checks that `lock_version` still holds the value read with the record and increments it. Rescue `StaleObjectError`, `reload` and let the user retry. `optimistic_locking column: version` uses another column.

## Serialization

`post.to_json` writes every non-hidden column plus extra selected columns (`distance`, aggregates). `post.attributes` returns a hash, `post.read_attribute("title")`/`write_attribute` work dynamically.
