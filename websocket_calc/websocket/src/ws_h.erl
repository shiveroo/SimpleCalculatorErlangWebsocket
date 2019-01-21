-module(ws_h).

-export([init/2]).
-export([websocket_init/1]).
-export([websocket_handle/2]).
-export([websocket_info/2]).

-export([add/2, delete/2, find/2, qs_transl/1, kv_lst/1, 
		 process_query/2, reply/2]).

init(Req, Opts) ->
	{cowboy_websocket, Req, Opts}.

websocket_init(State) ->
	erlang:start_timer(1000, self(), <<"Hello!">>),
	{ok, State}.


websocket_handle({text, Msg}, State) ->
	try qs_transl(binary_to_list(Msg)) of
		Query ->
			try process_query(Query, State) of		
				{Reply, NewState} ->
					{reply, {text, << Reply/binary >>}, NewState, hibernate}
			catch
				error:_ ->
					{reply, {text, << "Error in query." >>}, State, hibernate}
			end
	catch
		error:_ ->
			{reply, {text, << "Query syntax error." >>}, State, hibernate}
	end;

websocket_handle(_Data, State) ->
	{ok, State}.

websocket_info(_Info, State) ->
	{ok, State}.

	process_query(Query, State) -> 

		%Who = list_to_atom(find(who,Query)),
		Param1 = erlang:list_to_integer(find(a,Query)),
		Param2 = erlang:list_to_integer(find(b,Query)),

		case list_to_atom(find(op,Query)) of	
				plus ->
					Return = Param1 + Param2,
					{ reply("~w + ~w = ~w",[Param1,Param2,Return]),
					State };
				minus ->
					Return = Param1 - Param2,
					{ reply("~w - ~w = ~w",[Param1,Param2,Return]),
					State };
				divis ->
					Return = Param1 / Param2,
					{ reply("~w / ~w = ~w",[Param1,Param2,Return]),
					State };
				mult ->
					Return = Param1 * Param2,
					{ reply("~w * ~w = ~w",[Param1,Param2,Return]),
					State };
				pow ->
					Return = Param1 * Param1,
					{ reply("~w ^2 = ~w",[Param1,Return]),
					State };
				sqt ->
					Return = math:sqrt(Param1),
					{ reply("sqrt(~w) = ~w",[Param1,Return]),
					State };
				_ ->
				   { reply("Undefined operation.",[]),
					 State }
			 end.


qs_transl(String) ->
	kv_lst(string:tokens(String,"&")).

kv_lst([]) -> [];
kv_lst([Eq|Eqs]) ->
	[Ks,Vs] = string:tokens(Eq,"="),
	[{list_to_atom(Ks),Vs}|kv_lst(Eqs)].

add({Key,Value},[]) -> [{Key,Value}];
add({Key,Value},[{Key,_}|T]) -> [{Key,Value}|T];
add({Key,Value},[H|T]) -> [H|add({Key,Value},T)].

delete(_,[]) -> [];
delete(Key,[{Key,_}|T]) -> T;
delete(Key,[H|T]) -> [H|delete(Key,T)].
 
find(_,[]) -> undefined;
find(Key,[{Key,Value}|_]) -> Value;
find(Key,[_|T]) -> find(Key,T).

reply(Format, Args) ->
	list_to_binary(io_lib:format(Format, Args)).	