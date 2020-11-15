%%%-------------------------------------------------------------------
%%% @author ddstone
%%% @end
%%% Created : 11/04/2020
%%%-------------------------------------------------------------------
-module(depenv_handler).

%%
%% Cowboy callbacks
-export([init/3, handle/2, terminate/3]).

%%============================================================================
%% API
%%============================================================================
	 

init(_Transport, Req, []) ->
    io:format("lol-1~n"),
    {ok, Req, undefined}.

handle(Req, State) ->
    Req1 = cowboy_req:set_resp_header(<<"access-control-allow-origin">>, <<$*>>, Req),
    {Method, Req2} = cowboy_req:method(Req1),
    HasBody = cowboy_req:has_body(Req2),
    {ok, Req3} = deploy(Method, HasBody, Req2),
    {ok, Req3, State}.

terminate(_Reason, _Req, _State) ->
    ok.


%%============================================================================
%% Internal functions
%%============================================================================

deploy(<<"POST">>, true, Req) ->
    {ok, PostVals, Req2} = cowboy_req:body_qs(Req),
    JsonVal = jiffy:decode(element(1, hd(PostVals))),
    JsonDepVal = element(2, hd(element(1, JsonVal))),
    JsonDepVal1 = lists:map(
        fun(X) -> element(1, X) end, JsonDepVal
    ),
    deploy1(JsonDepVal1, Req2);
deploy(<<"POST">>, false, Req) ->
    Result = {<<"result">>, <<"Missing Body">>},
    JsonResult = jiffy:encode(Result),
    cowboy_req:reply(400, [], JsonResult, Req);
deploy(_, _, Req) ->  %% Method not allowed
    cowboy_req:reply(405, Req).

deploy1(undefined, Req) ->
    Result = {[{<<"result">>, <<"Missing key: deploy_env">>}]},
    JsonResult = jiffy:encode(Result),
    cowboy_req:reply(400, [{<<"content-type">>, <<"text/plain; charset=utf-8">>}], JsonResult, Req);
deploy1(JsonNetConf, Req) ->
    SuccessResult = {[{<<"deploy_enve_result">>, <<"success">>}]},
    %% FailResult = {[{<<"deploy_enve_result">>, <<"failed">>}]},
    ok = dep_via_py(JsonNetConf),
    JsonResult = jiffy:encode(SuccessResult),
    %% JsonResult = jiffy:encode(FailResult),
    cowboy_req:reply(
      200,
      [{<<"content-type">>, <<"text/plain; charset=utf-8">>}],
      JsonResult,
      Req
     ).

dep_via_py(JsonNetConf) ->
    Infos = parse_info(JsonNetConf, []),
    WorkDir = "/home/ddstone/hack/tweak/cmobile/erws",
    FileNames = ["./sto_hosts", "./sorany_hosts"],
    FilePathes = lists:map(
		   fun(FN) -> filename:join([WorkDir, FN]) end,
		   FileNames
		  ),
    lists:foreach(fun(FN) -> depViaBash(Infos, FN) end, FilePathes).


depViaBash([], _FN) ->
    ok;
depViaBash([{Name, IP} | T], FN) ->
    %% Prefix = "/apps/china_mobile_v2/",
    Prefix = "/home/ddstone/hack/tweak/cmobile/bashes",
    BashName = "update_net_conf.sh",
    Cmd = lists:concat([
			"sh", 
			" ",
			filename:join([Prefix, BashName]),
			" ",
			Name,
			" ",
			IP
		       ]),
    os:cmd(Cmd),
    depViaBash(T, FN).



parse_info([], Result) ->
    Result;
parse_info([Conf | T], Result) ->
    Ip = hd([element(2, X) || X <- Conf, element(1, X) == <<"ip">>]),
    Name = hd([element(2, X) || X <- Conf, element(1, X) == <<"name">>]),
    parse_info(T, [{Ip, Name} | Result]).
