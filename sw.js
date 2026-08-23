// Service worker: rede primeiro (para as atualizações chegarem sempre),
// cache só como rede de segurança quando não há ligação.
const CACHE = "appdespesas-v1";
const SHELL = ["./", "./index.html", "./manifest.webmanifest",
               "./icons/icon-180.png", "./icons/icon-512.png"];

self.addEventListener("install", (e) => {
  e.waitUntil(caches.open(CACHE).then(c => c.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches.keys()
      .then(ks => Promise.all(ks.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (e) => {
  const req = e.request;
  if (req.method !== "GET") return;
  const url = new URL(req.url);
  // Chamadas ao Supabase nunca passam pelo cache.
  if (url.hostname.endsWith("supabase.co")) return;

  e.respondWith(
    fetch(req)
      .then(res => {
        if (res && res.ok && (url.origin === location.origin || url.hostname.endsWith("gstatic.com")
            || url.hostname.endsWith("googleapis.com") || url.hostname.endsWith("jsdelivr.net"))){
          const copia = res.clone();
          caches.open(CACHE).then(c => c.put(req, copia)).catch(() => {});
        }
        return res;
      })
      .catch(() => caches.match(req).then(hit => hit || caches.match("./index.html")))
  );
});
