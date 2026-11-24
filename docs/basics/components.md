---
title: Components
description: Reusable view components with typed props and slots.
---
# Components

Inspired by Symfony UX TwigComponent: a class with typed props plus a template.

```crystal
class AlertComponent < Silth::Component
  prop message : String                # required
  prop variant : String = "info"       # default
  prop dismissible : Bool = false
  template "components/alert"          # src/views/components/alert.html.ecr

  def icon : String
    variant == "error" ? "✖" : "●"
  end
end
```

```erb
<div class="alert alert-<%= variant %>"><%= icon %> <%= message %></div>
```

Render it:

```erb
<%= component AlertComponent, message: "Saved!", variant: "success" %>
```

Props are checked at compile time: an unknown prop is a compile error.

## Slots

```crystal
class CardComponent < Silth::Component
  prop title : String
  template "components/card"
end
```

```erb
<!-- components/card.html.ecr -->
<section class="card"><h2><%= title %></h2><%= yield_slot %></section>
```

```erb
<% component CardComponent, title: "Stats" do %>
  <p>Any template content goes here.</p>
<% end %>
```

## Hooks

Override `before_render` to compute derived state just before rendering. Generate a component with `silth g component Alert message:string`.
