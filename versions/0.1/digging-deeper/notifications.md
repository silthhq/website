---
title: Notifications
description: Mail, database, broadcast and webhook notifications.
---
# Notifications

```crystal
class InvoicePaid < Silth::Notification
  def initialize(@invoice : Invoice); end

  def via(notifiable) : Array(Symbol)
    [:mail, :database, :broadcast, :webhook]
  end

  def to_mail(notifiable) : Silth::Mail?
    InvoicePaidMail.new(@invoice)
  end

  def to_data(notifiable) : Hash(String, String)
    {"invoice" => @invoice.number, "amount" => @invoice.total.to_s}
  end

  def to_webhook(notifiable) : {String, String}?
    {ENV["SLACK_WEBHOOK"], {text: "Invoice #{@invoice.number} paid"}.to_json}
  end
end

user.notify(InvoicePaid.new(invoice))         # User includes Silth::Notifiable
user.notify_later(InvoicePaid.new(invoice))
user.unread_notifications.each(&.mark_as_read)
```

- **database** stores rows in `silth_notifications` (`silth g notifications` creates the migration).
- **broadcast** pushes to the WebSocket topic `notifications:user:<id>` (see [WebSockets](/docs/digging-deeper/websockets)).
- **webhook** posts JSON to Slack, Discord, Teams…

Tests: `Silth::Notifications.fake` and `Silth::Notifications.sent?(InvoicePaid)`.
