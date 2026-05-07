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
