---
title: Mail
description: Mail classes, templates and transports (SMTP built in).
---
# Mail

```crystal
class InvoiceMail < Silth::Mail
  def initialize(@invoice : Invoice); end

  def build : Nil
    to @invoice.customer_email, @invoice.customer_name
    bcc "accounting@example.com"
    subject "Invoice ##{@invoice.number}"
    html render_to_string("mails/invoice", layout: "layouts/mail", invoice: @invoice)
    text "Your invoice is attached."            # optional, generated from HTML otherwise
    attach_data @invoice.pdf, "invoice.pdf", "application/pdf"
  end
end

InvoiceMail.new(invoice).deliver
InvoiceMail.new(invoice).deliver_later
```

## Markdown mails

Write the content in Markdown; Silth renders a themed, responsive HTML body with inline styles (mail clients ignore `<style>`) and the plain text version.

```crystal
class OrderShippedMail < Silth::Mail
  def initialize(@order : Order)
  end

  def build : Nil
    to @order.email
    subject "Your order is on its way"
    markdown "mails/order_shipped", order: @order, url: "https://shop.example/orders/#{@order.id}"
  end
end
```

```erb
<!-- src/views/mails/order_shipped.md.ecr -->
# Good news, <%= order.name %>!

Order **#<%= order.id %>** left our warehouse.

<%= button "Track the parcel", url %>

<%= panel "Delivery expected within 3 days." %>

| Item | Qty |
|---|---|
<% order.lines.each do |line| %>| <%= line.title %> | <%= line.quantity %> |
<% end %>
```

`<%= %>` values are shown as typed (`<`, `&`… are escaped once, never interpreted as Markdown HTML). `button(label, url)` and `panel(text)` go on their own line. In the text version links read `label (url)`. Theme settings in `config/mail.yml`: `markdown.color` (buttons and links), `markdown.footer` (default `© <year> <app.name>`).

`silth g mail OrderShipped` writes a Markdown mail, its template and a preview.

## Previews

```crystal
# src/mails/previews/order_shipped_mail_preview.cr
class OrderShippedMailPreview < Silth::MailPreview
  def order_shipped : Silth::Mail
    OrderShippedMail.new(Order.last? || OrderFactory.build)
  end

  def order_shipped_abroad : Silth::Mail
    OrderShippedMail.new(OrderFactory.build(country: "JP"))
  end
end
```

Every public method of a `Silth::MailPreview` is listed in the profiler's *Mails* tab (`/_silth/profiler/mails`): headers, attachments, the HTML body in a sandboxed frame, the text body and a `.eml` download. Previews are built on demand and never sent. Mails captured by the memory transport and `.eml` files of the file transport open the same way.

## Transports

```yaml
# config/mail.yml
driver: smtp            # memory | log | file | smtp
from: { address: hello@example.com, name: Example }
host: smtp.example.com
port: 587
username: ${MAIL_USERNAME}
password: ${MAIL_PASSWORD}
encryption: starttls    # starttls | tls | none
```

The SMTP client (STARTTLS, implicit TLS, AUTH PLAIN/LOGIN) is built in. In development the `file` transport writes `.eml` files into `tmp/mails` (listed in the profiler's *Mails* tab). In tests, `Silth::Mailer.sent` holds delivered messages.
