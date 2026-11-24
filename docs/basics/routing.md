---
title: Routing
description: Define routes, resources, scopes, constraints and named URLs.
---
# Routing

Routes live in `config/routes.cr`. They are Crystal code, so a route pointing to a missing controller action is a **compile error**.

```crystal
Silth.routes do
  get "/", HomeController, :index, name: "home"
  post "/contact", ContactController, :create
  get "/ping" { |ctx| ctx.text "pong" }             # closure route
  redirect "/old-blog", "/posts"
end
```

Verbs: `get`, `post`, `put`, `patch`, `delete`, `options`, `any`. `HEAD` requests are answered by `GET` routes.

## Parameters

```crystal
get "/posts/:id", PostsController, :show            # params["id"]
get "/files/*path", FilesController, :show          # glob: "a/b/c.txt"
get "/users/:id<\\d+>", UsersController, :show      # inline regex constraint
get "/u/:slug", UsersController, :show, constraints: {slug: /[a-z\-]+/}
```

Static segments win over parameters, which win over globs.

## Resources

```crystal
resources "posts", PostsController                  # index new create show edit update destroy
resources "photos", PhotosController, only: [:index, :show]
resources "posts", PostsController do               # nested: /posts/:post_id/comments
  resources "comments", CommentsController, except: [:edit]
end
```

Only actions the controller actually defines are registered. Names follow `posts.index`, `posts.show`, `posts.comments.create`…

## Scopes and groups

```crystal
scope "/admin", name: "admin", middleware: [:auth, RequireAdmin] do
  get "/", Admin::DashboardController, :index       # admin.dashboard.index
end

api do                                              # /api prefix, "api." names, "api" group
  resources "posts", Api::PostsController, except: [:new, :edit]
end
```

Middleware accepts aliases (`:auth`, `:guest`, `:verified`, `:signed`, `:throttle`), classes (instantiated) or instances.

Every route belongs to a **middleware group**: `web` by default (sessions, CSRF, locale, session auth) or `api` (token auth, rate limiting, no session).

## Named routes and URLs

```crystal
route("posts.show", id: post.id)          # "/posts/42"
route("posts.index", page: 2)             # "/posts?page=2" (unknown params → query string)
Silth.router.url_for("home")
```

## Live pages

```crystal
live "/dashboard", DashboardComponent, name: "dashboard"
```

## Inspecting routes

```bash
silth routes                # table
silth routes --json         # for tools and AI agents
silth routes -f posts       # filter
```
