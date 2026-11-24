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

## Conventions

| Declaration | Foreign key | Table |
|---|---|---|
| `belongs_to user : User` | `posts.user_id` | — |
| `has_many posts : Post` (in `User`) | `posts.user_id` | — |
| `has_many tags : Tag, through: "post_tags"` | `post_tags.post_id`, `post_tags.tag_id` | `post_tags` |

Override with `foreign_key:` and `related_key:`.
