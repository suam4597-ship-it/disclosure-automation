# GlobalPulse Taiwan TWSE Fly Egress Block Diagnostic

Date: 2026-05-27

## Conclusion

Taiwan listed-company material information remains blocked for Fly staging live polling.

The official TWSE OpenAPI endpoint is valid and machine-readable from local network checks:

```text
https://openapi.twse.com.tw/v1/opendata/t187ap04_L
```

However, the same TWSE/MOPS family endpoints return the TWSE security block page from the Fly
staging VM instead of JSON or expected HTML content.

## Fly Staging Result

Observed from `globalpulse-backend-staging`:

```text
source_key=tw_mops_daily_material_information
status_code=200 or 307 depending on endpoint
content_type=text/html; charset=UTF-8
body_signature=FOR SECURITY REASONS, THIS PAGE CAN NOT BE ACCESSED
```

Endpoints checked from Fly staging:

```text
https://openapi.twse.com.tw/v1/opendata/t187ap04_L
https://www.twse.com.tw/rwd/zh/IIH/market/events
https://www.twse.com.tw/rwd/en/IIH/market/events
https://mopsov.twse.com.tw/mops/web/ajax_t05sr01_1
https://mops.twse.com.tw/mops/web/ajax_t05st02
```

Header variants with browser user-agent, `Accept`, `Accept-Language`, `Referer`, and `Origin`
did not change the Fly result.

## Implementation Follow-up

Runtime validation now classifies this specific upstream block as:

```text
{:upstream_security_blocked, "tw_mops_daily_material_info_json_v1", "twse_security_page"}
```

This is intentionally bounded and does not expose the raw HTML block body in public digest output.

## Guardrails

```text
TWSE source remains manual-staging-only
production scheduled polling remains disabled
fixture fallback is not counted as live success
third-party mirrors are not enabled without explicit approval
backend digest JSON response shape unchanged
public poll UI unchanged
public Source Health UI unchanged
```

## Next Options

```text
1. Request TWSE/MOPS allowlisting for the Fly staging egress path.
2. Move this source to a non-Fly backend/proxy with an accepted egress profile.
3. Use an explicitly approved data vendor or third-party mirror as a separate source candidate.
4. Keep Taiwan source out of live staging refresh until one of the above is available.
```
