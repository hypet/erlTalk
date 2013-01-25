#!/bin/bash

make

export ERL_LIBS=".:../erlTalk:deps/amqp_client:deps/rabbit_common:deps/misultin:deps/mochiweb:deps/emysql"

erl -pa $PWD/ebin -I include -name erltalk@127.0.0.1 -sname erltalk -boot start_sasl -s chat_app -sasl errlog_type error -config sys
