(function () {
  const tokenKey = 'demo_auth_token';
  const flutterBase = '/app/';
  let bootstrapPromise;

  function createDemoToken() {
    const email = document.getElementById('email').value || 'demo@example.com';
    return 'demo-token-for-' + email + '-' + Date.now();
  }

  function storeAuthToken() {
    const token = createDemoToken();
    window.localStorage.setItem(tokenKey, token);
    return token;
  }

  function preloadLink(href, as, type) {
    const link = document.createElement('link');
    link.rel = 'preload';
    link.href = href;
    link.as = as;
    link.fetchPriority = 'low';
    if (type) link.type = type;
    if (as === 'fetch') link.crossOrigin = 'anonymous';
    document.head.appendChild(link);
  }

  function preloadFlutterAssets() {
    preloadLink(flutterBase + 'flutter.js', 'script');
    preloadLink(flutterBase + 'flutter_bootstrap.js', 'script');
    preloadLink(flutterBase + 'main.dart.js', 'script');
    preloadLink(flutterBase + 'AssetManifest.json', 'fetch', 'application/json');

    fetch(flutterBase + 'AssetManifest.json', {
      mode: 'same-origin',
      credentials: 'same-origin',
      priority: 'low'
    }).catch(function () {});
  }

  function loadFlutterBootstrap() {
    if (window.preloadFlutterWeb) return Promise.resolve();
    if (bootstrapPromise) return bootstrapPromise;

    bootstrapPromise = new Promise(function (resolve, reject) {
      const script = document.createElement('script');
      script.src = flutterBase + 'flutter_bootstrap.js';
      script.async = true;
      script.onload = resolve;
      script.onerror = reject;
      document.head.appendChild(script);
    });

    return bootstrapPromise;
  }

  function warmFlutter() {
    loadFlutterBootstrap()
      .then(function () {
        return window.preloadFlutterWeb && window.preloadFlutterWeb();
      })
      .catch(function () {});
  }

  window.addEventListener('load', function () {
    preloadFlutterAssets();

    const idle = window.requestIdleCallback || function (cb) {
      return window.setTimeout(cb, 800);
    };

    idle(warmFlutter);
  });

  document.getElementById('hard-login').addEventListener('click', function () {
    storeAuthToken();
    window.location.assign('/app');
  });

  document.getElementById('spa-login').addEventListener('click', async function () {
    storeAuthToken();

    const host = document.getElementById('flutter-host');
    host.classList.add('active');
    host.innerHTML = '';

    await loadFlutterBootstrap();
    await window.mountFlutterWeb(host);
  });
})();
