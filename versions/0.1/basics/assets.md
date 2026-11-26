---
title: Assets
description: CSS and JavaScript without a build step, fingerprinting and import maps.
---
# Assets

Silth embraces the platform: native CSS (nesting, custom properties, layers) and ES modules with import maps. No Node.js required.

- **Development**: files under `assets/` are served from `/assets/*` as-is, with live reload (CSS is hot-swapped).
- **Production**: `silth assets:build` copies them to `public/assets/` with content fingerprints (`app-3f2a9c1d.css`), gzip variants, CSS `url()` rewriting and a `manifest.json`. Fingerprinted files are served with `Cache-Control: immutable`.

```erb
<%= stylesheet_tag "app.css" %>
<%= image_tag "logo.svg", alt: "Logo" %>
<%= importmap_tags %>       <!-- import map + modulepreload + import "app" -->
<%= silth_scripts %>        <!-- live components, channels, live reload -->
```

## Import maps

```yaml
# config/importmap.yml
imports:
  app: js/app.js
  charts: https://cdn.example.com/charts@4.2.0/dist/charts.mjs
  silth: /_silth/silth.js
```

```js
// assets/js/app.js
import { silth } from "silth";
const chat = silth.socket().channel("chat:lobby");
```

## The client runtime

`/_silth/silth.js` (≈ 12 KB) powers live components, channels, `data-method`/`data-confirm` links and auto-dismissed flashes (`data-dismiss="4000"`).
