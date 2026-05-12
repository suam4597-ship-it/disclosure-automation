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
  configVersion: "staging-20260511-1",
  allowQueryParamOverride: true
});

window.DISCLOSURE_API_BASE_URL =
  window.DISCLOSURE_API_BASE_URL || window.GLOBALPULSE_RUNTIME_CONFIG.apiBaseUrl;

// Canonical region metadata shared with the single-file dashboard shell.
// Keep this aligned with DisclosureAutomation.Canonicalizer.infer_regions/1.
window.GLOBALPULSE_REGION_LABELS = Object.assign(
  {
    global: "Global",
    us: "US Americas",
    eu: "EU Europe",
    eu_north: "Northern Europe",
    eu_central: "Central Europe",
    eu_south: "Southern Europe",
    uk: "United Kingdom",
    ch: "Switzerland",
    tr: "Turkey",
    kr: "KR Korea",
    jp: "JP Japan",
    greater_china: "CN/TW Greater China",
    cn: "Mainland China",
    tw: "Taiwan",
    hk: "Hong Kong",
    apac: "Asia-Pacific",
    asean: "ASEAN",
    india: "India",
    anz: "Australia/NZ",
    other: "Other Regions"
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
    "global",
    "us",
    "kr",
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
    "eu_north",
    "eu_central",
    "eu_south",
    "uk",
    "ch",
    "tr",
    "other"
  ];
