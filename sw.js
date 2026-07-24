const CACHE = "wordhero-v16";
const FILES = ["index.html", "manifest.json", "icon.svg", "wordhero-icon.png"];

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
  // 跨域请求（云端备份 Supabase、在线发音、联网查词/翻译）一律直接走网络，不缓存不拦截
  if (url.origin !== self.location.origin) return;
  // 备份/核查请求指向外部服务器，直接走网络
  if (url.pathname.startsWith("/backup") || url.pathname.startsWith("/meta")) return;

  const isHtml = url.pathname.endsWith("/") || url.pathname.endsWith("index.html") || url.pathname.endsWith(".html");
  const isVersion = url.pathname.endsWith("version.json");
  // HTML 与 version.json 一律网络优先 + 绕过 HTTP 缓存：
  // 1) 保证代码更新后立刻生效，不再被 GitHub Pages 的 10 分钟 HTTP 缓存拖住；
  // 2) version.json 必须读最新值，否则「版本号变化强制刷新」会失效，App 永远停在旧页。
  if (isHtml || isVersion) {
    e.respondWith(
      fetch(e.request, { cache: "no-store" })
        .then(resp => { const copy = resp.clone(); caches.open(CACHE).then(c => c.put(e.request, copy).catch(() => {})); return resp; })
        .catch(() => caches.match(e.request).then(r => r || caches.match("index.html")))
    );
    return;
  }
  // 其他静态资源（图标等）用缓存优先，省流量
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
