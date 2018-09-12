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
    auto errorLog = "error.log";
    auto accessLog = "access.log";

    runShell("sudo service apache2 stop");
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

    runShell("sudo service apache2 start");
    return 0;
}
