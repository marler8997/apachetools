module apache.util;

import std.stdio;

int tryRunShell(string cmd)
{
    import std.process : spawnShell, wait;

    writefln("[SHELL] %s", cmd);
    auto pid = spawnShell(cmd);
    return wait(pid);
}

void runShell(string cmd)
{
    import core.stdc.stdlib : exit;

    const result = tryRunShell(cmd);
    if (result != 0)
    {
        writeln("--------------------------------------------------------------------------------");
        writefln("last command failed (exit code %s)", result);
        exit(1);
    }
}

auto tryRunGetOutput(string cmd)
{
    import std.process : executeShell, wait;

    writefln("[SHELL] %s", cmd);
    return executeShell(cmd);
}
auto runGetOutput(string cmd)
{
    import core.stdc.stdlib : exit;
    const result = tryRunGetOutput(cmd);
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

void setPermissionsForWebDir(string dir)
{
    import std.format : format;
    import std.path : dirName;

    // apache requires that the apache user has execute permissions
    // on all directories in the full path to the DocumentRoot
    for (;;)
    {
        runShell(format("sudo chmod +x %s", dir));
        auto next = dir.dirName;
        if (next == dir)
            break;
        dir = next;
    }
}

private immutable apacheConfDirCandidates = ["/etc/apache2", "/etc/httpd", "~/httpd"];
struct ApacheConf
{
    string confDir;
    string serviceName;
    string sitesAvailableDir;
    string sitesEnabledDir;
}
auto findApacheConf()
{
    import core.stdc.stdlib : exit;
    import std.string : replace;
    import std.path : baseName;
    import std.file : exists;
    import std.process : environment;

    foreach (string candidate; apacheConfDirCandidates)
    {
        candidate = candidate.replace("~", environment["HOME"]);
        if (exists(candidate))
        {
            return ApacheConf(
                candidate,
                baseName(candidate),
                candidate ~ "/sites-available",
                candidate ~ "/sites-enabled");
        }
    }
    writefln("Error: could not find apache dir in '%s'", apacheConfDirCandidates);
    exit(1);
    assert(0);
}