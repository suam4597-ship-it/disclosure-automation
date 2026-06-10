defmodule DisclosureAutomation.Canonicalizer do
  @moduledoc """
  Converts parser output into a conservative canonical feed-item shape.

  The Phase 0 goal is contract stability, so this helper focuses on key naming
  and default values rather than advanced NLP or deduplication.
  """

  def canonicalize_document(%{} = document, attrs \\ %{}) do
    published_at = Map.get(document, "published_at") || Map.get(document, :published_at)

    %{
      story_key: Map.get(document, "story_key") || Map.get(document, :story_key) || Map.get(attrs, :story_key),
      headline: Map.get(document, "headline") || Map.get(document, :headline) || Map.get(document, "title") || Map.get(document, :title),
      summary: Map.get(document, "summary") || Map.get(document, :summary) || "",
      canonical_url: Map.get(document, "canonical_url") || Map.get(document, :canonical_url) || Map.get(document, "url") || Map.get(document, :url),
      published_at: published_at,
      tickers: Map.get(document, "tickers") || Map.get(document, :tickers) || [],
      regions: Map.get(document, "regions") || Map.get(document, :regions) || [],
      sectors: Map.get(document, "sectors") || Map.get(document, :sectors) || [],
      sentiment_label: Map.get(document, "sentiment_label") || Map.get(document, :sentiment_label) || "neutral",
      metadata: Map.get(document, "metadata") || Map.get(document, :metadata) || %{}
    }
  end
end
