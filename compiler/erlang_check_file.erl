#!/usr/bin/env escript
-export([main/1]).

main([File_Name]) ->
    Default = [     warn_obsolete_guard,
                    warn_unused_import,
                    warn_shadow_vars, warn_export_vars,
                    strong_validation, report],
    case filelib:is_file("rebar.config") of
        true ->
            {ok, Terms} = file:consult("rebar.config"),
            Opts = proplists:get_value(erl_opts, Terms, []),
        	compile:file(File_Name, Default ++ Opts);
        false ->
            compile:file(File_Name, Default)
    end.
    
