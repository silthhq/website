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

## Previews

```crystal
# src/components/previews/alert_component_preview.cr
class AlertComponentPreview < Silth::ComponentPreview
  description "Inline messages, one per variant."

  def info : Silth::Component
    AlertComponent.new(message: "Saved.", variant: "info")
  end

  def in_a_card : Silth::Component
    CardComponent.new(title: "Stats").with_slots(content: "<p>42 visits</p>", footer: %(<a href="/stats">All stats</a>))
  end
end
```

Every public method without arguments is a scenario returning the component to show. They are listed in the profiler at **`/_silth/profiler/components`**, the catalogue of your UI kit. Each scenario page shows:

- the component in a frame with the app's stylesheets and scripts (live components work there), at full width, 1024, 768 or 375 px;
- its props, with their type and default; `String`, numbers and `Bool` can be changed on the page;
- the slots the scenario fills, the template code that renders it, and its HTML.

`with_slots(content:, **named)` fills slots with HTML from code (`fill_slot(:name, html)` for one). A component filled through methods of its own can override `preview_usage` to show the right snippet. `silth g component` and `silth g live` write a preview next to the component; the frame loads every stylesheet at the root of `assets/` (`previews.stylesheets` in the config to choose).

## Hooks

Override `before_render` to compute derived state just before rendering. Generate a component with `silth g component Alert message:string`.
