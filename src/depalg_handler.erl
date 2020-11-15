%%%-------------------------------------------------------------------
%%% @author ddstone
%%% @end
%%% Created : 11/04/2020
%%%-------------------------------------------------------------------
-module(depalg_handler).

%%
%% Cowboy callbacks
-export([init/3, handle/2, terminate/3]).

%%============================================================================
%% API
%%============================================================================
	 

init(_Transport, Req, []) ->
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
    deploy1(JsonVal, Req2);
deploy(<<"POST">>, false, Req) ->
    Result = {<<"result">>, <<"Missing Body">>},
    JsonResult = jiffy:encode(Result),
    cowboy_req:reply(400, [], JsonResult, Req);
deploy(_, _, Req) ->  %% Method not allowed
    cowboy_req:reply(405, Req).

deploy1(undefined, Req) ->
    %% Result = {[{<<"result">>, <<"Missing net_conf">>}]},
    %% JsonResult = jiffy:encode(Result),
    cowboy_req:reply(400, [], Req);
deploy1(JsonVal, Req) ->
    SuccessResult = {[{<<"deploy_algo_result">>, <<"success">>}]},
    % FailResult = {[{<<"deploy_algo_result">>, <<"failed">>}]},
    ok = write_file(JsonVal),
    JsonResult = jiffy:encode(SuccessResult),
    cowboy_req:reply(
      200,
      [{<<"content-type">>, <<"text/plain; charset=utf-8">>}],
      JsonResult,
      Req
     ).

write_file([JsonVal]) ->
    Path = hd([
	       element(2, X) || X <- JsonVal, 
				element(1, X) == <<"path">>
	      ]),
    BinFile = hd([
		  element(2, X) || X <- JsonVal,
				   element(1, X) == <<"file">>
		 ]),
    file:write_file(Path, BinFile).
