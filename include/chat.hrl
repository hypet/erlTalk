% ============================ \/ LOG ======================================================================
-ifdef(log_debug).
-define(LOG_DEBUG(Str, Args), erlang:apply(error_logger, info_msg, [lists:concat(["[DEBUG]	pid: ", pid_to_list(self()), "~n	module: ", ?MODULE, "~n	line: ", ?LINE, "~n", Str, "~n"]), Args])).
-define(LOG_INFO(Str, Args), erlang:apply(error_logger, info_msg, [lists:concat(["	module: ", ?MODULE, "~n	line: ", ?LINE, "~n", Str, "~n"]), Args])).
-define(LOG_WARNING(Str, Args), erlang:apply(error_logger, warning_msg, [lists:concat(["	module: ", ?MODULE, "~n	line: ", ?LINE, "~n", Str, "~n"]), Args])).
-define(LOG_ERROR(Str, Args), erlang:apply(error_logger, error_msg, [lists:concat(["	module: ", ?MODULE, "~n	line: ", ?LINE, "~n", Str, "~n"]), Args])).
-else.
-ifdef(log_info).
-define(LOG_DEBUG(Str, Args), ok).
-define(LOG_INFO(Str, Args), erlang:apply(error_logger, info_msg, [lists:concat(["	module: ", ?MODULE, "~n	line: ", ?LINE, "~n", Str, "~n"]), Args])).
-define(LOG_WARNING(Str, Args), erlang:apply(error_logger, warning_msg, [lists:concat(["	module: ", ?MODULE, "~n	line: ", ?LINE, "~n", Str, "~n"]), Args])).
-define(LOG_ERROR(Str, Args), erlang:apply(error_logger, error_msg, [lists:concat(["	module: ", ?MODULE, "~n	line: ", ?LINE, "~n", Str, "~n"]), Args])).
-else.
-ifdef(log_error).
-define(LOG_DEBUG(Str, Args), ok).
-define(LOG_INFO(Str, Args), ok).
-define(LOG_WARNING(Str, Args), ok).
-define(LOG_ERROR(Str, Args), erlang:apply(error_logger, error_msg, [lists:concat(["	module: ", ?MODULE, "~n	line: ", ?LINE, "~n", Str, "~n"]), Args])).
-else.
% default to warning level
-define(LOG_DEBUG(Str, Args), ok).
-define(LOG_INFO(Str, Args), ok).
-define(LOG_WARNING(Str, Args), erlang:apply(error_logger, warning_msg, [lists:concat(["	module: ", ?MODULE, "~n	line: ", ?LINE, "~n", Str, "~n"]), Args])).
-define(LOG_ERROR(Str, Args), erlang:apply(error_logger, error_msg, [lists:concat(["	module: ", ?MODULE, "~n	line: ", ?LINE, "~n", Str, "~n"]), Args])).
-endif.
-endif.
-endif.
% ============================ /\ LOG ======================================================================

-record(contact_rec, {name, login, email, hash}).
-record(hash_rec, {hash}).
