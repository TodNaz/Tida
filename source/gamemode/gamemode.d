module gamemode.gamemode;

import bindbc.loader;
import std.file : exists;

version(Posix):

alias pid_t = int;

alias api_call_return_int = extern(C) int function();
alias api_call_return_cstring = extern(C) const(char*) function();
alias api_call_pid_return_int = extern(C) int function(pid_t);

__gshared
{
    api_call_return_int REAL_internal_gamemode_request_start;
    api_call_return_int REAL_internal_gamemode_request_end;
    api_call_return_int REAL_internal_gamemode_query_status;
    api_call_return_cstring REAL_internal_gamemode_error_string;
    api_call_pid_return_int REAL_internal_gamemode_request_start_for;
    api_call_pid_return_int REAL_internal_gamemode_request_end_for;
    api_call_pid_return_int REAL_internal_gamemode_query_status_for;
}

__gshared SharedLib gmmodeLib;

enum path = "/usr/lib/libgamemode.so.0";
enum path2 = "/usr/lib/libgamemode.so";

bool isGameModeExist()
{
    if (!exists(path))
    {
        if (!exists(path2))
            return false;
    }

    return true;
}

void loadGameModeLib()
{
    if (!exists(path))
    {
        if (!exists(path2))
            throw new Exception("GameMode library not found!");
        else
            gmmodeLib = load(path2);
    } else
        gmmodeLib = load(path);

    if (gmmodeLib == SharedLib.init)
        throw new Exception("GameMode failure loaded!");

    bindSymbol(gmmodeLib, cast(void**) &REAL_internal_gamemode_request_start, "real_gamemode_request_start");
    bindSymbol(gmmodeLib, cast(void**) &REAL_internal_gamemode_request_end, "real_gamemode_request_end");
    bindSymbol(gmmodeLib, cast(void**) &REAL_internal_gamemode_query_status, "real_gamemode_query_status");
    bindSymbol(gmmodeLib, cast(void**) &REAL_internal_gamemode_error_string, "real_gamemode_error_string");
    bindSymbol(gmmodeLib, cast(void**) &REAL_internal_gamemode_request_start_for, "real_gamemode_request_start_for");
    bindSymbol(gmmodeLib, cast(void**) &REAL_internal_gamemode_request_end_for, "real_gamemode_request_end_for");
    bindSymbol(gmmodeLib, cast(void**) &REAL_internal_gamemode_query_status_for, "real_gamemode_query_status_for");

    if (REAL_internal_gamemode_request_start is null)
        throw new Exception("GameMode function error load!");
}

void gamemodeRequestStart() @trusted
{
    import std.conv : to;

    if (REAL_internal_gamemode_request_start() != 0)
    {
        throw new Exception("Gamemode request start error: " ~ REAL_internal_gamemode_error_string().to!string);
    }
}

void gamemodeRequestEnd() @trusted
{
    import std.conv : to;

    if (REAL_internal_gamemode_request_end() != 0)
    {
        throw new Exception("Gamemode request start error: " ~ REAL_internal_gamemode_error_string().to!string);
    }
}
