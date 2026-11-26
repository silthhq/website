---
title: UI components
description: Accessible dialog, dropdown menu, tabs and toasts shipped with every new app, unstyled by default.
---
# UI components

```erb
<% component UI::Dialog, id: "delete-post", title: "Delete this post?", trigger: "Delete…" do |d| %>
  <p>It will be gone for good, comments included.</p>
  <% d.slot :actions do %>
    <button type="button" class="btn" data-ui-close>Cancel</button>
    <%= button_to "Delete", route("posts.destroy", id: post.id), method: "delete", class: "btn btn-danger" %>
  <% end %>
<% end %>
```

New apps ship four components in `src/components/ui`, built for keyboard and screen reader users from the start. They are **your code**: the Crystal classes, the templates in `src/views/components/ui`, the behavior in `assets/js/ui.js` and the looks in `assets/ui.css`. Change them, or delete what you do not use.

- **Unstyled by default.** The markup carries no class, only ARIA and `data-ui` hooks. `assets/ui.css` styles those hooks with the app's design tokens; remove it (and its `<link>` in the layout) to start from bare markup.
- **Accessible.** They follow the [WAI-ARIA Authoring Practices](https://www.w3.org/WAI/ARIA/apg/) for focus and keys, and their previews pass an axe-core audit.
- **Live-component friendly.** They work in any template and inside live components: morphing keeps what the browser owns (`silth-keep`), a live action can open a dialog or show a toast.

Every component has previews at `/_silth/profiler/components`, where you can try the keyboard behavior.

## Dialog

A modal dialog on the native `<dialog>` element: focus moves into it and stays there, the page behind is inert, Escape or a click on the backdrop closes it, focus returns to the button that opened it.

| Prop | Default | |
|---|---|---|
| `id` | required | the dialog's id; `<button data-ui-dialog="id">` anywhere opens it |
| `title` | required | its heading, which names the dialog (`aria-labelledby`) |
| `trigger` | `nil` | label of a button rendered before the dialog to open it |
| `open` | `false` | rendered open: a live component opens and closes it from the server |
| `close_action` | `nil` | live action called when the user closes it, to keep the server state in sync |
| `close_label` | `"Close"` | accessible name of the × button |

The block is the body; the `actions` slot is the footer. Any element with `data-ui-close` inside closes it. From JavaScript: `ui.openDialog("delete-post")`, `ui.closeDialog(…)`.

In a live component:

```crystal
class PostRow < Silth::LiveComponent
  prop confirming : Bool = false
  action def ask; @confirming = true; end
  action def cancel; @confirming = false; end
end
```

```erb
<button silth-click="ask">Delete</button>
<% component UI::Dialog, id: "confirm-#{post.id}", title: "Delete it?", open: confirming, close_action: "cancel" do |d| %>…<% end %>
```

## Dropdown menu

A menu button: Enter, Space or ↓ opens the menu on its first item, ↑ on its last; ↑ ↓ Home End move between items, typing a letter jumps to the next item starting with it, Escape closes it and gives focus back to the button, Tab or a click outside closes it.

```erb
<% component UI::Dropdown, label: "Options", align: "end" do |menu| %>
  <% menu.item "Edit", href: route("posts.edit", id: post.id) %>
  <% menu.item "Archive", action: "archive" %>
  <% menu.item "Delete", href: route("posts.destroy", id: post.id), method: "delete", confirm: "Delete it?" %>
<% end %>
```

`item` takes a link (`href`, with `method:` for a DELETE or PATCH link and `confirm:`) or a live action (`action:`, called on the enclosing live component). `align: "end"` lines the menu up with the right edge of the button.

## Tabs

Tabs with one tab in the Tab order: ← → move between tabs and show their panel, Home and End jump to the first and last, Tab goes to the panel.

```erb
<% component UI::Tabs, label: "Account", selected: "security" do |tabs| %>
  <% tabs.tab "profile", "Profile" do %>…<% end %>
  <% tabs.tab "security", "Security" do %>…<% end %>
<% end %>
```

`label` names the tab list for screen readers. Every panel is rendered; switching tabs happens in the browser, without a request. A `ui:tab` event bubbles from the tab selected, if you want to save the choice.

## Toasts

Put the toaster once in the layout (new apps have it):

```erb
<%= component UI::Toaster %>
```

Then show toasts from a live action, JavaScript or the server:

```crystal
emit "toast", {message: "Post published", variant: "success"}
```

```js
import { ui } from "ui";
ui.toast("Link copied", { variant: "success", duration: 3000 });
```

```erb
<% component UI::Toaster do %><%= component UI::Toast, message: "Welcome back" %><% end %>
```

Toasts live in a polite live region (an assertive one for `variant: "error"`), so screen readers announce them. They disappear after `duration` milliseconds (5000), pause while hovered or focused, and have a dismiss button; errors stay until dismissed.
