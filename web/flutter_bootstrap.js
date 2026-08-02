{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
  onEntrypointLoaded: async function(engineInitializer) {
    let app = await engineInitializer.initializeEngine({
      useColorEmoji: true,
      renderer: 'html',
    });
    await app.runApp();
  }
});
