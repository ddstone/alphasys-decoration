%%%-------------------------------------------------------------------
%%% @author ddstone
%%% @end
%%% Created : 11/04/2020
%%%-------------------------------------------------------------------
-module(sink_handler).

-export([init/3]).
-export([handle/2]).
-export([terminate/3]).

init(_Type, Req, []) ->
    {ok, Req, undefined}.

handle(Req, State) ->
    Req1 = cowboy_req:set_resp_header(<<"access-control-allow-origin">>, <<$*>>, Req),
    ProcessIdx = element(2, hd(ets:lookup(sink_result, latest_idx))),
    MaxIdx = element(2, hd(ets:lookup(sink_result, max_idx))),
    Result = get_next_data(ProcessIdx, MaxIdx),
    JsonResult = jiffy:encode(Result),
    {ok, Req2} = cowboy_req:reply(
		   200,
		   [{<<"content-type">>, <<"text/plain; charset=utf-8">>}],
		   JsonResult,
		   Req1
     ),
    {ok, Req2, State}.


terminate(_Reason, _Req, _State) ->
	ok.


get_next_data(ProcessIdx, ProcessIdx) ->
    {[{<<"result">>, <<"empty">>}]};
get_next_data(ProcessIdx, _MaxIdx) ->
    Key = list_to_atom(
	    lists:concat(["sink_result", integer_to_list(ProcessIdx)])
	   ),
    {AgeStr, GenStr, B64ImgStr} = element(2, hd(ets:lookup(sink_result, Key))),
    ets:delete(sink_result, Key),
    ets:insert(sink_result, {latest_idx, ProcessIdx + 1}),
    {[{<<"age">>, AgeStr}, {<<"gender">>, GenStr}, {<<"BinData">>, B64ImgStr}]}.

