#!/usr/bin/env rund
//!importPath src
//!debug
//!debugSymbols

import core.stdc.stdlib : exit;
import std.algorithm : canFind;
import std.string;
import std.format;
import std.path;
import std.file;
import std.stdio;

import apache.util;

__gshared string inFilename;
__gshared string[string] vars;

void usage()
{
    writeln("Usage: ./processTemplate.d [<var>=<value>]... <input-file> [<output-file>]");
}
int main(string[] args)
{
    args = args[1 .. $];
    {
        size_t newArgsLength = 0;
        scope(exit) args = args[0 .. newArgsLength];
        for (size_t i = 0; i < args.length; i++)
        {
            auto arg = args[i];
            auto equalIndex = arg.indexOf('=');
            if (equalIndex == -1)
            {
                args[newArgsLength++] = arg;
            }
            else
            {
                vars[arg[0 .. equalIndex]] = arg[equalIndex + 1 .. $];
            }
        }
    }
    if (args.length == 0)
    {
        usage();
        return 1;
    }
    if (args.length > 2)
    {
        stderr.writeln("Error: too many arguments");
        return 1;
    }
    inFilename = args[0];
    File outFile;
    if (args.length == 1)
        outFile = stdout;
    else
        outFile = File(args[1], "w");

    auto inFile = File(inFilename, "r");
    uint lineNumber = 1;
    foreach (line; inFile.byLine)
    {
        processLine(outFile, line, lineNumber);
    }
    return 0;
}

void processLine(File outFile, const(char)[] line, uint lineNumber)
{
    size_t nextFlushStart = 0;
    size_t next = 0;
    void flush()
    {
        if (next > nextFlushStart)
        {
            outFile.write(line[nextFlushStart .. next]);
        }
    }
    for (;;next++)
    {
        if (next >= line.length)
            break;
        if (line[next] == '[')
        {
            flush();
            next++;
            auto start = next;
            for (;; next++)
            {
                if (next >= line.length)
                {
                    stderr.writefln("%s(%s) Error: unterminated '['", inFilename, lineNumber);
                    exit(1);
                }
                if (line[next] == ']')
                    break;
            }
            auto varName = line[start .. next];
            auto value = vars.get(cast(string)varName, null);
            if (value is null)
            {
                stderr.writefln("%s(%s) Error: undefined variable '%s'", inFilename, lineNumber, varName);
                exit(1);
            }
            outFile.write(value);
            nextFlushStart = next + 1;
        }
    }
    flush();
    outFile.writeln();
}