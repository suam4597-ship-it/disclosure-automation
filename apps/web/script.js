const API_BASE_URL = window.DISCLOSURE_API_BASE_URL || "";

async function fetchJson(path) {
  const response = await fetch(`${API_BASE_URL}${path}`, {
    headers: {
      Accept: "application/json"
    }
  });

  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`);
  }

  return response.json();
}

function setText(id, value) {
  const target = document.getElementById(id);
  if (target) {
    target.textContent = value;
  }
}

function setListItems(id, values) {
  const target = document.getElementById(id);
  if (!target) {
    return;
  }

  target.innerHTML = "";

  values.forEach((value) => {
    const item = document.createElement("li");
    item.textContent = value;
    target.appendChild(item);
  });
}

function firstPresent(...values) {
  return values.find((value) => value !== undefined && value !== null && value !== "");
}

function digestItemsFrom(payload) {
  if (Array.isArray(payload?.items)) {
    return payload.items;
  }

  if (Array.isArray(payload?.data?.items)) {
    return payload.data.items;
  }

  if (Array.isArray(payload?.digest?.items)) {
    return payload.digest.items;
  }

  if (Array.isArray(payload?.data)) {
    return payload.data;
  }

  return [];
}

function digestSummaryFrom(payload, itemCount) {
  const edition = firstPresent(payload?.edition, payload?.data?.edition, payload?.digest?.edition, "breaking");
  const digestDate = firstPresent(
    payload?.digest_date,
    payload?.data?.digest_date,
    payload?.digest?.digest_date,
    payload?.date,
    payload?.data?.date,
    "latest"
  );

  return `edition=${edition} · digest=${digestDate} · items=${itemCount}`;
}

function labelForDigestItem(item, index) {
  if (typeof item === "string") {
    return item;
  }

  const title = firstPresent(item?.title, item?.headline, item?.display_title, item?.event_title, `item ${index + 1}`);
  const region = firstPresent(item?.region_code, item?.region, item?.market_region_code);
  const source = firstPresent(item?.source_key, item?.source, item?.provider);
  const publishedAt = firstPresent(item?.published_at, item?.publishedAt, item?.published_at_utc, item?.date);

  return [title, region, source, publishedAt].filter(Boolean).join(" · ");
}

function renderDigest(payload) {
  const items = digestItemsFrom(payload);
  setText("digest-summary", digestSummaryFrom(payload, items.length));

  if (items.length === 0) {
    setListItems("digest-items", ["표시할 최신 digest 항목이 아직 없습니다."]);
    return;
  }

  setListItems("digest-items", items.slice(0, 5).map(labelForDigestItem));
}

function renderDigestUnavailable() {
  setText("digest-summary", "최신 digest를 확인할 수 없습니다.");
  setListItems("digest-items", ["API 서버가 아직 연결되지 않았거나 digest 데이터가 준비되지 않았습니다."]);
}

async function loadLatestDigest() {
  setText("digest-summary", "최신 digest를 불러오는 중입니다.");
  setListItems("digest-items", ["GET /api/feed/digest/latest 응답을 기다리고 있습니다."]);

  try {
    const payload = await fetchJson("/api/feed/digest/latest?edition=breaking");
    renderDigest(payload);
  } catch (_error) {
    renderDigestUnavailable();
  }
}

function renderHealthStatus(payload) {
  const service = payload?.service || "disclosure_automation";
  const phase = payload?.phase || "unknown";
  const repoStatus = payload?.repo || "unknown";
  const status = payload?.status || "unknown";

  setText("status-text", `백엔드 상태: ${status}`);
  setText("status-details", `service=${service} · phase=${phase} · repo=${repoStatus}`);
}

function renderHealthUnavailable() {
  setText("status-text", "백엔드 상태: 확인 불가");
  setText(
    "status-details",
    "API 서버가 아직 연결되지 않았거나 일시적으로 응답하지 않습니다. 화면은 기존 HTML shell로 계속 표시됩니다."
  );
}

async function loadHealthStatus() {
  setText("status-text", "백엔드 상태를 확인하는 중입니다.");
  setText("status-details", "GET /api/health 응답을 기다리고 있습니다.");

  try {
    const payload = await fetchJson("/api/health");
    renderHealthStatus(payload);
  } catch (_error) {
    renderHealthUnavailable();
  }
}

document.getElementById("show-status")?.addEventListener("click", () => {
  loadHealthStatus();
  loadLatestDigest();
});

loadHealthStatus();
loadLatestDigest();
