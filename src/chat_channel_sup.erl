-module(chat_channel_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

% includes
-include("../include/chat.hrl").

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    Chat = [{chat_srv, {chat_srv, start_link, []},
            temporary, 2000, worker, [chat_srv]}],
    {ok, {{simple_one_for_one, 10, 60}, Chat}}.

