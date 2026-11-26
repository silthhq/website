// silth.dev interactions: tabs, copy buttons, mobile nav, docs search.
import "silth";

const $ = (sel, root = document) => root.querySelector(sel);
const $$ = (sel, root = document) => Array.from(root.querySelectorAll(sel));

// Tabs on the home page
$$("[data-tabs]").forEach((tabs) => {
  tabs.addEventListener("click", (e) => {
    const btn = e.target.closest("[data-tab]");
    if (!btn) return;
    $$("[data-tab]", tabs).forEach((b) => b.setAttribute("aria-selected", String(b === btn)));
    $$("[data-panel]", tabs).forEach((p) => (p.hidden = p.dataset.panel !== btn.dataset.tab));
  });
});

// Copy install command
$$("[data-copy]").forEach((box) => {
  box.querySelector("button")?.addEventListener("click", async () => {
    await navigator.clipboard.writeText(box.dataset.copy);
    box.classList.add("copied");
    setTimeout(() => box.classList.remove("copied"), 1500);
  });
});

// Copy buttons on code blocks
$$(".prose pre.code").forEach((pre) => {
  const btn = document.createElement("button");
  btn.className = "copy-btn";
  btn.type = "button";
  btn.textContent = "Copy";
  btn.addEventListener("click", async () => {
    await navigator.clipboard.writeText(pre.innerText.replace(/Copy$/, "").trim());
    btn.textContent = "Copied";
    setTimeout(() => (btn.textContent = "Copy"), 1200);
  });
  pre.appendChild(btn);
});

// Mobile navigation
$("[data-nav-toggle]")?.addEventListener("click", () => $("[data-nav]").classList.toggle("open"));

// Docs search (client side, one index per docs version: /docs/search.json, /docs/0.1/search.json…)
const search = $("[data-search]");
if (search) {
  const results = $("[data-search-results]");
  let index = null;
  const load = async () => (index ||= await (await fetch(search.dataset.searchIndex || "/docs/search.json")).json());
  const score = (doc, terms) => terms.reduce((s, t) => {
    const title = doc.title.toLowerCase(), heads = doc.headings.join(" ").toLowerCase(), text = doc.text.toLowerCase();
    return s + (title.includes(t) ? 10 : 0) + (heads.includes(t) ? 4 : 0) + (text.includes(t) ? 1 : 0);
  }, 0);
  search.addEventListener("input", async () => {
    const q = search.value.trim().toLowerCase();
    if (q.length < 2) { results.hidden = true; return; }
    const terms = q.split(/\s+/);
    const docs = (await load()).map((d) => [score(d, terms), d]).filter(([s]) => s > 0).sort((a, b) => b[0] - a[0]).slice(0, 8);
    results.innerHTML = docs.length
      ? docs.map(([, d]) => `<a href="${d.url}">${d.title}<small>${d.section}</small></a>`).join("")
      : `<a><small>No results</small></a>`;
    results.hidden = false;
  });
  document.addEventListener("keydown", (e) => {
    if (e.key === "/" && document.activeElement !== search) { e.preventDefault(); search.focus(); }
  });
}
