%%%-------------------------------------------------------------------
%%% @author  <hypet>
%%% @copyright (C) 2012, 
%%% @doc
%%%
%%% @end
%%% Created : 25 Nov 2012 by  <hypet>
%%%-------------------------------------------------------------------
-module(chat_srv).

-behaviour(gen_server).

-include_lib("../deps/amqp_client/include/amqp_client.hrl").

%% API
-export([start_link/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-record(state, {channel, q_name, c_tag, hash}).

-define(SERVER,?MODULE).

%% @spec (string(),integer(),binary(),binary(),binary()) -> Result
%%         Result = {ok,pid()} | ignore | {error,Error}
%%          Error = {already_started,pid()} | term()
    
start_link(Hash) ->
    Name = list_to_atom("chat_srv_" ++ Hash),
    % Don't create new process if process Name is already exists.
    Pid = whereis(Name),
    case is_pid(Pid) of
        true -> Pid;
        false ->
            gen_server:start_link({local, Name}, ?MODULE, [Hash], [])
    end,
    {ok, #state{hash = Hash}}.

%% @doc Initialize. Open AMQP Connection and Channel.
%% Declare queue and bind it to an exchange. Start consuming messages from the queue.
%%
%% @spec ([term()]) -> Result
%%        Result = {ok,term ()} | ignore | {error, term()}
init([Hash]) ->
    Channel = gen_server:call(chat_amqp_srv, {get_channel}),
    QName = list_to_binary("q" ++ Hash),
    #'queue.declare_ok'{} =
        amqp_channel:call(Channel, #'queue.declare'{
                            queue = QName,
                            exclusive = false,
                            auto_delete = false}),

    #'basic.consume_ok'{consumer_tag = ConsumerTag} =
        amqp_channel:subscribe(Channel, 
                               #'basic.consume'{queue = QName,
                                                no_ack = true}, 
                               self()),
    State = #state{
                channel = Channel,
                q_name = QName,
                c_tag = ConsumerTag,
                hash = Hash},
    
    {ok, State}.


handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast({chat_msg, {From, _To, Payload}}, State) ->
    To = State#state.hash,
    Channel = State#state.channel,
    Qname = list_to_binary("q" ++ To),
    Msg = Payload,
    publish_msg(Channel, From, Qname, <<Msg/binary>>),
    {noreply, State};

handle_cast(_Msg, _State) ->
    {noreply, _State}.

%% @doc In gen_server handle_info/2 receives the subscribed messages
%%
%% @spec (InfoData::Data, #state{}) -> {noreply, #state{}}
%%        Data = Message | ConsumeOK | term()
%%         Message = {#'basic.deliver'{},#amqp_msg{}}
%%         ConsumeOK = #'basic.consume_ok'{}
handle_info(#'basic.consume_ok'{consumer_tag=Tag}, State) ->
    {noreply, State#state{c_tag=Tag}};

handle_info({#'basic.deliver'{},
              #amqp_msg{props = Props, payload = Payload}},
            State) ->
    #'P_basic'{reply_to = From} = Props,
    To = State#state.hash,
    gen_server:cast(chat_ws_srv, {chat_msg, From, To, Payload}),
    {noreply, State};

handle_info(Info, State) ->
    {noreply, State}.


terminate(_Reason, _State) ->
    %% #'channel.close_ok'{} = 
    %%     amqp_channel:call(Channel, 
    %%                       #'channel.close'{reply_code = 200,
    %%                                        reply_text = <<"Goodbye">>,
    %%                                        class_id = 0,
    %%                                        method_id = 0}),
    %% #'connection.close_ok'{} = 
    %%     amqp_connection:close(Connection,
    %%                       #'connection.close'{reply_code = 200,
    %%                                           reply_text = <<"Goodbye">>,
    %%                                             class_id = 0,
    %%                                            method_id = 0}),
    ok.


code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%--------------------------------------------------------------------
%%% Internal functions
%%--------------------------------------------------------------------

publish_msg(Channel, From, RoutingKey, Payload) ->
    Properties = #'P_basic'{
                            reply_to = case From == undefined of
                                           false -> list_to_binary(From);
                                           _ -> From
                                       end,         
                            delivery_mode = 2,
                            priority = 0},
    BasicPublish = #'basic.publish'{
                                    routing_key = RoutingKey,
                                    mandatory = false},
    Content = #amqp_msg{props = Properties, payload = Payload},
    amqp_channel:cast(Channel, BasicPublish, Content).
