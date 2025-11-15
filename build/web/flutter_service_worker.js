'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "d04f09c17e1ada87e6718253cf2b1f8d",
"version.json": "5a89b2d03c2eb4ebe43015dfb79edba1",
"index.html": "47fed83da0a4ff25f5e3a46872112567",
"/": "47fed83da0a4ff25f5e3a46872112567",
"main.dart.js": "6a8ff076db7074f8d4b470a550c6cdbc",
"flutter.js": "76f08d47ff9f5715220992f993002504",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "2475e531e06c37e10eff23abb3fbe820",
"assets/AssetManifest.json": "4b79f59b002380e072c1d94192ffaa15",
"assets/NOTICES": "bb614a4223a8bfcacd00e8b73c0aeecb",
"assets/FontManifest.json": "36f8503012dc94a89a9b828ab9e22e3c",
"assets/AssetManifest.bin.json": "0d8daf2e609a2fa6f580d870ae86ea37",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "32874dd3c4172914cdd8aa783a1ce150",
"assets/fonts/MaterialIcons-Regular.otf": "59d63932560f7b2dfcb8d10aa612cc56",
"assets/assets/images/group-2.png": "59b3bc43d775bb0cff1e4880e06112b1",
"assets/assets/images/group-3.png": "33fea690569f5a584deef904a0a73251",
"assets/assets/images/exdoctor-green-1.png": "5663135b2bae90951a0d74ca72568477",
"assets/assets/images/group-1.png": "59b3bc43d775bb0cff1e4880e06112b1",
"assets/assets/images/group-4.png": "fa8989d6f8ffd1b33834cf00fb6b7437",
"assets/assets/images/group-5.png": "44ea2ab1d4e9b06756edc0e6542ff83d",
"assets/assets/images/mask-group-1.png": "728a7ea02a77dc82f9a0278184179fa8",
"assets/assets/images/exvip-pink-1.png": "32fa3546b45aa73ac5f50efc23b70cb4",
"assets/assets/images/group.png": "0695d6af02208b0b558ed9eba2fca437",
"assets/assets/images/vector.svg": "165db1ce5651f61a9a95627d5343bee3",
"assets/assets/images/mask-group-3.png": "fb5bfd033b6d1972587fdfbce629f858",
"assets/assets/images/mask-group-2.png": "e6cec60f7f12980130ca63f286ad7218",
"assets/assets/images/vector-2.svg": "8e246e3e3911e525cc2f7f4870d36aa8",
"assets/assets/images/mask-group.png": "0915f45a1659c24c0eca20c10dd4793d",
"assets/assets/images/vector-1.svg": "4a867925cbe943401817def9e3d2272c",
"assets/assets/images/pink.png": "26c2ffa15657fca07eec90ae25ee1ec8",
"assets/assets/images/exsupervip-gold-1.png": "5ff97a2923bb4bd9f5e3f9f811dbbada",
"assets/assets/images/exmember-pink-1.png": "58e8d25eef7c9f97c11545895556fa82",
"assets/assets/images/green.png": "7f376da485aac5d7539e4135cb3a054a",
"assets/assets/images/quill-hamburger.svg": "c7e2e44bfc833197afff2b6261e9b254",
"assets/assets/images/line-8.svg": "e8bb6ed2f874cf712a3e2a2fc72aabb7",
"assets/assets/images/exsupervip-gold-1..png": "ce24e51989f8d789b84f8249d09b5328",
"assets/assets/images/product2.png": "e6cec60f7f12980130ca63f286ad7218",
"assets/assets/images/group-10.png": "44ea2ab1d4e9b06756edc0e6542ff83d",
"assets/assets/images/white-1.png": "7d8da58e8246ecabb0de118a123e055f",
"assets/assets/images/simple-line-icons-present.svg": "8bc249a9c0a8e368330cab077d0deb60",
"assets/assets/images/productscreen.png": "122877ee2d87e7c9d1c090b2a68d1310",
"assets/assets/images/product3.png": "fb5bfd033b6d1972587fdfbce629f858",
"assets/assets/images/product1.png": "728a7ea02a77dc82f9a0278184179fa8",
"assets/assets/images/group-8.png": "44ea2ab1d4e9b06756edc0e6542ff83d",
"assets/assets/images/group-12.png": "44ea2ab1d4e9b06756edc0e6542ff83d",
"assets/assets/images/fluent-mdl2-go.svg": "aed8427b1e830ce10ea22824149ce3c5",
"assets/assets/images/product4.png": "0915f45a1659c24c0eca20c10dd4793d",
"assets/assets/images/group-4-3.png": "fa8989d6f8ffd1b33834cf00fb6b7437",
"assets/assets/images/group-4-2.png": "fa8989d6f8ffd1b33834cf00fb6b7437",
"assets/assets/images/purple.png": "a8d22034f70f3f43b0fa1eb2d665d6c9",
"assets/assets/images/group-4-1.png": "fa8989d6f8ffd1b33834cf00fb6b7437",
"assets/assets/fonts/Prompt-Medium.ttf": "89c1cee8280e373a6f1c29b0cf19c55f",
"assets/assets/fonts/Prompt-SemiBold.ttf": "ea37508964f6d69dcbb4fb3807ce78c0",
"assets/assets/fonts/Prompt-Regular.ttf": "4312fa208fa783a5fa77120ccadac347",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/skwasm.js": "f2ad9363618c5f62e813740099a80e63",
"canvaskit/skwasm.js.symbols": "80806576fa1056b43dd6d0b445b4b6f7",
"canvaskit/canvaskit.js.symbols": "68eb703b9a609baef8ee0e413b442f33",
"canvaskit/skwasm.wasm": "f0dfd99007f989368db17c9abeed5a49",
"canvaskit/chromium/canvaskit.js.symbols": "5a23598a2a8efd18ec3b60de5d28af8f",
"canvaskit/chromium/canvaskit.js": "34beda9f39eb7d992d46125ca868dc61",
"canvaskit/chromium/canvaskit.wasm": "64a386c87532ae52ae041d18a32a3635",
"canvaskit/skwasm_st.js.symbols": "c7e7aac7cd8b612defd62b43e3050bdd",
"canvaskit/canvaskit.js": "86e461cf471c1640fd2b461ece4589df",
"canvaskit/canvaskit.wasm": "efeeba7dcc952dae57870d4df3111fad",
"canvaskit/skwasm_st.wasm": "56c3973560dfcbf28ce47cebe40f3206"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
