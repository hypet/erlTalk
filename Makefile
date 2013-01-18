REBAR_CONFIG:=$(PWD)/rebar.config
INCLUDE_DIR:=include
SRC_DIR:=src

compile: clean
	@./rebar compile

clean:
	@./rebar clean
	@find $(PWD)/. -name "erl_crash\.dump" | xargs rm -f
