%%%-------------------------------------------------------------------
%%% @author  <hypet>
%%% @copyright (C) 2012, 
%%% @doc
%%%
%%% @end
%%% Created : 25 Nov 2012 by  <hypet>
%%%-------------------------------------------------------------------
-module(chat_ws_sup).
-behaviour(supervisor).

% API
-export([start_link/1]).

% supervisor callbacks
-export([init/1]).

% ============================ \/ API =============================================================

% -------------------------------------------------------------------------------------------------
% Function: start_link() -> {ok,Pid} | ignore | {error,Error}
% Description: Starts the supervisor
% --------------------------------------------------------------------------------------------------
start_link(Options) ->
	supervisor:start_link(?MODULE, [Options]).
	
% ============================ /\ API =============================================================


% ============================ \/ SUPERVISOR CALLBACKS =============================================

% -------------------------------------------------------------------------------------------------
% Function: -> {ok,  {SupFlags,  [ChildSpec]}} | ignore | {error, Reason}
% Description: Starts the supervisor
% -------------------------------------------------------------------------------------------------
init([Options]) ->
	% misultin specs
	MisultinSpecs = {misultin,
		{misultin, start_link, [Options]},
		permanent, infinity, supervisor, [misultin]
	},	
	% application gen server specs
	ServerSpecs = {chat_ws_srv,
		{chat_ws_srv, start_link, []},
		permanent, 60000, worker, [chat_ws_srv]
	},
	% spawn
	{ok, {{one_for_all, 5, 30}, [MisultinSpecs, ServerSpecs]}}.

% ============================ /\ SUPERVISOR CALLBACKS ============================================


