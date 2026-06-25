/**
 * Flutter Web deployment update guard.
 *
 * - Removes legacy flutter service workers and caches (migration from older builds).
 * - Compares build_id.json on each load and while the app is open.
 * - Reloads automatically when a new deployment is detected.
 * - Loads flutter_bootstrap.js with a build-specific cache-busting query param.
 */
(function () {
  'use strict';

  var STORAGE_KEY = 'youv_app_build_id';
  var POLL_INTERVAL_MS = 5 * 60 * 1000;
  var reloadScheduled = false;

  function log() {
    if (typeof console !== 'undefined' && console.debug) {
      console.debug.apply(console, ['[AppUpdate]'].concat([].slice.call(arguments)));
    }
  }

  function loadScript(src) {
    return new Promise(function (resolve, reject) {
      var script = document.createElement('script');
      script.src = src;
      script.async = false;
      script.onload = resolve;
      script.onerror = function () {
        reject(new Error('Failed to load script: ' + src));
      };
      document.body.appendChild(script);
    });
  }

  async function clearFlutterCaches() {
    if (!window.caches) return;
    var keys = await caches.keys();
    await Promise.all(
      keys
        .filter(function (key) {
          return key.indexOf('flutter-app') !== -1 || key.indexOf('flutter-temp') !== -1;
        })
        .map(function (key) {
          return caches.delete(key);
        }),
    );
  }

  async function unregisterServiceWorkers() {
    if (!('serviceWorker' in navigator)) return;
    var registrations = await navigator.serviceWorker.getRegistrations();
    await Promise.all(
      registrations.map(function (registration) {
        return registration.unregister();
      }),
    );
  }

  async function fetchBuildId() {
    try {
      var buildResponse = await fetch('build_id.json', { cache: 'no-store' });
      if (buildResponse.ok) {
        var buildJson = await buildResponse.json();
        if (buildJson && buildJson.build_id) {
          return String(buildJson.build_id);
        }
      }
    } catch (error) {
      log('build_id.json unavailable', error);
    }

    try {
      var versionResponse = await fetch('version.json', { cache: 'no-store' });
      if (versionResponse.ok) {
        var versionJson = await versionResponse.json();
        return [
          versionJson.app_name || 'app',
          versionJson.version || '0',
          versionJson.build_number || '0',
        ].join(':');
      }
    } catch (error) {
      log('version.json unavailable', error);
    }

    return null;
  }

  function scheduleReload(reason) {
    if (reloadScheduled) return;
    reloadScheduled = true;
    log('Reloading for new deployment:', reason);
    window.location.reload();
  }

  async function ensureLatestBuild(buildId, options) {
    var forceReload = options && options.forceReload;
    var storedBuildId = null;
    try {
      storedBuildId = window.localStorage.getItem(STORAGE_KEY);
    } catch (_) {}

    if (buildId && storedBuildId && storedBuildId !== buildId) {
      await unregisterServiceWorkers();
      await clearFlutterCaches();
      try {
        window.localStorage.setItem(STORAGE_KEY, buildId);
      } catch (_) {}
      if (forceReload !== false) {
        scheduleReload('build_id_changed');
        return false;
      }
    }

    if (buildId) {
      try {
        window.localStorage.setItem(STORAGE_KEY, buildId);
      } catch (_) {}
    }

    return true;
  }

  async function checkForUpdates() {
    if (document.visibilityState === 'hidden') return;
    var latestBuildId = await fetchBuildId();
    if (!latestBuildId) return;

    var storedBuildId = null;
    try {
      storedBuildId = window.localStorage.getItem(STORAGE_KEY);
    } catch (_) {}

    if (storedBuildId && storedBuildId !== latestBuildId) {
      await unregisterServiceWorkers();
      await clearFlutterCaches();
      scheduleReload('poll_detected_new_build');
    }
  }

  async function bootstrapFlutter() {
    await unregisterServiceWorkers();
    await clearFlutterCaches();

    var buildId = await fetchBuildId();
    var canContinue = await ensureLatestBuild(buildId, { forceReload: true });
    if (!canContinue) return;

    var cacheBust = buildId || String(Date.now());
    window.__YOUV_BUILD_ID__ = cacheBust;

    if (!document.querySelector('script[data-youv-face-detector="true"]')) {
      await loadScript('face_detector.js?v=' + encodeURIComponent(cacheBust));
    }

    await loadScript('flutter_bootstrap.js?v=' + encodeURIComponent(cacheBust));

    window.setInterval(checkForUpdates, POLL_INTERVAL_MS);
    document.addEventListener('visibilitychange', function () {
      if (document.visibilityState === 'visible') {
        checkForUpdates();
      }
    });
  }

  bootstrapFlutter().catch(function (error) {
    console.error('[AppUpdate] bootstrap failed:', error);
    loadScript('flutter_bootstrap.js?v=' + Date.now());
  });
})();
