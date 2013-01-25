%%%-------------------------------------------------------------------
%%% @author  <hypet>
%%% @copyright (C) 2013, 
%%% @doc
%%%
%%% @end
%%% Created : 26 Nov 2012 by  <hypet>
%%%-------------------------------------------------------------------
-module(chat_amqp_srv).

-behaviour(gen_server).

-include_lib("../deps/amqp_client/include/amqp_client.hrl").

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-define(SERVER, ?MODULE). 

-record(state, {connection, channel}).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
init([]) ->
    {ok, Host} = application:get_env(chat, server),
    {ok, Port} = application:get_env(chat, port),
    {ok, Uid} = application:get_env(chat, uid),
    {ok, Pwd} = application:get_env(chat, pwd),
    {ok, VHost} = application:get_env(chat, vhost),
    {ok, Connection} = amqp_connection:start(#amqp_params_network{virtual_host = VHost, host = Host, port = Port, username = Uid, password = Pwd}),
    {ok, Channel} = amqp_connection:open_channel(Connection),
    {ok, #state{connection = Connection, channel = Channel}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @spec handle_call(Request, From, State) ->
%%                                   {reply, Reply, State} |
%%                                   {reply, Reply, State, Timeout} |
%%                                   {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, Reply, State} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_call({get_channel}, _From, State) ->
    {reply, State#state.channel, State};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @spec handle_cast(Msg, State) -> {noreply, State} |
%%                                  {noreply, State, Timeout} |
%%                                  {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
terminate(_Reason, #state{channel = Channel, connection = Connection}) ->
    #'channel.close_ok'{} = 
        amqp_channel:call(Channel, 
                          #'channel.close'{reply_code = 200,
                                           reply_text = <<"Goodbye">>,
                                           class_id = 0,
                                           method_id = 0}),
    #'connection.close_ok'{} = 
        amqp_connection:close(Connection,
                          #'connection.close'{reply_code = 200,
                                              reply_text = <<"Goodbye">>,
                                                class_id = 0,
                                               method_id = 0}),
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
