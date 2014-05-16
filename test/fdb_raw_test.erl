-module(fdb_raw_test).

-include_lib("eunit/include/eunit.hrl").
-include("../include/fdb.hrl").

-define(SOLIB,"../priv/fdb_nif").

range_test() ->
  {ok, DB} = fdb_raw:init_and_open_try_5_times(?SOLIB),
  range_test_core(DB).

range_single_transaction_test() ->
  {ok, DB} = fdb_raw:init_and_open_try_5_times(?SOLIB),
  fdb:transact(DB, fun(Tx) ->
    range_test_core(Tx)
  end).

range_test_core(Handle) ->
  fdb_raw:clear_range(Handle, <<"__test",0>>, <<"__test",255>>),
  [ok = fdb_raw:set(Handle, <<"__test",(2*I)>>, <<(2*I)>>) || I <- lists:seq(1, 9)],
  %% test closed interval, when values are present
  ?assertEqual( [ {<<"__test",2>>, <<2>>}
                , {<<"__test",4>>, <<4>>}
                , {<<"__test",6>>, <<6>>}
                ]
              , fdb_raw:get_range(Handle, #select{ gte = <<"__test",2>>
                                                 , lte = <<"__test",6>>})),
  %% test closed interval, when values are not present
  ?assertEqual( [ {<<"__test",4>>, <<4>>}
                , {<<"__test",6>>, <<6>>}
                ]
              , fdb_raw:get_range(Handle, #select{ gte = <<"__test",3>>
                                                 , lte = <<"__test",7>>})),
  %% test open interval, when values are present
  ?assertEqual( [ {<<"__test",6>>, <<6>>}
                , {<<"__test",8>>, <<8>>}
                ]
              , fdb_raw:get_range(Handle, #select{ gt = <<"__test",4>>
                                                 , lt = <<"__test",10>>})),
  %% test open interval, when values are not present
  ?assertEqual( [ {<<"__test",4>>, <<4>>}
                , {<<"__test",6>>, <<6>>}
                ]
              , fdb_raw:get_range(Handle, #select{ gt = <<"__test",3>>
                                                 , lt = <<"__test",7>>})),
  %% test interval, with endpoint offsets
  ?assertEqual( [ {<<"__test",2>>, <<2>>}
                , {<<"__test",4>>, <<4>>}
                , {<<"__test",6>>, <<6>>}
                , {<<"__test",8>>, <<8>>}
                , {<<"__test",10>>, <<10>>}
                ]
              , fdb_raw:get_range(Handle, #select{ gt           = <<"__test",3>>
                                                 , offset_begin = -1
                                                 , lte          = <<"__test",7>>
                                                 , offset_end   = 2
                                                 })),
  %% test getting data around a single value
  ?assertEqual( [ {<<"__test",2>>, <<2>>}
                , {<<"__test",4>>, <<4>>}
                , {<<"__test",6>>, <<6>>}
                , {<<"__test",8>>, <<8>>}
                , {<<"__test",10>>, <<10>>}
                ]
              , fdb_raw:get_range(Handle, #select{ gte          = <<"__test",6>>
                                                 , offset_begin = -2
                                                 , lte          = <<"__test",6>>
                                                 , offset_end   = 2
                                                 })),
  %% test range/3
  ?assertEqual( [ {<<"__test",4>>, <<4>>}
                , {<<"__test",6>>, <<6>>}
                ]
              , fdb_raw:get_range(Handle, <<"__test",4>>, <<"__test",7>>)),
  fdb_raw:clear_range(Handle, <<"__test",0>>, <<"__test",255>>).

