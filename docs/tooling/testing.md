---
title: Testing
description: HTTP tests, transactions, fakes and browser tests.
---
# Testing

```crystal
# spec/spec_helper.cr
ENV["SILTH_ENV"] = "test"
require "spec"
require "silth/testing"
require "../src/app"
require "../db/migrations/**"
require "./factories/**"
Silth::Testing.setup        # boot, migrate, wrap each example in a rolled back transaction
```

## HTTP tests

Requests run **in process** (no socket) and keep cookies between calls.

```crystal
describe PostsController do
  it "creates a post" do
    user = UserFactory.create
    client.acting_as(user)
    response = client.post("/posts", form: {"post[title]" => "Hello"})
    response.should be_redirect
    client.follow(response).should contain("Hello")
  end

  it "serves JSON" do
    response = client.with_token(token).get_json("/api/posts")
    response.should be_ok
    response.json["data"].as_a.size.should eq(1)
    client.post("/api/posts", json: {title: ""}).should be_unprocessable
  end
end
```

Matchers: `be_ok`, `be_redirect`, `redirect_to(path)`, `have_status(201)`, `be_not_found`, `be_forbidden`, `be_unauthorized`, `be_unprocessable`, `contain(text)`. CSRF checks are disabled in tests (enable with `security.csrf_in_tests: true`).

## Fakes

```crystal
Silth::Mailer.sent                         # always captured in tests
Silth::Queue.fake;          Silth::Queue.pushed?(SendJob)
Silth::Events.fake;         Silth::Events.dispatched?(OrderShipped)
Silth::Notifications.fake;  Silth::Notifications.sent?(InvoicePaid)
disk = Silth::Storage.fake
Silth::HTTPClient.fake({"api.stripe.com/*" => {200, "{}"}})
```

## Browser tests

Drive Chrome or Firefox through WebDriver (`chromedriver --port=9515`):

```crystal
Silth::Testing::Browser.session do |b|
  b.visit("/login")
   .fill("#email", "ada@example.com")
   .fill("#password", "password")
   .click("button[type=submit]")
  b.wait_for(".flash")
  b.should_see("Welcome back")
  b.screenshot("tmp/login.png")
end
```

The app is served on a local port during the session. Browser tests are not wrapped in transactions — clean up explicitly.
