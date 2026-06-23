{ { flutter_js } }
{ { flutter_build_config } }

(function () {
  const appBase = '/app/';
  let engineInitializerPromise;
  let appRunnerPromise;
  let mountedViewId = null;

  window.preloadFlutterWeb = function () {
    if (engineInitializerPromise) return engineInitializerPromise;

    engineInitializerPromise = new Promise((resolve) => {
      _flutter.loader.load({
        config: {
          entrypointBaseUrl: appBase,
          assetBase: appBase + 'assets/',
          renderer: 'skwasm',
          forceSingleThreadedSkwasm: true
        },
        onEntrypointLoaded: function (engineInitializer) {
          resolve(engineInitializer);
        }
      });
    });

    return engineInitializerPromise;
  };

  window.mountFlutterWeb = async function (hostElement) {
    const engineInitializer = await window.preloadFlutterWeb();

    if (!appRunnerPromise) {
      appRunnerPromise = engineInitializer
        .initializeEngine({ multiViewEnabled: true })
        .then((engine) => engine.runApp());
    }

    const app = await appRunnerPromise;

    if (mountedViewId !== null) return mountedViewId;

    mountedViewId = app.addView({
      hostElement,
      initialData: {
        authToken: window.localStorage.getItem('demo_auth_token') || ''
      }
    });

    return mountedViewId;
  };

  if (window.location.pathname.startsWith('/app/')) {
    window.addEventListener('load', function () {
      const host = document.getElementById('flutter-host');
      window.mountFlutterWeb(host);
    });
  }
})();