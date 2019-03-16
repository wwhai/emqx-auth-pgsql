%% Copyright (c) 2013-2019 EMQ Technologies Co., Ltd. All Rights Reserved.
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.

-module(emqx_auth_pgsql).

-include("emqx_auth_pgsql.hrl").

-include_lib("emqx/include/emqx.hrl").

-export([check/2, description/0]).

-record(state, {auth_query, super_query, hash_type}).

-define(UNDEFINED(S), (S =:= undefined orelse S =:= <<>>)).

%%--------------------------------------------------------------------
%% Auth Module Callbacks
%%--------------------------------------------------------------------

check(Credentials = #{username := Username, password := Password}, _State)
    when ?UNDEFINED(Username); ?UNDEFINED(Password) ->
    {ok, Credentials#{result => username_or_password_undefined}};

check(Credentials = #{password := Password}, #state{auth_query  = {AuthSql, AuthParams},
                                                   super_query = SuperQuery,
                                                   hash_type   = HashType}) ->
    CheckPass = case emqx_auth_pgsql_cli:equery(AuthSql, AuthParams, Credentials) of
                    {ok, _, [Record]} ->
                        check_pass(erlang:append_element(Record, Password), HashType);
                    {ok, _, []} ->
                        {error, not_found};
                    {error, Reason} ->
                        logger:error("Pgsql query '~p' failed: ~p", [AuthSql, Reason]),
                        {error, not_found}
                end,
    case CheckPass of
        ok -> {stop, Credentials#{is_superuser => is_superuser(SuperQuery, Credentials),
                                  result => success}};
        {error, not_found} -> ok;
        {error, ResultCode} ->
            logger:error("Auth from pgsql failed: ~p", [ResultCode]),
            {stop, Credentials#{result => ResultCode}}
    end;
check(Credentials, Config) ->
    ResultCode = insufficient_credentials,
    logger:error("Auth from pgsql failed: ~p, Configs: ~p", [ResultCode, Config]),
    {ok, Credentials#{result => ResultCode}}.

%%--------------------------------------------------------------------
%% Is Superuser?
%%--------------------------------------------------------------------

-spec(is_superuser(undefined | {string(), list()}, emqx_types:credentials()) -> boolean()).
is_superuser(undefined, _Credentials) ->
    false;
is_superuser({SuperSql, Params}, Credentials) ->
    case emqx_auth_pgsql_cli:equery(SuperSql, Params, Credentials) of
        {ok, [_Super], [{true}]} ->
            true;
        {ok, [_Super], [_False]} ->
            false;
        {ok, [_Super], []} ->
            false;
        {error, _Error} ->
            false
    end.

check_pass(Password, HashType) ->
    case emqx_passwd:check_pass(Password, HashType) of
        ok -> ok;
        {error, _Reason} -> {error, not_authorized}
    end.

description() -> "Authentication with PostgreSQL".
