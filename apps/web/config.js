// GlobalPulse 런타임 설정.
// 화면 동작(어느 백엔드를 부를지, 지역·타임존)은 코드가 아니라 이 파일에서 바꾼다.
// 타임존은 IANA 존 이름만 사용한다. 오프셋(+09:00) 하드코딩 금지 — 서머타임에 깨진다.
window.GLOBALPULSE_RUNTIME_CONFIG = {
  environment: "staging",
  configVersion: "staging-20260610-1",
  apiBase: "https://globalpulse-backend-staging.fly.dev",
  edition: "breaking",
  // ?apiBase=... 쿼리 파라미터로 로컬 백엔드 등을 임시 지정할 수 있게 허용
  allowQueryParamOverride: true,
  displayTimezone: "Asia/Seoul",
  regions: [
    { key: "asia_pacific",  name: "Japan / Asia-Pacific", flag: "JP",    timezone: "Asia/Tokyo",       deliveryLocalTime: "18:30" },
    { key: "greater_china", name: "Greater China",        flag: "CN/TW", timezone: "Asia/Taipei",      deliveryLocalTime: "19:00" },
    { key: "korea",         name: "Korea",                flag: "KR",    timezone: "Asia/Seoul",       deliveryLocalTime: "20:45" },
    { key: "eu_north",      name: "Europe (North)",       flag: "EU",    timezone: "Europe/Copenhagen", deliveryLocalTime: "20:30" },
    { key: "eu_central",    name: "Europe (Central)",     flag: "EU",    timezone: "Europe/Paris",     deliveryLocalTime: "20:30" },
    { key: "eu_south",      name: "Europe (South)",       flag: "EU",    timezone: "Europe/Madrid",    deliveryLocalTime: "20:30" },
    { key: "americas",      name: "Americas",             flag: "US",    timezone: "America/New_York", deliveryLocalTime: "21:00" }
  ],
  categories: [
    { key: "supply_demand",   name: "Supply / Demand",      cssClass: "supply-demand",  color: "#3B82F6" },
    { key: "tech_innovation", name: "Tech Innovation",      cssClass: "tech-innovation", color: "#8B5CF6" },
    { key: "shortage_surge",  name: "Shortage / Surge",     cssClass: "shortage-surge", color: "#EF4444" },
    { key: "ma_capital_flow", name: "M&A / Capital Flow",   cssClass: "ma",             color: "#F59E0B" },
    { key: "earnings",        name: "Earnings",             cssClass: "earnings",       color: "#22C55E" }
  ]
};

// 하위 호환: 일부 스크립트/스모크 테스트가 참조하는 전역 변수
window.DISCLOSURE_API_BASE_URL = window.GLOBALPULSE_RUNTIME_CONFIG.apiBase;
