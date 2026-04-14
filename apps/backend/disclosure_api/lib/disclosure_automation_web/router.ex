defmodule DisclosureAutomationWeb.Router do
  use DisclosureAutomationWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", DisclosureAutomationWeb do
    pipe_through :api

    get "/health", HealthController, :show

    get "/feed/hero", FeedController, :hero
    get "/feed/region/:region_code", FeedController, :region
    get "/events/:event_id", EventController, :show

    get "/feed/digest/latest", FeedDigestController, :latest
    get "/feed/digest/:digest_date/:edition", FeedDigestController, :show

    get "/admin/source-health", AdminSourceHealthController, :index
    get "/admin/source-health/:source_key", AdminSourceHealthController, :show
    post "/admin/source-health/:source_key/recheck", AdminSourceHealthController, :recheck

    post "/admin/sources/:source_key/poll", AdminSourcePollController, :create
  end
end
