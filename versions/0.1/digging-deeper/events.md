---
title: Events
description: Typed events, closures and class-based listeners.
---
# Events

```crystal
class OrderShipped < Silth::Event
  getter order_id : Int64
  def initialize(@order_id); end
end

Silth::Events.listen(OrderShipped) { |e| Log.info { "Order #{e.order_id} shipped" } }

class NotifyCustomer < Silth::Listener(OrderShipped)
  queued                                   # handled in the background
  def handle(event : OrderShipped) : Nil
    ShippedMail.new(event.order_id).deliver
  end
end

Silth::Events.dispatch(OrderShipped.new(order.id))
Silth::Events.dispatch_after_commit(OrderShipped.new(order.id))   # after the DB transaction
Silth::Events.listen_all { |e| Audit.record(e) }                   # wildcard
```

Class listeners are registered automatically at boot. In tests: `Silth::Events.fake` then `Silth::Events.dispatched?(OrderShipped)`.
