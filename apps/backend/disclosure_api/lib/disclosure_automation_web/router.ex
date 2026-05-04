defmodule DisclosureAutomationWeb.Router do
  use DisclosureAutomationWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :source_health_recheck_authorization do
    plug DisclosureAutomationWeb.SourceHealthRecheckAuthorization
  end

  pipeline :browser do
    plug :accepts, ["html"]
  end

  scope "/admin", DisclosureAutomationWeb do
    pipe_through :browser

    get "/duplicate-groups", AdminDuplicateGroupUiController, :index
    get "/duplicate-groups/:group_id", AdminDuplicateGroupPermissionUiController, :show
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

    get "/admin/source-health", AdminSourceHealthController, :index
    get "/admin/source-health/:source_key", AdminSourceHealthController, :show

    get "/admin/duplicate-groups", AdminDuplicateGroupController, :index
    get "/admin/duplicate-groups/:group_id", AdminDuplicateGroupController, :show
    post "/admin/duplicate-groups/:group_id/confirm", AdminDuplicateGroupController, :confirm
    post "/admin/duplicate-groups/:group_id/reject", AdminDuplicateGroupController, :reject
    post "/admin/duplicate-groups/:group_id/mark-review", AdminDuplicateGroupController, :mark_review
    post "/admin/duplicate-groups/:group_id/clear-review-state", AdminDuplicateGroupController, :clear_review_state

    post "/admin/sources/:source_key/poll", AdminSourcePollController, :create
  end

  scope "/api/admin/source-health", DisclosureAutomationWeb do
    pipe_through [:api, :source_health_recheck_authorization]

    post "/:source_key/recheck", AdminSourceHealthController, :recheck
  end
end
