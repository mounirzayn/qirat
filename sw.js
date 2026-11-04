// QIRAT : fonctionne hors connexion pour le Coran, les horaires et les rappels.
const CACHE="qirat-v3";
const QCACHE="qirat-coran-v1";
const SHELL=["./","index.html","config.js","vendor/supabase.js","manifest.webmanifest","icons/icon-192.png","icons/icon-512.png","icons/apple-touch-icon.png"];
self.addEventListener("install",e=>{e.waitUntil(caches.open(CACHE).then(c=>c.addAll(SHELL)).then(()=>self.skipWaiting()))});
self.addEventListener("activate",e=>{e.waitUntil(caches.keys().then(k=>Promise.all(k.filter(x=>x!==CACHE&&x!==QCACHE).map(x=>caches.delete(x)))).then(()=>self.clients.claim()))});
self.addEventListener("fetch",e=>{
  const u=new URL(e.request.url);
  if(e.request.method!=="GET"||u.hostname.endsWith("supabase.co"))return; // données toujours fraîches
  if(u.origin===location.origin){
    // page et fichiers de l'appli : réseau d'abord pour avoir la dernière version, cache si hors ligne
    e.respondWith(fetch(e.request).then(r=>{const c=r.clone();caches.open(CACHE).then(x=>x.put(e.request,c));return r}).catch(()=>caches.match(e.request).then(r=>r||caches.match("index.html"))));
  }else if(u.hostname==="api.alquran.cloud"){
    // texte du Coran : ne change jamais, donc cache d'abord (lecture hors ligne)
    e.respondWith(caches.open(QCACHE).then(c=>c.match(e.request).then(r=>r||fetch(e.request).then(n=>{if(n.ok)c.put(e.request,n.clone());return n}))));
  }else if(u.hostname.includes("fonts.g")){
    e.respondWith(caches.match(e.request).then(r=>r||fetch(e.request).then(n=>{const c=n.clone();caches.open(CACHE).then(x=>x.put(e.request,c));return n})));
  }
});
