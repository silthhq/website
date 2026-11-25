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

### Named slots

Give the block a parameter to fill named slots; the rest of the block is the default slot:

```erb
<!-- components/card.html.ecr -->
<section class="card">
  <header><%= yield_slot :header %></header>
  <%= yield_slot %>
  <% if slot?(:footer) %><footer><%= yield_slot :footer %></footer><% end %>
</section>
```

```erb
<% component CardComponent, title: "Stats" do |card| %>
  <% card.slot :header do %><h2>Q4 <small>live</small></h2><% end %>
  <% card.slot :footer do %><a href="/stats">All stats</a><% end %>
  <p>Default slot content.</p>
<% end %>
```

The block runs before the component renders (so `slot?` knows every slot); slot blocks render where the component places them. Slots are for regular components: a live component re-renders on the server without its caller, so pass it props instead.

## Hooks

Override `before_render` to compute derived state just before rendering. Generate a component with `silth g component Alert message:string`.
