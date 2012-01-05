#!/usr/bin/env escript
-export([main/1]).

main([ModuleName]) ->
    %% TODO use rebar.config here:
    code:add_path("ebin"),
    code:add_paths( filelib:wildcard("deps/*/ebin") ),
    case code:where_is_file(ModuleName ++ ".beam") of
        non_existing ->
            use_module_info(ModuleName);
        Path ->
            use_debug_info(Path)
    end;

main(_) ->
    bad_module.

use_module_info(ModuleName) ->
    Module = erlang:list_to_atom(ModuleName),
    try Module:module_info(exports) of
        Functions ->
            lists:foreach(
                fun({FunctionName, ArgumentsCount}) ->
                        io:format("~s\t~B~n", [FunctionName, ArgumentsCount])
                end,
                Functions
            )
    catch
        error:undef ->
            bad_module
    end.

use_debug_info(Path) ->
    {ok, Beam} = file:read_file(Path),
    AC = read_abstract_code(Beam),
    Funs = extract_funs_from_abstract(AC),
    io:format( [ render_function(F) || F <- lists:reverse(Funs) ] ).

%% If F is a function declaration Name Fc_1 ; ... ; Name Fc_k,
%% where each Fc_i is a function clause with a pattern sequence of the same 
%% length Arity, then Rep(F) = {function,LINE,Name,Arity,[Rep(Fc_1), ...,Rep(Fc_k)]}.

read_abstract_code(Beam) when is_binary(Beam) ->
    {ok,{_,[{abstract_code,{_,AC}}]}} = beam_lib:chunks(Beam,[abstract_code]),
    AC.

extract_funs_from_abstract(AC) ->
    lists:foldl(fun(T, Acc) -> 
                    case element(1,T) of 
                        function -> [T|Acc] ; 
                        _        -> Acc 
                    end 
                end, [], AC).


%% Never auto-complete on certain common behaviour funs:
render_function({function, _, handle_call, _, _}) -> "";
render_function({function, _, handle_cast, _, _}) -> "";
render_function({function, _, handle_info, _, _}) -> "";

render_function({function, _LineNo, Name, 0, _Reps}) ->
    io_lib:format("~w()\t~B~n", [Name, 0]);

render_function({function, _LineNo, Name, Arity, Reps}) ->
    %erl_prettypr:format(erl_syntax:form_list([ F ]))
    {clause, _, ParamTups, _, _} = hd(Reps),
    Params = [ to_str(P) || {_,_,P} <- ParamTups ],
    ParamsString = string:join(Params, ","),
    io_lib:format("~w(~s)\t~B~n", [Name, ParamsString, Arity]).


to_str(N) when is_integer(N) ; is_float(N) ; is_boolean(N) ->
    io_lib:format("~w",[n]);

to_str(A) when is_atom(A) ->
    io_lib:format("~s",[A]).
