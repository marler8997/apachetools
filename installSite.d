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

    const apacheConf = findApacheConf();
    if (!exists(apacheConf.sitesAvailableDir) || !exists(apacheConf.sitesEnabledDir))
    {
        writefln("Error: one of '%s' or '%s' does not exist",
            apacheConf.sitesAvailableDir, apacheConf.sitesEnabledDir);
        return 1;
    }

    const confBasename = baseName(confSource);
    const confDest = buildPath(apacheConf.sitesAvailableDir, confBasename);
    if (exists(confDest))
    {
        if (!prompt(format("site '%s' already exists, would you like to overwrite it", confDest)))
            return 0;
    }

    runShell(format("sudo cp '%s' '%s'", confSource, confDest));

    writeln("--------------------------------------------------------------------------------");
    // check if the site is enabled
    const enableLink = buildPath(apacheConf.sitesEnabledDir, confBasename);
    if (exists(enableLink))
    {
        writefln("site is already enabled");
    }
    else if (prompt("site is not enabled, would you like to enable it"))
    {
        runShell(format("sudo ln -s '%s' '%s'", confDest, enableLink));
    }
    writeln("--------------------------------------------------------------------------------");
    bool systemd = false;
    if (prompt("would you like to restart apache"))
    {
        if (0 == tryRunShell(format("sudo systemctl restart %s", apacheConf.serviceName)))
            systemd = true;
        else
            runShell(format("sudo service %s reload", apacheConf.serviceName));
    }

    writeln("--------------------------------------------------------------------------------");

    // check to make sure that the cgi module is enabled
    // we do this at the end because apache needs to be running
    // for this check to work
    {
        writeln("checking if cgi module is enabled...");
        const modResult = tryRunGetOutput("apache2ctl -M");
        if (modResult.status != 0)
        {
            writefln("WARNING: apache2ctl -M failed, can't verify that the CGI module is installed");
        }
        else
        {
            const mods = modResult.output;
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
    }
    
    return 0;
}
