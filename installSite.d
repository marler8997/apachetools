#!/usr/bin/env rund
//!importPath src
//!debug
//!debugSymbols

import std.algorithm : canFind;
import std.string;
import std.format;
import std.path;
import std.file;
import std.stdio;

import apache.util;

immutable apacheConfDirCandidates = ["/etc/apache2", "/etc/httpd"];
__gshared string serviceName;
__gshared string apacheSitesAvailableDir;
__gshared string apacheSitesEnabledDir;

void usage()
{
    writeln("Usage: ./installSite.d <site-conf-file>");
}
int main(string[] args)
{
    args = args[1 .. $];
    if (args.length == 0)
    {
        usage();
        return 1;
    }
    if (args.length > 1)
    {
        writeln("Error: too many arguments");
        return 1;
    }
    const confSource = args[0];
    if (!exists(confSource))
    {
        writefln("Error: '%s' does not exist", confSource);
        return 1;
    }

    
    foreach (candidate; apacheConfDirCandidates)
    {
        if (exists(candidate))
        {
            serviceName = baseName(candidate);
            apacheSitesAvailableDir = candidate ~ "/sites-available";
            apacheSitesEnabledDir = candidate ~ "/sites-enabled";
            break;
        }
    }
    if (apacheSitesAvailableDir is null)
    {
        writefln("Error: could not find apache dir in '%s'", apacheConfDirCandidates);
        return 1;
    }
    if (!exists(apacheSitesAvailableDir) || !exists(apacheSitesEnabledDir))
    {
        writefln("Error: one of '%s' or '%s' does not exist",
            apacheSitesAvailableDir, apacheSitesEnabledDir);
        return 1;
    }

    const confBasename = baseName(confSource);
    const confDest = buildPath(apacheSitesAvailableDir, confBasename);
    if (exists(confDest))
    {
        if (!prompt(format("site '%s' already exists, would you like to overwrite it", confDest)))
            return 0;
    }

    runShell(format("sudo cp '%s' '%s'", confSource, confDest));

    writeln("--------------------------------------------------------------------------------");
    // check if the site is enabled
    const enableLink = buildPath(apacheSitesEnabledDir, confBasename);
    if (exists(enableLink))
    {
        writefln("site is already enabled");
    }
    else if (prompt("site is not enabled, would you like to enable it"))
    {
        runShell(format("sudo ln -s '%s' '%s'", confDest, enableLink));
    }
    writeln("--------------------------------------------------------------------------------");
    if (prompt("would you like to restart apache"))
    {
        runShell(format("sudo service %s reload", serviceName));
    }

    writeln("--------------------------------------------------------------------------------");
    // check to make sure that the cgi module is enabled
    // we do this at the end because apache needs to be running
    // for this check to work
    {
        writeln("checking if cgi module is enabled...");
        auto mods = runGetOutput("apache2ctl -M");
        //writeln(mods);
        enum cgiModule = "cgi_module";
        enum cgidModule = "cgid_module";
        foreach (line; mods.lineSplitter)
        {
            if (line.canFind(cgiModule) || line.canFind(cgidModule))
            {
                goto FOUND_MODULE;
            }
        }
        writefln("Error: neither module '%s' nor '%s' appear to be installed", cgiModule, cgidModule);
        writeln("try running `sudo a2enmod cgid`");
        return 1;
      FOUND_MODULE:
    }
    
    return 0;
}
