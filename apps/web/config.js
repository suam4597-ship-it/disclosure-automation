// Runtime configuration for the GlobalPulse GitHub Pages frontend.
//
// This default points the public Pages UI at the stable Fly.io staging backend.
// It is intended for browser smoke and staging validation, not production.
//
// Override options:
// - set window.DISCLOSURE_API_BASE_URL before this file is loaded, or
// - use ?apiBase=<backend-url> in the page URL for one-off smoke tests.

window.GLOBALPULSE_RUNTIME_CONFIG = Object.freeze({
  environment: "staging",
  apiBaseUrl: "https://globalpulse-backend-staging.fly.dev",
  configVersion: "staging-20260513-link-filter-1",
  allowQueryParamOverride: true
});

window.DISCLOSURE_API_BASE_URL =
  window.DISCLOSURE_API_BASE_URL || window.GLOBALPULSE_RUNTIME_CONFIG.apiBaseUrl;

// Canonical region metadata shared with the single-file dashboard shell.
// Keep this aligned with DisclosureAutomation.Canonicalizer.infer_regions/1.
window.GLOBALPULSE_REGION_LABELS = Object.assign(
  {
    global: "전체",
    us: "미국",
    eu: "유럽",
    eu_north: "북유럽",
    eu_central: "중부 유럽",
    eu_south: "남유럽",
    uk: "영국",
    ch: "스위스",
    tr: "튀르키예",
    kr: "한국",
    jp: "일본",
    greater_china: "중국/대만",
    cn: "중국 본토",
    tw: "대만",
    hk: "홍콩",
    apac: "아시아/태평양",
    asean: "ASEAN",
    india: "인도",
    anz: "호주/뉴질랜드",
    other: "기타 지역"
  },
  window.GLOBALPULSE_REGION_LABELS || {}
);

window.GLOBALPULSE_REGION_ALIASES = Object.assign(
  {
    americas: "us",
    usa: "us",
    united_states: "us",
    united_states_of_america: "us",
    europe: "eu",
    europe_north: "eu_north",
    northern_europe: "eu_north",
    europe_central: "eu_central",
    central_europe: "eu_central",
    europe_south: "eu_south",
    southern_europe: "eu_south",
    gb: "uk",
    great_britain: "uk",
    united_kingdom: "uk",
    switzerland: "ch",
    turkey: "tr",
    turkiye: "tr",
    korea: "kr",
    south_korea: "kr",
    japan: "jp",
    cn_tw: "greater_china",
    greaterchina: "greater_china",
    china: "cn",
    mainland_china: "cn",
    taiwan: "tw",
    hong_kong: "hk",
    hongkong: "hk",
    southeast_asia: "asean",
    south_east_asia: "asean",
    in: "india",
    australia_nz: "anz",
    australia: "anz",
    new_zealand: "anz"
  },
  window.GLOBALPULSE_REGION_ALIASES || {}
);

window.GLOBALPULSE_REGION_ORDER =
  window.GLOBALPULSE_REGION_ORDER || [
    "us",
    "jp",
    "greater_china",
    "cn",
    "tw",
    "hk",
    "apac",
    "asean",
    "india",
    "anz",
    "eu",
    "global",
    "other"
  ];

window.GLOBALPULSE_HIDDEN_REGIONS =
  window.GLOBALPULSE_HIDDEN_REGIONS || ["kr"];

// Region-specific disclosure exclusions live here. Keep this off the public UI;
// update these lists when an operator asks to hide a category for a region.
window.GLOBALPULSE_REGION_EXCLUSION_RULES = Object.assign(
  {},
  window.GLOBALPULSE_REGION_EXCLUSION_RULES || {}
);
