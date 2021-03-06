%%%----------------------------------------------------------------
%%% @author  Heinz N. Gies <heinz@licenser.net>
%%% @doc
%%% @end
%%% @copyright 2011 Heinz N. Gies
%%%----------------------------------------------------------------
-module(ds_web_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

%%%===================================================================
%%% API functions
%%%===================================================================

-spec start_link() -> {ok, pid()} | any().
start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%%%===================================================================
%%% Supervisor callbacks
%%%===================================================================


%% @private
-spec init(list()) -> {ok, {SupFlags::any(), [ChildSpec::any()]}} |
                       ignore | {error, Reason::any()}.
init([]) ->
    RestartStrategy = one_for_one,
    MaxRestarts = 1000,
    MaxSecondsBetweenRestarts = 3600,

    SupFlags = {RestartStrategy, MaxRestarts, MaxSecondsBetweenRestarts},

    Restart = permanent,
    Shutdown = 2000,
    Type = worker,

    WebServer = {ds_web_server, {ds_web_server, start_link, []},
		 Restart, Shutdown, Type, [ds_web_server]},
    WsSup = {ws_sup, {ws_sup, start_link, []},
	     Restart, Shutdown, supervisor, [ws_sup]},
    
    {ok, {SupFlags, [WebServer, WsSup]}}.

%%%===================================================================
%%% Internal functions
%%%===================================================================


