-module(erws_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    Dispatch = cowboy_router:compile([
      {'_', [
        % {"/", cowboy_static, {priv_file, erws, "index.html"}},
        % {"/websocket", erws_handler, []},
	{"/", toppage_handler, []},
	{"/deployment", depenv_handler, []},
	{"/deployalgo", depalg_handler, []}
      ]}
    ]),
    {ok, _} = cowboy:start_http(http, 100, [{port, 10100}],
        [{env, [{dispatch, Dispatch}]}]),
    
    %% SinkDir = "/apps/china_mobile_v2/sink",
    SinkDir = "/home/ddstone/hack/tweak/cmobile/erws",
    ok = sink_watcher:start(SinkDir),
    erws_sup:start_link().

stop(_State) ->
    ok.
