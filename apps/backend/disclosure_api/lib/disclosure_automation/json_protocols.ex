require Protocol

Protocol.derive(Jason.Encoder, DisclosureAutomation.Schema.SourceCursor,
  only: [:cursor_key, :cursor_value, :cursor_meta, :last_polled_at]
)
