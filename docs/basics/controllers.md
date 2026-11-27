---
title: Controllers
description: Actions, filters, rendering, redirects and error handling.
---
# Controllers

```crystal
class PostsController < ApplicationController
  before_action :authenticate!, except: [:index, :show]
  before_action :load_post, only: [:show, :edit, :update, :destroy]
  after_action :track, only: :show

  def index
    posts = Post.published.latest.paginate(params.int("page", 1), 20)
    render "posts/index", posts: posts
  end

  def show
    render "posts/show", post: @post.not_nil!
  end

  def update
    post = @post.not_nil!
    authorize! :update, post
    if post.assign(params.permit(:title, :body, from: :post)).save
      redirect route("posts.show", id: post.id), notice: "Saved"
    else
      render "posts/edit", status: 422, post: post
    end
  end

  private def load_post
    @post = Post.find(params["id"])   # raises RecordNotFound → 404
  end

  @post : Post?
end
```

A filter that responds (redirect, render, head) halts the request.

## Responding

| Method | Effect |
|---|---|
| `render "dir/template", layout: "layouts/x", status: 200, **locals` | HTML from `src/views/dir/template.html.ecr` |
| `json(data, status = 200)` | `data.to_json` |
| `text`, `html`, `xml` | raw bodies |
| `redirect(url, notice: "…", alert: "…")` | 302 + flash |
| `redirect_back(fallback: "/")` | same-origin referer |
| `head(204)`, `no_content` | empty body |
| `send_file(path)`, `send_data(bytes, filename)` | downloads |
| `stream { \|io\| … }`, `sse { \|events\| … }` | streaming & server-sent events |
| `problem(422, "Title", "detail")` | RFC 9457 `application/problem+json` |

If an action does not respond, Silth sends `204 No Content`.

Downloads keep any file name: `send_data(pdf, "facture-été.pdf", "application/pdf")` writes an ASCII fallback and the exact UTF-8 name (`filename*`, RFC 6266). Both `send_data` and `send_file` take `headers:` for anything else (`headers: {"Cache-Control" => "no-store"}`).

## Layouts

The layout is `layouts/application` unless a `LAYOUT` constant says otherwise (`LAYOUT = "layouts/admin"` or `LAYOUT = false`). Override per call with `render "x", layout: false`.

## Rescuing errors

```crystal
rescue_from Stripe::Error, with: :payment_failed

private def payment_failed(ex)
  redirect "/billing", alert: ex.message
end
```

Unhandled `Silth::HTTPError`s map to their status (`NotFound` → 404, `Forbidden` → 403, `UnprocessableEntity` → 422…).
