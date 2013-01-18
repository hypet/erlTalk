%%%-------------------------------------------------------------------
%%% @author  <hypet>
%%% @copyright (C) 2012, 
%%% @doc
%%%
%%% @end
%%% Created : 26 Nov 2012 by  <hypet>
%%%-------------------------------------------------------------------
-module(chat_app).

-behaviour(application).

-export([start/0, start/2, stop/1]).

% includes
-include("../include/chat.hrl").

start() ->
    application:set_env(emysql, pools, [
                {p1, [
                  {size, 2},
                  {host, "localhost"},
                  {port, 3306},
                  {encoding, 'utf8'},
                  {user, "root"},
                  {password, ""},
                  {database, "chat"}
                 ]},
                {p2, [
                  {size, 3},
                  {host, "localhost"},
                  {port, 3306},
                  {encoding, 'utf8'},
                  {user, "root"},
                  {password, ""},
                  {database, "chat"}
                 ]}
    ]),
%    appmon:start(),
    crypto:start(),
    application:start(emysql),
    application:start(chat).

start(_Type, _StartArgs) ->
    WorkDir = filename:dirname(code:which(?MODULE)),
    Options = [
               {sessions_expire, 3600*12},
               {port, 8088},
               {static, [WorkDir ++ "/../priv/px/faces"]},
               {loop, fun(Req) -> chat_ws_srv:handle_http(Req) end},
               {ws_loop, fun(Ws) -> chat_ws_srv:handle_websocket(Ws) end}
              ],
    chat_db_sup:start_link(),
    chat_amqp_sup:start_link(),
    chat_ws_sup:start_link(Options),
    chat_dict_sup:start_link(),
    chat_sup:start_link().

stop(_State) ->
    ok.
