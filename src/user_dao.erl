%%%-------------------------------------------------------------------
%%% @author  <hypet>
%%% @copyright (C) 2012, 
%%% @doc
%%%
%%% @end
%%% Created : 17 Dec 2012 by  <hypet>
%%%-------------------------------------------------------------------
-module(user_dao).

%% API
-export([save_user/1, get_user/0, check_credentials/1, refresh_last_access/1, 
         get_contacts/0,
         get_user_by_email/1, get_user_by_login/1]).

-record(user_rec, {name, login, email, password}).
-record(count_rec, {amount}).

% includes
-include("../include/chat.hrl").

%%%===================================================================
%%% API
%%%===================================================================

save_user([]) ->
    bad_arg;

save_user([Username, Login, Email, Password]) ->
    Hash = compute_hash(Email),
    Statement = io_lib:format(
                  "INSERT INTO user (login, name, email, `password`, `hash`) VALUES ('~s', '~s', '~s', md5('~s'), '~s')",
                  [Login, Username, Email, Password, Hash]),
    exec_sql(Statement),
    {ok, Hash}.

get_user() ->
    Statement = io_lib:format("SELECT name, login, email, `password` FROM user",
                              []),
    query_sql(Statement).

get_contacts() ->
    Statement = io_lib:format("SELECT name, login, email, hash FROM user",
                              []),
    Result = emysql:execute(p1, Statement),
    emysql_util:as_record(Result, contact_rec, record_info(fields, contact_rec)).

get_user_by_login(Login) ->
    Statement = io_lib:format("SELECT COUNT(1) as amount FROM user WHERE login='~s'",
                              [Login]),
    Result = emysql:execute(p1, Statement),
    Recs = emysql_util:as_record(Result, count_rec, record_info(fields, count_rec)),
    [{count_rec, Count}] = Recs,
    Count > 0.

get_user_by_email(Email) ->
    Statement = io_lib:format("SELECT COUNT(1) as amount FROM user WHERE email='~s'",
                              [Email]),
    Result = emysql:execute(p1, Statement),
    Recs = emysql_util:as_record(Result, count_rec, record_info(fields, count_rec)),
    [{count_rec, Count}] = Recs,
    Count > 0.

check_credentials([]) ->
    bad_arg;

check_credentials([Login, Password]) ->
    Statement = io_lib:format("SELECT hash FROM user WHERE login='~s' AND password=md5('~s')",
                              [Login, Password]),
    Result = emysql:execute(p2, Statement),
    emysql_util:as_record(Result, hash_rec, record_info(fields, hash_rec)).
    
refresh_last_access(Login) ->
    Statement = io_lib:format(
                  "UPDATE user SET lastAccess=NOW() WHERE login='~s'",
                  [Login]),
    io:format("~s~n", [Statement]),
    exec_sql(Statement).
    

%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------

%%%===================================================================
%%% Internal functions
%%%===================================================================

exec_sql(Statement) ->
    emysql:execute(p1, Statement).

query_sql(Statement) ->
    Result = emysql:execute(p2, Statement),
    emysql_util:as_record(Result, user_rec, record_info(fields, user_rec)).
    
compute_hash(Email) ->
    {_Mega, Secs, Micro} = erlang:now(),
    Data = list_to_binary(Email ++ integer_to_list(Secs * Micro)),
    mochihex:to_hex(crypto:md5(Data)).
