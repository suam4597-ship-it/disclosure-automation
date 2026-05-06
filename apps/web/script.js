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

document.getElementById("show-status")?.addEventListener("click", loadHealthStatus);

loadHealthStatus();
