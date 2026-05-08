// Runtime configuration for the GlobalPulse GitHub Pages frontend.
//
// This default points the public Pages UI at the stable Fly.io staging backend.
// It is intended for browser smoke and staging validation, not production.
//
// Override options:
// - set window.DISCLOSURE_API_BASE_URL before this file is loaded, or
// - use ?apiBase=<backend-url> in the page URL for one-off smoke tests.

window.DISCLOSURE_API_BASE_URL =
  window.DISCLOSURE_API_BASE_URL || "https://globalpulse-backend-staging.fly.dev";

// UI adapter for backend region codes that were added after the original
// single-file GlobalPulse shell. This keeps the large index.html stable while
// allowing backend canonical regions to render as distinct Europe buckets.
window.addEventListener("load", () => {
  const labels = {
    eu_north: "Northern Europe",
    eu_central: "Central Europe",
    eu_south: "Southern Europe"
  };

  const normalize = value => {
    const raw = String(value || "global").toLowerCase();
    if (raw === "europe_north") return "eu_north";
    if (raw === "europe_central") return "eu_central";
    if (raw === "europe_south") return "eu_south";
    if (labels[raw]) return raw;
    if (raw === "usa") return "us";
    if (raw === "europe") return "eu";
    if (raw === "korea") return "kr";
    if (raw === "japan") return "jp";
    if (raw === "china") return "cn";
    return typeof window.REGION_LABELS !== "undefined" && window.REGION_LABELS?.[raw] ? raw : raw;
  };

  if (typeof window.canonicalRegion === "function") {
    window.canonicalRegion = normalize;
  }

  if (typeof window.regionLabel === "function") {
    const previousRegionLabel = window.regionLabel;
    window.regionLabel = code => labels[code] || previousRegionLabel(code);
  }

  if (typeof window.loadBackend === "function") {
    window.loadBackend();
  }
});
