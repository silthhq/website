---
title: Billing (Stripe)
description: Subscriptions, checkout, customer portal and webhooks.
---
# Billing (Stripe)

A Laravel Cashier equivalent.

```bash
silth g billing && silth db:migrate     # subscriptions table + stripe columns on users
```

```yaml
# config/billing.yml
stripe:
  secret: ${STRIPE_SECRET}
  webhook_secret: ${STRIPE_WEBHOOK_SECRET}
```

```crystal
class User < ApplicationModel
  include Silth::Auth::Authenticatable
  include Silth::Billing::Billable
  # …
end
```

## Subscribing

```crystal
url = current_user.checkout("price_pro_monthly",
  success_url: "#{ctx.base_url}/billing/thanks", cancel_url: "#{ctx.base_url}/pricing", trial_days: 14)
redirect url

current_user.subscribed?                        # active, trialing, past due or grace period
current_user.subscribed?("default", price: "price_pro_monthly")
current_user.on_trial?
redirect current_user.billing_portal_url(return_url: "#{ctx.base_url}/account")
```

## Managing subscriptions

```crystal
sub = current_user.subscription.not_nil!
sub.swap("price_pro_yearly")
sub.update_quantity(5)
sub.cancel          # at period end (grace period)
sub.resume
sub.cancel_now
```

One-off payments: `charge(amount_in_cents, payment_method)`, `refund(payment_intent)`, `invoices`, `payment_methods`, `update_default_payment_method(pm)`.

## Webhooks

`POST /stripe/webhook` verifies the `Stripe-Signature` header and keeps the `subscriptions` table in sync. Listen to `Silth::Billing::WebhookReceived` for anything else:

```crystal
Silth::Events.listen(Silth::Billing::WebhookReceived) do |e|
  InvoiceMail.new(e.payload).deliver if e.type == "invoice.paid"
end
```
