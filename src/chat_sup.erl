%%%-------------------------------------------------------------------
%%% @author  <hypet>
%%% @copyright (C) 2012, 
%%% @doc
%%%
%%% @end
%%% Created : 25 Nov 2012 by  <hypet>
%%%-------------------------------------------------------------------
-module(chat_sup).

-behaviour(supervisor).

%% API
-export([start_link/0,start_link/1]).

%% Supervisor callbacks
-export([init/1]).

% includes
-include("../include/chat.hrl").


start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

start_link(Args) ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, [Args]).

init([]) ->
    ChannelSup = [{chat_channel_sup, {chat_channel_sup, start_link, []},
                  permanent, 2000, supervisor, [chat_channel_sup]}],

    {ok, {{one_for_one, 10, 10}, ChannelSup}}.
