---
title: Quickstart
description: Build a small blog with authentication, a live search and a JSON API.
---
# Quickstart: a blog in ten minutes

## 1. Create the app

```bash
silth new blog && cd blog && shards install
```

## 2. Authentication

```bash
silth g auth
```

This creates the `User` model, a migration (users + API tokens), login/registration/password-reset controllers, views and routes.

## 3. A resource

```bash
silth g scaffold Post title:string 'body:text?' published:bool 'user:references?'
silth db:migrate
```

> [!NOTE]
> Quote fields containing `?` (nullable) — shells such as zsh treat `?` as a glob.

You now have `src/models/post.cr`, a RESTful `PostsController`, views, a policy, a factory, a spec and `resources "posts", PostsController` in `config/routes.cr`.

## 4. Refine the model

```crystal
class Post < ApplicationModel
  primary_key
  column title : String
  column body : String?
  column published : Bool = false
  belongs_to user : User, optional: true
  timestamps

  validates title, presence: true, length: {min: 3, max: 120}

  scope published { where(published: true) }
end
```

## 5. A live search

```bash
silth g live PostSearch
```

```crystal
class PostSearchComponent < Silth::LiveComponent
  prop query : String = "", writable: true
  template "components/post_search"

  def results : Array(Post)
    query.empty? ? [] of Post : Post.published.search([:title, :body], query).limit(10).to_a
  end
end
```

```erb
<div>
  <input type="search" silth-model.debounce.250ms="query" value="<%= query %>" placeholder="Search…">
  <ul><% results.each do |post| %><li><%= post.title %></li><% end %></ul>
</div>
```

Embed it anywhere: `<%= live PostSearchComponent %>`.

## 6. A JSON API

```bash
silth g api Comment body:text 'post:references'
silth db:migrate
```

The API is documented automatically at `/docs/api`.

## 7. Test it

```bash
silth test
```

Next: read about [routing](/docs/basics/routing) and [models](/docs/database/models).
