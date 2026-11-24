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
