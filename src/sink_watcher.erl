-module(sink_watcher).
-export([start/1]).


start(Path) ->
    _Pid = spawn(fun() -> watch(Path) end),
    ok.


watch(Path) ->
    {ok, _Wd} = fnotify:watch(Path),
    watch().


watch() ->
    receive
	{fevent, _, [create], Path, FN} ->
	    PicPath = filename:join([Path, FN]),
	    %% PyDir =  "/apps/china_mobile_v2/",
	    PyDir = "/home/ddstone/hack/tweak/cmobile/erws/src",
	    PyName = "sink_callback.py",
	    Cmd = lists:concat([
				"python",
				" ",
				filename:join([PyDir, PyName]),
				" ",
				PicPath
			       ]),
	    os:cmd(Cmd);
	_Other ->
	    ok
	    %% io:format("Unwanted fevent: ~w~n", [Other])
    end,
    watch().
