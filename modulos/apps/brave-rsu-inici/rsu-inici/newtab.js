const $ = id => document.getElementById(id);
const DIES = ["diumenge","dilluns","dimarts","dimecres","dijous","divendres","dissabte"];
const MESOS = ["gener","febrer","març","abril","maig","juny","juliol","agost","setembre","octubre","novembre","desembre"];
function rellotge() {
  const d = new Date();
  $("clock").textContent = String(d.getHours()).padStart(2, "0") + ":" + String(d.getMinutes()).padStart(2, "0");
  const m = MESOS[d.getMonth()];
  $("date").textContent = `${DIES[d.getDay()]} · ${d.getDate()} ${/^[aeiou]/.test(m) ? "d'" : "de "}${m} · ${d.getFullYear()}`;
}
rellotge(); setInterval(rellotge, 1000);

// Cerca: si sembla una adreça, hi va directament
$("cerca").addEventListener("submit", e => {
  e.preventDefault();
  const q = $("q").value.trim(); if (!q) return;
  const esUrl = /^(https?:\/\/)?[\w-]+(\.[\w-]+)+(\/\S*)?$/.test(q);
  location.href = esUrl ? (q.startsWith("http") ? q : "https://" + q) : CERCADOR + encodeURIComponent(q);
});

// Enllaços amb la icona de cada web (en gris; en color en passar-hi el ratolí)
const fav = u => (chrome.runtime && chrome.runtime.id)
  ? `chrome-extension://${chrome.runtime.id}/_favicon/?pageUrl=${encodeURIComponent(u)}&size=32` : "";
$("links").innerHTML = ENLLACOS.map(l =>
  `<a href="${l.url}">${fav(l.url) ? `<img src="${fav(l.url)}" alt="">` : `<i>${l.nom[0]}</i>`}${l.nom}</a>`).join("");

// Mercat (Yahoo Finance; desat 10 min per no demanar a cada pestanya)
const pct = c => (c >= 0 ? "+" : "−") + Math.abs(c).toFixed(2) + "%";
function pinta(d) {
  const vix = d.find(x => x.s === "^VIX");
  const resta = d.filter(x => x.s !== "^VIX");
  $("tickers").innerHTML = resta.map(x =>
    `<span>${NOMS[x.s] || x.s} <b class="${x.c >= 0 ? "up" : "dn"}">${pct(x.c)}</b></span>`).join("");
  if (vix) {
    const est = vix.p >= 30 ? "panic" : vix.p >= 20 ? "tensio" : "calma";
    $("mercat").textContent = `VIX ${vix.p.toFixed(1)} · ${{calma:"CALMA",tensio:"TENSIÓ",panic:"PÀNIC"}[est]}`;
    $("mercat").className = est;
  }
}
async function mercat() {
  try {
    const c = JSON.parse(localStorage.getItem("rsu-mercat") || "null");
    if (c && Date.now() - c.t < 600000) { pinta(c.d); $("actualitzat").textContent = "ACTUALITZAT " + c.h; return; }
    if (c) pinta(c.d);
  } catch (e) {}
  try {
    const d = await Promise.all(VALORS.map(async s => {
      const r = await fetch(`https://query1.finance.yahoo.com/v8/finance/chart/${encodeURIComponent(s)}?range=1d&interval=1d`);
      const m = (await r.json()).chart.result[0].meta;
      const prev = m.chartPreviousClose || m.previousClose || m.regularMarketPrice;
      return { s, p: m.regularMarketPrice, c: (m.regularMarketPrice / prev - 1) * 100 };
    }));
    const h = new Date().toTimeString().slice(0, 5);
    try { localStorage.setItem("rsu-mercat", JSON.stringify({ t: Date.now(), h, d })); } catch (e) {}
    pinta(d); $("actualitzat").textContent = "ACTUALITZAT " + h;
  } catch (e) {
    $("actualitzat").textContent = "SENSE CONNEXIÓ";
  }
}
mercat();
