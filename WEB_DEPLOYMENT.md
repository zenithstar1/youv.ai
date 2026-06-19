# Flutter Web deployment — cache & update strategy

## What caused stale builds

1. **`flutter_service_worker.js` (default PWA strategy)**  
   Flutter registered a service worker that cached `index.html`, `flutter_bootstrap.js`, `main.dart.js`, and assets. Returning visitors often kept the **old service worker** and **old cache** until a manual hard refresh.

2. **Browser / CDN caching of shell files**  
   `index.html` and `flutter_bootstrap.js` were requested without cache-busting. Hosts that cache HTML/JS aggressively served outdated entrypoints even after a new deploy.

3. **`version.json` alone is not enough**  
   It only changes when `pubspec.yaml` version changes, not on every compile.

## What we implemented

| Layer | Fix |
|--------|-----|
| Build | `flutter build web --pwa-strategy=none` — **no new service worker** |
| `web/js/app_update.js` | Unregisters legacy SW, clears Flutter caches, compares `build_id.json`, auto-reloads on new deploy |
| `build_id.json` | Written post-build from `.last_build_id` (unique every build) |
| `index.html` | No-cache meta tags; loads Flutter via `app_update.js` with `?v=<build_id>` on bootstrap |
| `web/.htaccess` | Apache: no-cache for shell files |
| `web/_headers` | Netlify/compatible hosts: no-cache for shell files |

## Build for production

**Windows (recommended):**

```powershell
.\tool\build_web.ps1
```

**macOS / Linux:**

```bash
chmod +x tool/build_web.sh
./tool/build_web.sh
```

Deploy the **entire** `build/web/` folder (must include `build_id.json`, `js/app_update.js`, `.htaccess` or `_headers`).

Do **not** use plain `flutter build web` for production unless you also run the post-build step that writes `build_id.json`.

## Hosting notes

### Apache
`web/.htaccess` is copied into `build/web/.htaccess` automatically. Ensure `AllowOverride` allows headers.

### Nginx (example)

```nginx
location ~* ^/(index\.html|flutter_bootstrap\.js|flutter_service_worker\.js|build_id\.json|version\.json|main\.dart\.js|face_detector\.js)$ {
    add_header Cache-Control "no-cache, no-store, must-revalidate";
    add_header Pragma "no-cache";
    add_header Expires "0";
}
```

### IIS / generic CDN
Set **no-cache** (or very short TTL) for the files listed above. Long-cache only files that include content hashes in the URL (not `main.dart.js`).

## Verification after deploy

1. Open the site in a normal tab (not incognito).
2. Deploy a new build with `.\tool\build_web.ps1`.
3. Reload the page — users should get the new build without Ctrl+Shift+R.
4. In DevTools → Application → Service Workers: should be **empty** (or only briefly during migration).
5. Network tab: `build_id.json` and `flutter_bootstrap.js` should show `cache: no-store` or 200 (not from disk cache).

## Files modified / added

- `web/index.html` — cache meta, `app_update.js` bootstrap
- `web/js/app_update.js` — version detection & SW cleanup
- `web/.htaccess` — Apache cache headers
- `web/_headers` — static host cache headers
- `tool/build_web.ps1` — production build script
- `tool/build_web.sh` — production build script (Unix)
