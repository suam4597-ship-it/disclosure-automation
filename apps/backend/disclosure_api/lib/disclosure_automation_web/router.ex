defmodule DisclosureAutomationWeb.Router do
  use DisclosureAutomationWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :source_health_production_auth_context do
    plug DisclosureAutomationWeb.SourceHealthProductionAuthContext
  end

  pipeline :source_health_recheck_authorization do
    plug DisclosureAutomationWeb.SourceHealthRecheckAuthorization
  end

  pipeline :source_health_poll_authorization do
    plug DisclosureAutomationWeb.SourceHealthPollAuthorization
  end

  pipeline :browser do
    plug :accepts, ["html"]
  end

  scope "/admin", DisclosureAutomationWeb do
    pipe_through :browser

    get "/duplicate-groups", AdminDuplicateGroupUiController, :index
    get "/duplicate-groups/:group_id", AdminDuplicateGroupPermissionUiController, :show
  end

  scope "/admin", DisclosureAutomationWeb do
    pipe_through [:browser, :source_health_production_auth_context]

    get "/source-health", AdminSourceHealthUiController, :index
    get "/source-health/:source_key", AdminSourceHealthUiController, :show
  end

  scope "/api", DisclosureAutomationWeb do
    pipe_through :api

    get "/health", HealthController, :show

    get "/feed/hero", FeedController, :hero
    get "/feed/region/:region_code", FeedController, :region
    get "/events/:event_id/news-overlay", EventNewsOverlayController, :show
    get "/events/:event_id", EventController, :show

    get "/feed/digest/latest", FeedDigestController, :latest
    get "/feed/digest/:digest_date/:edition", FeedDigestController, :show

    get "/admin/duplicate-groups", AdminDuplicateGroupController, :index
    get "/admin/duplicate-groups/:group_id", AdminDuplicateGroupController, :show
    post "/admin/duplicate-groups/:group_id/confirm", AdminDuplicateGroupController, :confirm
    post "/admin/duplicate-groups/:group_id/reject", AdminDuplicateGroupController, :reject
    post "/admin/duplicate-groups/:group_id/mark-review", AdminDuplicateGroupController, :mark_review
    post "/admin/duplicate-groups/:group_id/clear-review-state", AdminDuplicateGroupController, :clear_review_state
  end

  scope "/api/admin/source-health", DisclosureAutomationWeb do
    pipe_through [:api, :source_health_production_auth_context]

    get "/", AdminSourceHealthController, :index
    get "/:source_key", AdminSourceHealthController, :show
  end

  scope "/api/admin/source-health", DisclosureAutomationWeb do
    pipe_through [:api, :source_health_production_auth_context, :source_health_recheck_authorization]

    post "/:source_key/recheck", AdminSourceHealthController, :recheck
  end

  scope "/api/admin/sources", DisclosureAutomationWeb do
    pipe_through [:api, :source_health_production_auth_context, :source_health_poll_authorization]

    post "/:source_key/poll", AdminSourcePollController, :create
  end
end
