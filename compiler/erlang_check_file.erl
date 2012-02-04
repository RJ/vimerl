#!/usr/bin/env escript
-export([main/1]).

main([File_Name]) ->
    %% If we use parse transforms (lager, etc):
    code:add_paths(["ebin"] ++ filelib:wildcard("deps/*/ebin")),
    Default = [     warn_obsolete_guard,
                    warn_unused_import,
                    warn_shadow_vars, warn_export_vars,
                    strong_validation, report],
    %% Take our options from rebar.config:
    case file:consult("rebar.config") of
        {ok, Terms} ->
            Opts = proplists:get_value(erl_opts, Terms, []),
        	compile:file(File_Name, Default ++ Opts);
        _ ->
            compile:file(File_Name, Default ++ [{i, "../include"}])
    end.
    
