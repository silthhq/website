---
title: Live components
description: Stateful server-rendered components updated over WebSocket.
---
# Live components

Live components keep their state on the server and update the page over a WebSocket (with an HTTP fallback). No JavaScript to write — inspired by Symfony UX Live Components and Phoenix LiveView.

```crystal
class TodoListComponent < Silth::LiveComponent
  prop items : Array(String) = [] of String
  prop draft : String = "", writable: true    # writable props accept browser input
  template "components/todo_list"

  action def add
    return if draft.strip.empty?
    @items = items + [draft.strip]
    @draft = ""
    emit "toast", {message: "Added"}          # browser event `silth:toast`
  end

  action def remove(index : Int32)            # typed action arguments
    @items = items.dup.tap { |list| list.delete_at(index) if index < list.size }
  end
end
```

```erb
<div>
  <form silth-submit="add">
    <input name="draft" silth-model="draft" value="<%= draft %>">
    <button>Add</button>
  </form>
  <ul>
    <% items.each_with_index do |item, i| %>
      <li data-key="<%= i %>"><%= item %> <button silth-click="remove" silth-args="<%= i %>">×</button></li>
    <% end %>
  </ul>
</div>
```

Embed with `<%= live TodoListComponent %>` or mount as a page with `live "/todos", TodoListComponent` in routes. The layout must include `<%= silth_scripts %>`.

## Directives

| Attribute | Effect |
|---|---|
| `silth-click="action"` | call an action (`silth-args='[1, "x"]'` for arguments) |
| `silth-submit="action"` | submit a form; fields update writable props first |
| `silth-model="prop"` | two-way binding (`.lazy` on change, `.debounce.300ms`); on `<input type="file">` it uploads the files |
| `silth-change="action"` | call with the input value |
| `silth-keydown.enter="action"` | on Enter |
| `silth-poll="5s"` | re-render periodically |
| `silth-confirm="Sure?"` | confirmation dialog |
| `silth-loading` | element shown while a call is pending |
| `silth-ignore` | never morphed |
| `data-key` | stable identity for list items |

## File uploads

```crystal
class AvatarForm < Silth::LiveComponent
  prop avatar : Silth::Live::Upload?, writable: true
  prop photos : Array(Silth::Live::Upload) = [] of Silth::Live::Upload, writable: true

  action def save
    if file = avatar
      user.not_nil!.update!(avatar_path: file.store("avatars"))   # moves it to the storage disk
      @avatar = nil
    end
  end
end
```

```erb
<input type="file" accept="image/*" silth-model="avatar">
<input type="file" multiple silth-model="photos">
<% if (file = avatar) && file.image? %><img src="<%= file.preview_url %>" alt="<%= file.filename %>"><% end %>
```

Choosing a file uploads it to a temporary directory (`POST /_silth/live/upload`, one request per file), then the component receives a `Silth::Live::Upload`: `filename`, `content_type`, `size`, `image?`, `read`, `preview_url`, `store(directory, disk, name)`, `delete`. The component state only carries a signed token, never the bytes. While uploading, the input has `data-silth-progress` (0-100) and dispatches `silth:upload-progress` / `silth:upload-error` events.

| Setting (`config/app.yml`) | Default | |
|---|---|---|
| `live.upload_max_size` | `10485760` | bytes per file (larger: `413`) |
| `live.upload_dir` | `tmp/live_uploads` | temporary files |
| `live.upload_max_age` | `86400` | seconds before temporary files and tokens expire |

## Nested live components

A live template can embed other live components. Give each one a `key` unique among its siblings: its id derives from the parent's id and the key, so it survives the parent's re-renders.

```erb
<% todos.each do |todo| %>
  <%= live TodoItem, key: todo.id, todo_id: todo.id, title: todo.title %>
<% end %>
```

A child handles its own actions and keeps its state while the parent re-renders with the same props; when the parent passes different props, the child is re-rendered from them. A child talks back with `notify_parent("action", *args)`, which calls that action on the enclosing live component once the child's response is applied.

## How it works

1. The initial HTML contains the component's props signed with the app key (`data-silth-state`).
2. An interaction sends `{component, state, action, args, model updates}`.
3. The server verifies the signature, rebuilds the component, applies writable updates, runs the action, re-renders and returns HTML + new state.
4. The client **morphs** the DOM (focus, inputs and scroll are preserved).

Only `writable: true` props can be changed by the browser; any tampering with the state is rejected (`403`).

## Server push

```crystal
def subscriptions : Array(String)
  ["orders"]
end
```

`Silth::Live.refresh("orders")` re-renders every connected component subscribed to `orders` (e.g. from a job or a listener).

## Hooks

`mount` (first render), `updated(prop)` (after a browser update), `before_render`. Access the user with `user`.
