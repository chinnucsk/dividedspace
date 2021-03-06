-module(ds_web_api_shiptype).

-export([
	 get_sub_handler/3,
	 delete/2,
	 forbidden/3,
	 create/3,
	 exists/2,
	 list_resources/1,
	 list_resources_for_parent/2,
	 get_data/2,
	 get_owner/2,
	 put_data/3]).

%% Implementation


get_sub_handler(Parents, This, [<<"module">>]) ->
    {[{shiptype, This} | Parents], ds_web_api_module, undefined};

get_sub_handler(Parents, This, [<<"module">>, Id]) ->
    {[{shiptype, This} | Parents], ds_web_api_module, list_to_integer(binary_to_list(Id))};

get_sub_handler([Parents], This, []) ->
    {[Parents], ds_web_api_shiptype, This}.

delete(Db, Id) ->
    R = pgsql:equery(Db, "DELETE FROM shiptypes WHERE id = $1", [Id]),
    case R of
	{ok, 1} ->
	    true;
	{ok, 0} ->
	    false;
	_Error -> 
	    false
    end.

forbidden(Db, Id, UId) ->
    case pgsql:equery(Db, "SELECT user_id FROM shiptypes WHERE id = $1", [Id]) of
	{ok, _, [{UId}]} -> 
	    true;
	{ok, _, []} ->
	    true
    end.

exists(Db, Id) ->
    case pgsql:equery(Db, "SELECT count(*) FROM shiptypes WHERE id = $1", [Id]) of
	{ok, _, [{1}]} ->
	    true;
	_ -> 
	    false
    end.

create(Db, UId, [{user, UId}]) ->
    {ok, _, _, [{TypeId}]} =
	pgsql:equery(Db, "INSERT INTO shiptypes (user_id) VALUES ($1) RETURNING id", [UId]),
    Location = list_to_binary(io_lib:format("~p", [TypeId])),
    UIdStr = list_to_binary(io_lib:format("~p", [UId])),
    {<<"/api/v1/user/", UIdStr/binary, "/shiptype/", Location/binary>>, TypeId}.


%%Internal


list_resources(Db) ->
    {ok, _, SIds} =
	pgsql:equery(Db, "SELECT id, name FROM shiptypes"),
    List = lists:map(fun ({Id, Name}) ->
			     [{<<"id">>, Id},
			      {<<"name">>, Name}]
		     end, SIds),
    {ok, List}.

list_resources_for_parent(Db, [{user, UId}]) ->
    {ok, _, SIds} =
	pgsql:equery(Db, "SELECT id, name FROM shiptypes WHERE user_id = $1", [UId]),
    List = lists:map(fun ({Id, Name}) ->
			     [{<<"id">>, Id},
			      {<<"name">>, Name}]
		     end, SIds),
    {ok ,List}.

get_owner(Db, Id) ->
    {ok, _, [{Owner}]} =
	pgsql:equery(Db, "SELECT user_id FROM shiptypes where id = $1", [Id]),
    {ok, Owner}.

get_data(Db, Id) ->
    {ok, get_obj(Db, Id)}.

put_data(Db, Id, Obj) ->
    {<<"user_id">>, UserId} = lists:keyfind(<<"user_id">>, 1, Obj),
    {<<"name">>, Name} = lists:keyfind(<<"name">>, 1, Obj),
    {<<"script_id">>, ScriptId} = lists:keyfind(<<"script_id">>, 1, Obj),
    {ok, _, _, [{RespId, UserId, Name, ScriptId}]} = 
	pgsql:equery(Db, "UPDATE shiptypes SET user_id = $2, name = $3, script_id = $4" ++ 
			 "WHERE id = $1 RETURNING id, user_id, name, script_id", [Id, UserId, Name, ScriptId]),
    {ok, 
     [{<<"id">>, RespId},
      {<<"user_id">>, UserId},
      {<<"name">>, Name},
      {<<"script_id">>, ScriptId}]}.

get_obj(Db, Id) ->
    {ok, _, [{RespId, UserId, Name, ScriptId}]} =
	pgsql:equery(Db, "SELECT id, user_id, name, script_id FROM shiptypes WHERE id = $1", [Id]),
    {ok, _, MIds} = 
	pgsql:equery(Db, "SELECT id, name  FROM modules WHERE ship_id = $1", [Id]),
    List = lists:map(fun ({MId, MName}) ->
			     [{<<"id">>, MId},
			      {<<"name">>, MName}]
		     end, MIds),
    [{<<"id">>, RespId},
     {<<"user_id">>, UserId},
     {<<"name">>, Name},
     {<<"script_id">>, ScriptId},
     {<<"modules">>, List}].
