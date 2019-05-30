#!/usr/bin/env rund
//!importPath src
import std.stdio;
import std.file;
import std.path;
import std.format;
import std.process;

import apache.util;

int main()
{
    const errorLog = "error.log";
    const accessLog = "access.log";

    const apacheConf = findApacheConf();

    bool systemd = false;
    if (0 == tryRunShell(format("sudo systemctl stop %s", apacheConf.serviceName)))
        systemd = true;
    else
        runShell(format("sudo service %s stop", apacheConf.serviceName));
    if(exists(errorLog))
    {
        writefln("removing \"%s\"...", errorLog);
        remove(errorLog);
    }
    else
    {
        writefln("error log \"%s\" does not exist", errorLog);
    }
    
    if(exists(accessLog))
    {
        writefln("removing \"%s\"...", accessLog);
        remove(accessLog);
    }
    else
    {
        writefln("access log \"%s\" does not exist", accessLog);
    }

    if (systemd)
        runShell(format("sudo systemctl start %s", apacheConf.serviceName));
    else
        runShell(format("sudo service %s start", apacheConf.serviceName));
    return 0;
}
