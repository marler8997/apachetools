module apache.util;

import std.stdio;

void runShell(string cmd)
{
    import core.stdc.stdlib : exit;
    import std.process : spawnShell, wait;

    writefln("[SHELL] %s", cmd);
    auto pid = spawnShell(cmd);
    auto result = wait(pid);
    if (result != 0)
    {
        writeln("--------------------------------------------------------------------------------");
        writefln("last command failed (exit code %s)", result);
        exit(1);
    }
}

auto runGetOutput(string cmd)
{
    import core.stdc.stdlib : exit;
    import std.process : executeShell, wait;

    writefln("[SHELL] %s", cmd);
    auto result = executeShell(cmd);
    if (result.status != 0)
    {
        writeln("--------------------------------------------------------------------------------");
        writeln(result.output);
        writeln("--------------------------------------------------------------------------------");
        writefln("command failed (exit code %s)", result);
        exit(1);
    }
    return result.output;
}

bool prompt(string message)
{
    import std.string : strip;
    for(;;)
    {
        write(message);
        write(" (y/n)? ");
        stdout.flush();
        string response = readln().strip;
        if (response == "y")
            return true;
        if (response == "n")
            return false;
    }
}
