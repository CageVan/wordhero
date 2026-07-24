const CACHE = "koreanhero-v1";
const FILES = ["index.html", "manifest.json", "icon.svg", "icon-512.png"];

self.addEventListener("install", e => {
  e.waitUntil(
    caches.open(CACHE).then(c => c.addAll(FILES).catch(() => {})).then(() => self.skipWaiting())
  );
});

self.addEventListener("activate", e => {
  e.waitUntil(
    caches.keys()
      .then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", e => {
  if (e.request.method !== "GET") return;
  const url = new URL(e.request.url);
  // 跨域请求（在线发音、联网翻译）一律直接走网络，不缓存不拦截
  if (url.origin !== self.location.origin) return;

  const isHtml = url.pathname.endsWith("/") || url.pathname.endsWith("index.html") || url.pathname.endsWith(".html");
  const isVersion = url.pathname.endsWith("version.json");
  // HTML 与 version.json 一律网络优先 + 绕过 HTTP 缓存，保证上线后立即生效
  if (isHtml || isVersion) {
    e.respondWith(
      fetch(e.request, { cache: "no-store" })
        .then(resp => { const copy = resp.clone(); caches.open(CACHE).then(c => c.put(e.request, copy).catch(() => {})); return resp; })
        .catch(() => caches.match(e.request).then(r => r || caches.match("index.html")))
    );
    return;
  }
  // 其他静态资源（图标等）缓存优先
  e.respondWith(
    caches.match(e.request).then(r =>
      r || fetch(e.request).then(resp => {
        const copy = resp.clone();
        caches.open(CACHE).then(c => c.put(e.request, copy).catch(() => {}));
        return resp;
      }).catch(() => caches.match("index.html"))
    )
  );
});
