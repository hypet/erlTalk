%%%-------------------------------------------------------------------
%%% @author  <hypet>
%%% @copyright (C) 2012, 
%%% @doc
%%%
%%% @end
%%% Created : 25 Nov 2012 by  <hypet>
%%%-------------------------------------------------------------------
-module(chat_ws_srv).
-behaviour(gen_server).

% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

% API
-export([start_link/0, handle_http/1, handle_websocket/1]).

%-record(state, {ws}).

% includes
-include("../include/chat.hrl").

% ============================ \/ API =============================================================

% Function: {ok,Pid} | ignore | {error, Error}
% Description: Starts the server.
start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

% ============================ /\ API =============================================================


% ============================ \/ GEN_SERVER CALLBACKS ============================================

% --------------------------------------------------------------------------------------------------
% Function: -> {ok, State} | {ok, State, Timeout} | ignore | {stop, Reason}
% Description: Initiates the server.
% -------------------------------------------------------------------------------------------------
init([]) ->
	{ok, {}}.

handle_call(_Message, _From, State) ->
	{reply, error, State}.

handle_cast({chat_msg, From, To, Msg}, State) ->
    {ok, Ws} = gen_server:call(chat_dict_srv, {find, To}),
    Json = {struct, [{t, <<"msg">>}, {p, [{body, Msg}, {from, From}]}]},
    Message = binary_to_list(iolist_to_binary(mochijson2:encode(Json))),
    Ws:send(Message),
    {noreply, State};

handle_cast({send_contacts, Contacts, To}, State) ->
    {ok, Ws} = gen_server:call(chat_dict_srv, {find, To}),
    ContactList = lists:map(fun({contact_rec, Name, Login, _Email, Hash}) -> 
                                   [{l, Login}, {n, Name}, {h, Hash}] 
                                end,
                                Contacts),
    Json = {struct, [{t, <<"contacts">>}, {p, ContactList}]},
    Message = binary_to_list(iolist_to_binary(mochijson2:encode(Json))),
    Ws:send(Message),
    {noreply, State}.

% handle_info generic fallback (ignore)
handle_info(_Msg, State) ->
	{noreply, State}.

% -------------------------------------------------------------------------------------------------
% Function: terminate(Reason, State) -> void()
% Description: This function is called by a gen_server when it is about to terminate. When it returns,
% the gen_server terminates with Reason. The return value is ignored.
% -------------------------------------------------------------------------------------------------
terminate(_Reason, _State) ->
	terminated.

% -------------------------------------------------------------------------------------------------
% Func: code_change(OldVsn, State, Extra) -> {ok, NewState}
% Description: Convert process state when code is changed.
% -------------------------------------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
	{ok, State}.

% ============================ /\ GEN_SERVER CALLBACKS ============================================


% ============================ \/ INTERNAL FUNCTIONS ==============================================

% ---------------------------- \/ misultin requests -----------------------------------------------

% ---------------------------- \/ GET  -----------------------------------------------

handle_http(Req) ->
	% dispatch to rest
	handle(Req:get(method), Req:resource([lowercase, urldecode]), Req).

handle('GET', [], Req) -> 
    % get session info
    {_SessionId, SessionState} = Req:session(),
    % check state
    case SessionState of
        [] ->
            Req:file("priv/login.html");
        [{hash, _Hash}, {addr, _Addr}] ->
            Req:file("priv/index.html"),
            send_contact_delivery_update()
	end;

handle('GET', ["login"], Req) -> 
    Req:file("priv/login.html");

handle('GET', ["logout"], Req) -> 
    {SessionId, _SessionState} = Req:session(),
    Req:save_session_state(SessionId, []),
    %%%%%%%%%%%%%%%%% Kill misultin processes
    Req:file("priv/login.html");

handle('GET', ["register"], Req) -> 
    Req:file("priv/login.html");

handle('GET', ["faces"], Req) ->
    Path = get_destination_path() ++ "/../priv/px/faces/",
    Files = filelib:wildcard("*.*", Path),
    FileList = lists:map(fun(File) -> list_to_binary(File) end, Files),
    Req:ok([{"Content-Type", "application/json"}], 
    binary_to_list(iolist_to_binary(mochijson2:encode(FileList))));

handle('GET', ["index.html"], Req) -> 
    Req:file("priv/index.html");

% ---- Mobile

handle('GET', ["m", "index.html"], Req) -> 
    Req:file("priv/mobile/index.html");


% ---------------------------- /\ GET  -----------------------------------------------
% ---------------------------- \/ POST  -----------------------------------------------

handle('POST', ["auth"], Req) -> 
    % get session info
    {SessionId, _SessionState} = Req:session(),
    Args = Req:parse_post(unicode),
    case parse_credentials(Args) of
        [Login, Password] when erlang:length(Login) > 2, erlang:length(Password) > 2 ->
            case user_dao:check_credentials([Login, Password]) of
                [{hash_rec, BinHash}] ->
                    Hash = binary_to_list(BinHash),
                    user_dao:refresh_last_access(Login),
                    user_login_ok(Req, Hash, SessionId, Login);
                _ ->
                    Req:redirect("/login")
            end;
        undefined ->
            Req:redirect("/login");
        empty_list ->
            Req:redirect("/login")
    end;

