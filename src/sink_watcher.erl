-module(sink_watcher).
-export([start/0]).


start() ->
    SinkDir = "/apps/china_mobile_v2/sink",
    %% SinkDir = "/home/ddstone/hack/tweak/cmobile/erws",
    _Pid = spawn(fun() -> watch(SinkDir) end),
    ok.


watch(Path) ->
    {ok, _Wd} = fnotify:watch(Path),
    watch().


watch() ->
    receive
	{fevent, _, [create], Path, FN} ->
	    io:format("Got create"),
	    PicPath = filename:join([Path, FN]),
	    PyDir =  "/apps/china_mobile_v2/",
	    %% PyDir = "/home/ddstone/hack/tweak/cmobile/erws/src",
	    PyName = "sink_callback.py",
	    Cmd = lists:concat([
				"python",
				" ",
				filename:join([PyDir, PyName]),
				" ",
				PicPath
			       ]),
	    SinkResult = os:cmd(Cmd),
	    SinkFaceResult = parse_sink_result(string:tokens(SinkResult, "|"), []),
	    MaxIdx = element(2, hd(ets:lookup(sink_result, max_idx))),
	    insert2ets(MaxIdx, SinkFaceResult);
	_Other ->
	    ok
	    %% io:format("Unwanted fevent: ~w~n", [Other])
    end,
    watch().


insert2ets(MaxIdx, []) ->
    ets:insert(sink_result, {max_idx, MaxIdx});
insert2ets(MaxIdx, [Info | T]) ->
    Obj2Write = {
      list_to_atom(
	lists:concat(["sink_result", integer_to_list(MaxIdx)])
       ), 
      Info
     },
    ets:insert(sink_result, Obj2Write),

    insert2ets(MaxIdx + 1, T).



parse_sink_result([], Result) ->
    Result;
parse_sink_result([FaceInfo | T], Result) ->
    [AgeStr, GenStr, B64ImgStr] = string:tokens(FaceInfo, "-"),
    io:format("~s~n~s~n~w~n", [AgeStr, GenStr, length(B64ImgStr)]),
    parse_sink_result(T, [{AgeStr, GenStr, B64ImgStr} | Result]).
   


