PROJECT = emqx_auth_pgsql
PROJECT_DESCRIPTION = EMQ X Authentication/ACL with PostgreSQL
PROJECT_VERSION = 3.0

DEPS = epgsql ecpool clique emqx_passwd

dep_epgsql = git-emqx https://github.com/epgsql/epgsql 4.1.0
dep_ecpool = git-emqx https://github.com/emqx/ecpool v0.3.0
dep_clique = git-emqx https://github.com/emqx/clique v0.3.11
dep_emqx_passwd = git-emqx https://github.com/emqx/emqx-passwd v1.0

BUILD_DEPS = emqx cuttlefish
dep_emqx = git-emqx https://github.com/emqx/emqx master
dep_cuttlefish = git-emqx https://github.com/emqx/cuttlefish v2.2.0

NO_AUTOPATCH = cuttlefish

ERLC_OPTS += +debug_info

TEST_DEPS = emqx_auth_username
dep_emqx_auth_username = git-emqx https://github.com/emqx/emqx-auth-username master

TEST_ERLC_OPTS += +debug_info

COVER = true

$(shell [ -f erlang.mk ] || curl -s -o erlang.mk https://raw.githubusercontent.com/emqx/erlmk/master/erlang.mk)
include erlang.mk

app:: rebar.config

app.config::
	./deps/cuttlefish/cuttlefish -l info -e etc/ -c etc/emqx_auth_pgsql.conf -i priv/emqx_auth_pgsql.schema -d data

