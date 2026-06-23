import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';

import 'main.server.options.dart';

void main() {
  Jaspr.initializeApp(options: defaultServerOptions);

  runApp(
    Document(
      title: 'Hybrid Jaspr + Flutter',
      head: [
        meta(
          attributes: {
            'name': 'description',
            'content': 'Instant SSR landing page with background-preloaded Flutter web app.',
          },
        ),
        meta(
          attributes: {
            'name': 'viewport',
            'content': 'width=device-width, initial-scale=1',
          },
        ),
        link(
          rel: 'stylesheet',
          href: '/styles.css',
        ),

        // Low-priority preloads. They fetch but do not execute Flutter.
        link(
          rel: 'preload',
          href: '/app/flutter.js',
          attributes: {
            'as': 'script',
            'fetchpriority': 'low',
          },
        ),
        link(
          rel: 'preload',
          href: '/app/flutter_bootstrap.js',
          attributes: {
            'as': 'script',
            'fetchpriority': 'low',
          },
        ),
        link(
          rel: 'preload',
          href: '/app/main.dart.js',
          attributes: {
            'as': 'script',
            'fetchpriority': 'low',
          },
        ),
        link(
          rel: 'preload',
          href: '/app/AssetManifest.json',
          attributes: {
            'as': 'fetch',
            'type': 'application/json',
            'crossorigin': 'anonymous',
            'fetchpriority': 'low',
          },
        ),
        link(
          rel: 'preload',
          href: '/app/main.dart.wasm',
          attributes: {
            'as': 'fetch',
            'type': 'application/wasm',
            'crossorigin': 'anonymous',
            'fetchpriority': 'low',
          },
        ),
      ],
      body: const LandingPage(),
    ),
  );
}

class LandingPage extends StatelessComponent {
  const LandingPage({super.key});

  @override
  Component build(BuildContext context) {
    return div([
      main_([
        section(classes: 'hero', [
          div(classes: 'copy', [
            p(classes: 'eyebrow', [Component.text('SSR by Jaspr')]),
            h1([Component.text('Fast landing page, instant Flutter handoff')]),
            p(classes: 'lead', [
              Component.text(
                'This page is server-rendered HTML. Flutter is fetched in the background, then launched after login.',
              ),
            ]),
            div(classes: 'login', [
              label([
                Component.text('Email'),
                input(
                  id: 'email',
                  attributes: {
                    'type': 'email',
                    'value': 'demo@example.com',
                    'autocomplete': 'email',
                  },
                ),
              ]),
              label([
                Component.text('Password'),
                input(
                  id: 'password',
                  attributes: {
                    'type': 'password',
                    'value': 'password',
                    'autocomplete': 'current-password',
                  },
                ),
              ]),
              div(classes: 'actions', [
                button(
                  id: 'hard-login',
                  attributes: {'type': 'button'},
                  [Component.text('Login: hard navigate')],
                ),
                button(
                  id: 'spa-login',
                  attributes: {'type': 'button'},
                  [Component.text('Login: mount Flutter here')],
                ),
              ]),
            ]),
          ]),
          div(id: 'flutter-host', classes: 'flutter-host', [
            p([Component.text('SPA handoff target')]),
          ]),
        ]),
      ]),
      .element(
        tag: 'script',
        children: [
          RawText(r'''
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
'''),
        ],
      ),
    ]);
  }
}
