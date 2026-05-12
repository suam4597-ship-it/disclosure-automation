FROM elixir:1.18-slim AS build

RUN apt-get update -y && apt-get install -y build-essential git && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV MIX_ENV=prod

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs ./
RUN mix deps.get --only prod

COPY config ./config
COPY lib ./lib
COPY priv ./priv

RUN mix deps.compile
RUN mix compile
RUN mix release

FROM debian:trixie-slim AS app

RUN apt-get update -y && apt-get install -y openssl libstdc++6 ca-certificates ncurses-bin && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV MIX_ENV=prod
ENV PHX_SERVER=true

COPY --from=build /app/_build/prod/rel/disclosure_automation ./
COPY --from=build /app/priv ./priv

CMD ["/app/bin/disclosure_automation", "start"]
