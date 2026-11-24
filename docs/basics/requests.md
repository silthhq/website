---
title: Requests & validation
description: Params, uploads, cookies, sessions, flash and form requests.
---
# Requests & validation

`ctx` (also delegated in controllers) wraps the request.

## Params

Route params, query string, form bodies (urlencoded and multipart) and JSON bodies are merged into `params`.

```crystal
params["id"]                 # String, 400 Bad Request when missing
params["q"]?                 # String?
params.int("page", 1)
params.bool("remember")
params.nested("post")        # {"title" => "…"} from post[title]=…
params.permit(:title, :body, from: :post)   # strong parameters → Hash(String, String)
params.file("avatar")        # Silth::UploadedFile?
params.json                  # JSON::Any for JSON bodies
```

## Form requests

Typed, validated input objects — perfect for APIs (and documented automatically in OpenAPI).

```crystal
class CreatePostRequest < Silth::FormRequest
  field title : String, min: 3, max: 120
  field body : String?
  field email : String, email: true
  field rating : Int32, min: 1, max: 5
  field status : String, in: ["draft", "published"]
  field password : String, min: 8, confirmed: true

  def validate : Nil
    errors.add("title", "must not shout") if title == title.upcase
  end
end

data = validate!(CreatePostRequest)   # raises 422 with {"errors": {...}}
data.title
```

## Request helpers

`ctx.method`, `ctx.path`, `ctx.host`, `ctx.url`, `ctx.remote_ip`, `ctx.user_agent`, `ctx.wants_json?`, `ctx.xhr?`, `ctx.header("X-Thing")`.

## Sessions & flash

```crystal
session["cart_id"] = cart.id.to_s
session.pull("_intended")
session.regenerate            # after login
flash["notice"] = "Saved"     # next request
flash.now["alert"] = "Oops"   # this render
```

Sessions are stored in an encrypted cookie by default (`config/session.yml`, `driver: cache` for server-side storage).

## Cookies

```crystal
ctx.set_cookie("theme", "dark", max_age: 365.days)
ctx.set_signed_cookie("ref", code)        # tamper-proof
ctx.set_encrypted_cookie("token", secret) # confidential
ctx.signed_cookie("ref")
```
