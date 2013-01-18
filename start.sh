#!/bin/bash

make

export ERL_LIBS=".:deps/amqp_client:deps/rabbit_common:deps/misultin:deps/mochiweb:deps/Emysql"

erl -pa $PWD/ebin -I include -D log_debug -config sys -sname chat -boot start_sasl -s chat_app 
