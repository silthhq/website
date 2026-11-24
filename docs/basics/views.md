---
title: Views & templates
description: ECR templates with auto-escaping, layouts, partials, helpers and forms.
---
# Views & templates

Templates live in `src/views` with the `.html.ecr` extension and are **compiled into the binary**.

| Tag | Meaning |
|---|---|
| `<%= expr %>` | output, **HTML escaped** |
| `<%== expr %>` | raw output |
| `<% code %>` | control flow |
| `<%# comment %>` | removed |
| `<%-`, `-%>` | trim whitespace |

Values of type `Silth::SafeHTML` (returned by helpers) are never escaped twice.

```erb
<h1><%= post.title %></h1>
<% if post.body? %><%= simple_format(post.body?) %><% end %>
<% posts.each do |post| %>
  <%= partial "posts/_card", post: post %>
<% end %>
```

## Layouts and sections

```erb
<!-- src/views/layouts/application.html.ecr -->
<title><%= yield_content(:title, "My app") %></title>
<main><%= content %></main>
```

```erb
<% content_for :title, "Posts" %>
<% content_for :sidebar do %><nav>…</nav><% end %>
```

## Forms

Helpers that take a block are used with control tags (`<% … do %>`):

```erb
<% form_with url: route("posts.create"), model: post, class: "form" do |f| %>
  <%= f.label :title %>
  <%= f.text_field :title, required: true %>
  <%= f.errors_for :title %>
  <%= f.select :status, [{"Draft", "draft"}, {"Published", "published"}] %>
  <%= f.check_box :published %>
  <%= f.submit "Save" %>
<% end %>
```

`form_with` adds the CSRF token and the `_method` field for `patch`/`delete`.

## Helpers

`link_to`, `button_to` (any HTTP method, optional `confirm:`), `route`, `asset_path`, `stylesheet_tag`, `script_tag`, `importmap_tags`, `image_tag`, `csrf_meta_tags`, `t`, `l`, `time_ago_in_words`, `pluralize`, `truncate`, `number_to_currency`, `number_to_human_size`, `markdown`, `paginate`, `flash_messages`, `class_names`, `active_class`, `tag`, `raw`, `debug`.

Add your own by reopening `Silth::View::Helpers` or defining methods on your controllers.
