---
title: Relationships
description: belongs_to, has_many, has_one, many-to-many and eager loading.
---
# Relationships

```crystal
class User < ApplicationModel
  primary_key
  has_many posts : Post, dependent: :destroy     # :destroy | :delete | :nullify
  has_one profile : Profile
end

class Post < ApplicationModel
  primary_key
  belongs_to user : User                         # declares user_id : Int64
  belongs_to editor : User, foreign_key: "editor_id", optional: true
  has_many tags : Tag, through: "post_tags"      # many-to-many pivot table
end
```

## Using them

```crystal
post.user                    # User? (lazy, cached)
post.user!                   # raises if missing
post.user = current_user     # sets user_id

user.posts                   # chainable query: user.posts.published.latest
user.posts.count
user.posts.build(title: "Draft")   # user_id preset
user.posts.create!(title: "Live")

post.tags.to_a
post.attach_tags([1, 2])
post.detach_tags([2])
post.sync_tags([3, 4])       # pivot rows become exactly [3, 4]
```

## Eager loading

Avoid N+1 queries with `includes` (one extra query per relation):

```crystal
posts = Post.includes(:user, :tags).latest.limit(20).to_a
posts.each { |p| puts "#{p.title} by #{p.user.try(&.name)} — #{p.tags.map(&.name).join(", ")}" }
```

The profiler flags duplicated queries so N+1 problems are easy to spot.

## Polymorphic relations

One table can belong to several models: the row stores the class name and the id.

```crystal
class Comment < ApplicationModel
  primary_key
  belongs_to commentable : Post | Video, polymorphic: true  # commentable_type + commentable_id
end

class Post < ApplicationModel
  primary_key
  has_many comments : Comment, as: commentable
end

class Video < ApplicationModel
  primary_key
  has_one comment : Comment, as: commentable
end

comment = Comment.create!(body: "Nice", commentable: post)
comment.commentable_type                 # "Post"
comment.commentable.as(Post)             # Silth::Model? (cast to the class you expect)
post.comments.create!(body: "Again")     # type and id preset
Comment.includes(:commentable).to_a      # one query per class
```

The migration needs both columns: `t.string :commentable_type` and `t.bigint :commentable_id` (plus an index on the pair). The type list (`Post | Video`) is optional: without it any model is accepted; with it, assigning another class raises `ArgumentError`. With a single class (`belongs_to imageable : User, polymorphic: true`) the reader returns that class. Polymorphic keys are `Int64` primary keys.

## Counter caches

```crystal
class Comment < ApplicationModel
  belongs_to post : Post, counter_cache: true               # posts.comments_count
  belongs_to author : User, counter_cache: :comments_written # custom column
end
```

The parent's counter (`t.integer :comments_count, null: false, default: 0`) is incremented on create, decremented on destroy, moved when the foreign key changes, and follows soft deletes and `restore`. Updates go straight to the counter column (no callbacks, no lock check), inside the child's transaction. Counter caches are not available on polymorphic relations.

## Conventions

| Declaration | Foreign key | Table |
|---|---|---|
| `belongs_to user : User` | `posts.user_id` | — |
| `has_many posts : Post` (in `User`) | `posts.user_id` | — |
| `has_many tags : Tag, through: "post_tags"` | `post_tags.post_id`, `post_tags.tag_id` | `post_tags` |

Override with `foreign_key:` and `related_key:`.
