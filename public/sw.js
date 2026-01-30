self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open('barterpoint-v1').then((cache) => {
      return cache.addAll([
        '/',
        '/manifest.json',
        '/icons/icon-72x72.png',
        '/icons/icon-192x192.png',
        '/icons/icon-512x512.png',
      ]);
    })
  );
});

self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then((response) => {
      return response || fetch(event.request);
    })
  );
});
