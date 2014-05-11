-module(stress_test).
-export([start/0,start/1]).

start() -> start(10000).

start(Amount) ->
  DB = fdb:init_and_open(),
  Pid = self(),
  [spawn_link(fun ()-> test_get_and_set(Pid, DB, I) end)
    ||I <- lists:seq(1, Amount)],
  R = get_results([]),
  report(R).
  
get_results(Vals) ->
  receive
    {yups, From, To} -> get_results([{From, To}|Vals])
    after 1000 -> [timer:now_diff(T,F)||{F,T} <-Vals]
  end.

test_get_and_set(ParentPid, DB, I) ->
  From = now(),
  fdb:maybe_do([
    fun() -> fdb:set(DB, I, I) end,
    fun() -> fdb:get(DB, I, I) end,
    fun() -> ParentPid ! {yups, From, now()} end
  ]).

report(L) ->
    Length = length(L),
    Min = lists:min(L),
    Max = lists:max(L),
    Med = lists:nth(round(Length / 2), lists:sort(L)),
    Avg = round(lists:foldl(fun(X, Sum) -> X + Sum end, 0, L) / Length),
    io:format("Count: ~b~n",[Length]),
    io:format("Range: ~b - ~b mics~n"
          "Median: ~b mics~n"
          "Average: ~b mics~n",
          [Min, Max, Med, Avg]).
