---
title: API documentation
description: OpenAPI 3.1 generated from routes and Crystal types.
---
# API documentation

Routes in the `api` group are documented automatically at **`/docs/api`** (an interactive reference with "try it") and **`/docs/api/openapi.json`**.

Add details with the `@[Silth::API]` annotation — request and response schemas are **generated from your Crystal types** (models, form requests, `JSON::Serializable` structs, pages):

```crystal
class Api::PostsController < ApiController
  @[Silth::API(summary: "List posts", tags: ["Posts"], response: Silth::DB::Page(Post))]
  def index
    json Post.latest.paginate(params.int("page", 1))
  end

  @[Silth::API(summary: "Create a post", tags: ["Posts"], body: CreatePostRequest, response: Post, status: 201)]
  def create
    data = validate!(CreatePostRequest)
    json Post.create!(title: data.title, body: data.body), 201
  end
end
```

Form request constraints (`min`, `max`, `email`, `url`) become JSON Schema keywords. Protected routes declare bearer security; validation and rate limiting responses reference RFC 9457 problem details.

```yaml
# config/api_docs.yml
enabled: true
path: /docs/api
title: Blog API
version: 1.2.0
```

Export the spec for client generation: `silth api:docs -o public/openapi.json`.
