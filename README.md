# obx-search

Static frontend for [search.obx.deals](https://search.obx.deals) — OBX vacation rental search powered by the rental-intel Lambda API.

Hosted on GitHub Pages (CNAME: search.obx.deals). Deployed automatically on push to `main`.

## Architecture

- `index.html` — main search (Alpine.js + MapLibre + Flatpickr)
- `quick-getaways/index.html` — static browse page, regenerated nightly by `generate_quick_getaways_page.py`
- API: `https://search-api.obx.deals` (Lambda container, rebuilt nightly with fresh `search.db`)
- Tracking: `https://track.obx.deals/c` (click tracker Lambda, DynamoDB `obx_deals_clicks`)

## Developer notes

### Search tracking self-exclusion

All searches and clicks from this browser are **excluded from analytics** by a localStorage flag:

```
localStorage.setItem('obx_internal', '1')
```

**This has already been set on the owner's primary browser.** Searches performed there (including FB group answer tests) will not appear in `obx_deals_clicks`.

To verify tracking is working, or to test the guest experience cold, use an **incognito window** — incognito has no localStorage, so beacons fire normally.

To re-enable tracking on a browser where it was suppressed:
```
localStorage.removeItem('obx_internal')
```

To check the current state:
```
localStorage.getItem('obx_internal')  // '1' = excluded, null = tracked
```

### Staging environment

Append `?env=staging` to use the staging Lambda instead of production:
```
https://search.obx.deals/?env=staging
```

### Visitor identity

A UUID cookie (`obxd_vid`) is set on first visit, shared across `.obx.deals` subdomains (`max-age=1yr`). This is the `visitor_id` on all beacon events. The same cookie is used by obx.deals and owners.obx.deals for cross-site visitor correlation.
</content>
</invoke>