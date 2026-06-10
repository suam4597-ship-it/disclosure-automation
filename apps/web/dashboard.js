// GlobalPulse 대시보드 렌더러.
// 데이터는 백엔드 digest API에서 가져오고, 실패하면 "샘플 데이터"임을 명시하고 폴백을 보여준다.
// 시간 계산 규칙: 저장/전송은 UTC, 표시는 Intl + IANA 타임존. 오프셋 하드코딩 금지.
(function () {
  "use strict";

  var CONFIG = window.GLOBALPULSE_RUNTIME_CONFIG || {};

  // ?apiBase=... 로 임시 백엔드 지정 허용 (config에서 켠 경우에만)
  function resolveApiBase() {
    if (CONFIG.allowQueryParamOverride) {
      var override = new URLSearchParams(window.location.search).get("apiBase");
      if (override) return override.replace(/\/+$/, "");
    }
    return (CONFIG.apiBase || "").replace(/\/+$/, "");
  }

  var API_BASE = resolveApiBase();
  var EDITION = CONFIG.edition || "breaking";
  var DISPLAY_TZ = CONFIG.displayTimezone || "Asia/Seoul";
  var REGIONS = CONFIG.regions || [];
  var CATEGORIES = CONFIG.categories || [];

  var regionByKey = {};
  REGIONS.forEach(function (r) { regionByKey[r.key] = r; });
  var categoryByKey = {};
  CATEGORIES.forEach(function (c) { categoryByKey[c.key] = c; });

  // 백엔드 필드명이 다를 수 있으므로 흔한 이름들을 순서대로 시도한다 (방어적 매핑)
  function pick(obj, names) {
    for (var i = 0; i < names.length; i++) {
      var v = obj[names[i]];
      if (v !== undefined && v !== null && v !== "") return v;
    }
    return null;
  }

  function normalizeCategoryKey(raw) {
    if (!raw) return null;
    var k = String(raw).toLowerCase().replace(/[\s/-]+/g, "_");
    var aliases = {
      ma: "ma_capital_flow", m_a: "ma_capital_flow", m_a_capital_flow: "ma_capital_flow",
      tech: "tech_innovation", supply: "supply_demand", supply_demand_changes: "supply_demand",
      shortage: "shortage_surge", earnings_reports: "earnings"
    };
    k = aliases[k] || k;
    return categoryByKey[k] ? k : null;
  }

  function normalizeItem(raw) {
    var cats = [];
    var rawCats = raw.categories || raw.category_keys || (raw.category ? [raw.category] : []);
    (Array.isArray(rawCats) ? rawCats : [rawCats]).forEach(function (c) {
      var key = normalizeCategoryKey(typeof c === "object" && c ? (c.key || c.name) : c);
      if (key && cats.indexOf(key) < 0) cats.push(key);
    });

    var evidenceCount = pick(raw, ["evidence_count"]);
    var duplicates = pick(raw, ["duplicates_removed", "duplicate_count"]);
    if (duplicates === null && typeof evidenceCount === "number") {
      duplicates = Math.max(0, evidenceCount - 1);
    }

    return {
      headline: pick(raw, ["headline", "title"]) || "(제목 없음)",
      summary: pick(raw, ["summary", "description", "body_preview"]) || "",
      source: pick(raw, ["source", "source_name", "source_key", "primary_source"]) || "unknown",
      url: pick(raw, ["url", "link"]),
      region: pick(raw, ["region", "region_key"]) || "unknown",
      categories: cats,
      publishedAt: parseDate(pick(raw, ["published_at_utc", "published_at", "occurred_at_utc", "occurred_at", "timestamp"])),
      duplicatesRemoved: typeof duplicates === "number" ? duplicates : 0
    };
  }

  function parseDate(value) {
    if (!value) return null;
    var d = new Date(value);
    return isNaN(d.getTime()) ? null : d;
  }

  // ---- 시간 표시 (전부 Intl 기반, 표시 계층에서만 변환) ----

  function formatInZone(date, tz, opts) {
    return new Intl.DateTimeFormat("en-CA", Object.assign({ timeZone: tz }, opts)).format(date);
  }

  function formatClock(date) {
    var ymd = formatInZone(date, DISPLAY_TZ, { year: "numeric", month: "2-digit", day: "2-digit" });
    var hm = formatInZone(date, DISPLAY_TZ, { hour: "2-digit", minute: "2-digit", hour12: false });
    return ymd + " KST " + hm;
  }

  function relativeTime(date) {
    if (!date) return "";
    var mins = Math.round((Date.now() - date.getTime()) / 60000);
    if (mins < 1) return "방금";
    if (mins < 60) return mins + "분 전";
    var hours = Math.round(mins / 60);
    if (hours < 24) return hours + "시간 전";
    return Math.round(hours / 24) + "일 전";
  }

  // 특정 타임존의 UTC 오프셋(분) — Intl에서 읽는다 (서머타임 자동 반영)
  function zoneOffsetMinutes(tz, date) {
    var parts = new Intl.DateTimeFormat("en-US", { timeZone: tz, timeZoneName: "shortOffset" })
      .formatToParts(date);
    var name = (parts.find(function (p) { return p.type === "timeZoneName"; }) || {}).value || "GMT+0";
    var m = name.match(/GMT([+-])(\d{1,2})(?::(\d{2}))?/);
    if (!m) return 0;
    return (m[1] === "-" ? -1 : 1) * (parseInt(m[2], 10) * 60 + (m[3] ? parseInt(m[3], 10) : 0));
  }

  // "현지 HH:MM 배달"이 표시 타임존(KST)으로 몇 시인지 — 오늘 날짜 기준으로 계산
  function localDeliveryToDisplay(tz, hhmm) {
    var now = new Date();
    var h = parseInt(hhmm.split(":")[0], 10);
    var min = parseInt(hhmm.split(":")[1], 10);
    var localYmd = formatInZone(now, tz, { year: "numeric", month: "2-digit", day: "2-digit" });
    var utcGuess = new Date(localYmd + "T" + hhmm + ":00Z");
    var utc = new Date(utcGuess.getTime() - zoneOffsetMinutes(tz, utcGuess) * 60000);
    var displayHm = formatInZone(utc, DISPLAY_TZ, { hour: "2-digit", minute: "2-digit", hour12: false });
    var dayDiff = formatInZone(utc, DISPLAY_TZ, { day: "2-digit" }) !== localYmd.slice(8, 10);
    return displayHm + (dayDiff ? " +1" : "");
  }

  // ---- 렌더링 ----

  function el(tag, className, text) {
    var node = document.createElement(tag);
    if (className) node.className = className;
    if (text !== undefined) node.textContent = text;
    return node;
  }

  var state = { items: [], activeCategory: "all", usingSample: false, metadata: null };

  function render() {
    renderBanner();
    renderTabs();
    renderFeed();
    renderSidebar();
  }

  function renderBanner() {
    var bar = document.getElementById("dedupBar");
    var totalDuplicates = state.items.reduce(function (sum, it) { return sum + it.duplicatesRemoved; }, 0);
    bar.innerHTML = "";
    if (state.usingSample) {
      bar.appendChild(el("span", null, "⚠️ 백엔드에 연결하지 못해 샘플 데이터를 표시 중입니다. (" + API_BASE + ")"));
      return;
    }
    var span = el("span");
    span.appendChild(document.createTextNode("Deduplication active — "));
    span.appendChild(el("strong", null, totalDuplicates + " duplicate articles"));
    span.appendChild(document.createTextNode(" removed across regions. Each story appears once under its primary source."));
    bar.appendChild(span);
  }

  function countByCategory(key) {
    if (key === "all") return state.items.length;
    return state.items.filter(function (it) { return it.categories.indexOf(key) >= 0; }).length;
  }

  function renderTabs() {
    var tabs = document.getElementById("tabs");
    tabs.innerHTML = "";
    var defs = [{ key: "all", name: "All" }].concat(CATEGORIES);
    defs.forEach(function (def) {
      var btn = el("button", "tab" + (state.activeCategory === def.key ? " active" : ""), def.name);
      var badge = el("span", "badge", String(countByCategory(def.key)));
      btn.appendChild(badge);
      btn.addEventListener("click", function () {
        state.activeCategory = def.key;
        renderTabs();
        renderFeed();
      });
      tabs.appendChild(btn);
    });
  }

  function visibleItems() {
    if (state.activeCategory === "all") return state.items;
    return state.items.filter(function (it) { return it.categories.indexOf(state.activeCategory) >= 0; });
  }

  function renderFeed() {
    var feed = document.getElementById("feed");
    feed.innerHTML = "";
    var items = visibleItems();

    if (!items.length) {
      feed.appendChild(el("div", "region-group", "표시할 항목이 없습니다."));
      return;
    }

    var grouped = {};
    items.forEach(function (it) {
      (grouped[it.region] = grouped[it.region] || []).push(it);
    });

    Object.keys(grouped).forEach(function (regionKey) {
      var region = regionByKey[regionKey] || { name: regionKey, flag: "—" };
      var group = el("div", "region-group");
      var header = el("div", "region-header");
      var title = el("div", "region-title");
      title.appendChild(el("span", "region-flag", region.flag));
      title.appendChild(el("span", "region-name", region.name));
      var meta = el("div", "region-meta");
      meta.appendChild(el("span", null, grouped[regionKey].length + " items"));
      header.appendChild(title);
      header.appendChild(meta);
      var body = el("div", "region-body");
      header.addEventListener("click", function () {
        body.style.display = body.style.display === "none" ? "block" : "none";
      });
      grouped[regionKey].forEach(function (it) { body.appendChild(renderItem(it)); });
      group.appendChild(header);
      group.appendChild(body);
      feed.appendChild(group);
    });
  }

  function renderItem(it) {
    var node = el("div", "news-item");
    var firstCat = it.categories[0] ? categoryByKey[it.categories[0]] : null;
    node.appendChild(el("div", "news-category-indicator " + (firstCat ? firstCat.cssClass : "")));

    var content = el("div", "news-content");
    if (it.url) {
      var link = el("a", null, it.headline);
      link.href = it.url;
      link.target = "_blank";
      link.rel = "noopener noreferrer";
      link.style.color = "inherit";
      var headline = el("div", "news-headline");
      headline.appendChild(link);
      content.appendChild(headline);
    } else {
      content.appendChild(el("div", "news-headline", it.headline));
    }
    if (it.summary) content.appendChild(el("div", "news-summary", it.summary));

    var meta = el("div", "news-meta");
    meta.appendChild(el("span", "news-source", it.source));
    if (it.publishedAt) meta.appendChild(el("span", null, relativeTime(it.publishedAt)));
    if (it.duplicatesRemoved > 0) meta.appendChild(el("span", null, "+" + it.duplicatesRemoved + " duplicates merged"));
    it.categories.forEach(function (key) {
      var cat = categoryByKey[key];
      if (cat) meta.appendChild(el("span", "news-tag " + cat.cssClass, cat.name));
    });
    content.appendChild(meta);
    node.appendChild(content);
    return node;
  }

  function renderSidebar() {
    // 배달 스케줄: config의 (IANA 존, 현지 시각)에서 KST 환산을 실행 시점에 계산
    var schedule = document.getElementById("scheduleList");
    schedule.innerHTML = "";
    REGIONS.forEach(function (region) {
      var li = el("li", "schedule-item");
      li.appendChild(el("span", "schedule-region", region.flag + " " + region.name));
      var right = el("div");
      right.appendChild(el("span", "schedule-time", localDeliveryToDisplay(region.timezone, region.deliveryLocalTime) + " KST"));
      right.appendChild(el("span", "schedule-local", " = " + region.deliveryLocalTime + " (" + region.timezone + ")"));
      li.appendChild(right);
      schedule.appendChild(li);
    });

    var legend = document.getElementById("legendList");
    legend.innerHTML = "";
    CATEGORIES.forEach(function (cat) {
      var li = el("li", "legend-item");
      var dot = el("span", "legend-dot");
      dot.style.background = cat.color;
      li.appendChild(dot);
      li.appendChild(document.createTextNode(cat.name));
      li.appendChild(el("span", "legend-count", String(countByCategory(cat.key))));
      legend.appendChild(li);
    });

    var health = document.getElementById("sourceHealth");
    health.innerHTML = "";
    if (state.usingSample) {
      health.appendChild(el("div", null, "backend unreachable — 샘플 데이터 표시 중"));
    } else {
      health.appendChild(el("div", null, "backend: ok (" + API_BASE + ")"));
      var meta = state.metadata || {};
      health.appendChild(el("div", null, "edition: " + EDITION + " · fixture fallback: " + String(meta.fallback_to_fixture)));
    }
  }

  // ---- 데이터 로드 ----

  // 연결 실패 시에만 쓰는 폴백. 화면에 "샘플 데이터"라고 명시된다.
  var SAMPLE_ITEMS = [
    { headline: "[샘플] ASML Reports Record Backlog as EUV Demand Exceeds Capacity", summary: "샘플 데이터입니다. 백엔드 연결 후 실제 공시로 대체됩니다.", source: "sample", region: "eu_central", categories: ["earnings"], published_at_utc: new Date(Date.now() - 2 * 3600000).toISOString() },
    { headline: "[샘플] TSMC Monthly Revenue +35% YoY on Advanced Node Demand", summary: "샘플 데이터입니다.", source: "sample", region: "greater_china", categories: ["earnings", "supply_demand"], published_at_utc: new Date(Date.now() - 10 * 3600000).toISOString() },
    { headline: "[샘플] Broadcom Nears $85B Deal for Cloud Software Acquisition", summary: "샘플 데이터입니다.", source: "sample", region: "americas", categories: ["ma_capital_flow"], published_at_utc: new Date(Date.now() - 3 * 3600000).toISOString() }
  ];

  function load() {
    fetch(API_BASE + "/api/feed/digest/latest?edition=" + encodeURIComponent(EDITION))
      .then(function (res) {
        if (!res.ok) throw new Error("digest fetch failed: " + res.status);
        return res.json();
      })
      .then(function (payload) {
        state.items = (payload.items || []).map(normalizeItem);
        state.metadata = payload.metadata || null;
        state.usingSample = false;
        render();
      })
      .catch(function (err) {
        console.warn("GlobalPulse: falling back to sample data —", err);
        state.items = SAMPLE_ITEMS.map(normalizeItem);
        state.metadata = null;
        state.usingSample = true;
        render();
      });
  }

  // ---- 시계 ----
  function tickClock() {
    var node = document.getElementById("currentTime");
    if (node) node.textContent = formatClock(new Date());
  }

  document.addEventListener("DOMContentLoaded", function () {
    tickClock();
    setInterval(tickClock, 30000);
    load();
  });
})();
