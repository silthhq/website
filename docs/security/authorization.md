---
title: Authorization
description: Policies, gates and the before hook.
---
# Authorization

## Policies

One class per model, one predicate per ability. The argument types decide which policy applies.

```crystal
class PostPolicy < Silth::Policy
  # Admins bypass every check (Symfony voter style).
  def before(user, ability) : Bool?
    true if user.as?(User).try(&.admin?)
  end

  def view?(user : User?, post : Post) : Bool          # nilable user: guests allowed
    post.published? || post.user_id == user.try(&.id)
  end

  def update?(user : User, post : Post) : Bool
    post.user_id == user.id
  end
end
```

```crystal
authorize! :update, post        # controllers: raises Forbidden (403)
can?(:update, post)             # controllers and views
```

```erb
<% if can?(:update, post) %><%= link_to "Edit", route("posts.edit", id: post.id) %><% end %>
```

Policy dispatch is generated at compile time — no reflection at runtime.

## Gates

For abilities without a record:

```crystal
Silth::Gate.define("view-admin") { |user| user.as?(User).try(&.admin?) || false }
authorize! "view-admin"
```

Gates also guard [workflow](/docs/digging-deeper/workflows) transitions.