handle('POST', ["register"], Req) -> 
    % get session info
    {SessionId, _SessionState} = Req:session(),
    Args = Req:parse_post(unicode),
    case parse_registration_data(Args) of
        [Username, Login, Email, Password] when erlang:length(Login) > 2 ->
            case user_dao:save_user([Username, Login, Email, Password]) of
                {ok, Hash} ->
                    user_login_ok(Req, Hash, SessionId, Login);
                _ ->
                    Req:redirect("/login")
            end;
        undefined ->
            Req:redirect("/login");
        empty_list ->
            Req:redirect("/login")
    end;

% ---------------------------- /\ POST  -----------------------------------------------

% ---------------------------- \/ CSS  -----------------------------------------------

handle('GET', ["css", "app.css"], Req) -> 
    Req:file("priv/css/app.css");

handle('GET', ["css", "bootstrap.css"], Req) -> 
    Req:file("priv/css/bootstrap.css");

% ---------------------------- /\ CSS  -----------------------------------------------

% ---------------------------- \/ JS libs  -----------------------------------------------

handle('GET', ["js", "app.js"], Req) -> 
    Req:file("priv/js/app.js");

% ---------------------------- /\ JS libs -----------------------------------------------

handle('POST', [], Req) -> 
    case Req:parse_post() of
		[{_Tag, Attributes, FileData}] ->
			% build destination file path
			DestPath = get_destination_path(),
			FileName = misultin_utility:get_key_value("filename", Attributes),
			DestFile = filename:join(DestPath, FileName),
			% save file
			case file:write_file(DestFile, FileData) of
				ok ->
					Req:ok(["File has been successfully saved to \"", DestFile, "\"."]);
				{error, _Reason} ->
					Req:respond(500)
			end;
		_ ->
			Req:respond(500)
	end;

% handle the 404 page not found
handle(_, _, Req) ->
	Req:ok([{"Content-Type", "text/plain"}], "Page not found.").

% callback on received websockets data
handle_websocket(Ws) ->
    {_SessionId, SessionState} = Ws:session(),
	receive
		{browser, Data} ->
            case string:tokens(Data, ":") of
                [Login, _Key, _SessionKey, Hash] when length(Login) > 2, length(Hash) > 1 -> 
                    gen_server:call(chat_dict_srv, {add, Hash, Ws}),
                    send_contact_delivery_update();
                _ ->
                    UserName = proplists:get_value(hash, SessionState),
                    io:format("UserName: ~p~n", [UserName]),
                    process_message(Data, UserName)
            end,
            io:format("Tokens: ~p~n", [string:tokens(Data, ":")]),
            io:format("Data: ~p~n", [Data]),
			handle_websocket(Ws);
		_Ignore ->
			handle_websocket(Ws)
	end.


% ---------------------------- /\ misultin requests -----------------------------------------------

% ============================ /\ INTERNAL FUNCTIONS ==============================================

% {"a" : "msg", "p" : [{"body" : "hello"}, {"from" : "name"}]}
% {"a" : "get_contacts"}
process_message(Data, From) ->
    {struct, Msg} = mochijson2:decode(Data),
    Action = proplists:get_value(<<"a">>, Msg),
    case Action of
        <<"get_contacts">> ->
            Contacts = user_dao:get_contacts(),
            % From == To
            gen_server:cast(chat_ws_srv, {send_contacts, Contacts, From});
        <<"msg">> ->
            {struct, Payload} = proplists:get_value(<<"p">>, Msg),
            To = binary_to_list(proplists:get_value(<<"to">>, Payload)),
            Body = proplists:get_value(<<"body">>, Payload),
            gen_server:cast(list_to_atom("chat_srv_" ++ To), {chat_msg, {From, To, Body}});
        _ -> undefined
    end.

% gets the destination path
get_destination_path() ->
	filename:dirname(code:which(?MODULE)).

create_queue(User) ->
    supervisor:start_child(chat_channel_sup, chat_srv:start_link(User)).

parse_credentials([{"password", _, Password},{"login", _, Login}]) ->
    [binary_to_list(Login), binary_to_list(Password)];

parse_credentials([{"password", Password},{"login", Login}]) ->
    [Login, Password];

parse_credentials([{"login", Login},{"password", Password}]) ->
    [Login, Password];

parse_credentials([]) ->
    empty_list.
    

parse_registration_data([{"username", Username},
                         {"login", Login},
                         {"email", Email},
                         {"password", Password},
                         {"password2", _}]) ->
    [Username, Login, Email, Password];
    
parse_registration_data([]) ->
    empty_list.

user_login_ok(Req, Hash, SessionId, Login) ->
    Req:set_cookie("key", mochihex:to_hex(crypto:rand_bytes(16))),
    Req:set_cookie("login", Login),
    Req:set_cookie("hash", Hash),
    Req:save_session_state(SessionId, [{hash, Hash}, {addr, Req:get(peer_addr)}]),
    create_queue(Hash),
    Req:redirect("/").

send_contact_delivery_update() ->
    Contacts = user_dao:get_contacts(),
    Recipients = gen_server:call(chat_dict_srv, {find_all}),
    [gen_server:cast(chat_ws_srv, {send_contacts, Contacts, Recipient}) || Recipient <- Recipients].
    