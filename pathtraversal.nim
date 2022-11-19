import os
import std/[parseopt, strutils, sequtils, httpclient, strformat]
import dots

let client = newHttpClient()

let cmdLine = commandLineParams()
var p = initOptParser(cmdLine, shortNoVal = {'v', 'h'},
                              longNoVal = @["verbose", "help"])

var
    verbose = false
    url = ""
    str = ""
    depth = 10


proc printHelpAndQuit() =
    echo "Usage: ", cmdLine[0], " [options] [url]"
    echo "Options:"
    echo "      --string   String to replace from url  (required)"
    echo "      --depth    Depth to traverse"
    echo "  -v, --verbose  Print verbose output"
    echo "  -h, --help     Print this help message"
    quit(0)

proc unknownOption(opt: string) =
    echo "Unknown option: ", opt
    printHelpAndQuit()

if verbose:
  echo "Verbose output enabled"

for kind, key, val in p.getopt():
    case kind
    of cmdEnd:
        break
    of cmdShortOption, cmdLongOption:
        case key
        of "v": verbose = true
        of "verbose": verbose = true
        of "h": printHelpAndQuit()
        of "help": printHelpAndQuit()
        of "string": str = val
        of "depth": depth = val.parseInt()
        else: unknownOption(key)
    of cmdArgument:
        url = key

if url == "":
    echo "No url specified"
    printHelpAndQuit()

if str == "":
    echo "No string specified"
    printHelpAndQuit()

let message = fmt"""

TESTING PATH TRAVERSAL

Testing in {url}
String to replace: {str}
Depth: {depth}
"""

echo message

for i in 1..depth:
    for file in dots.files:
        for dot in dots.dots:
            let path = toSeq(1..i).mapIt(dot).joinPath()
            let newUrl = url.replace(str, path & file)

            if verbose:
                echo "Trying: ", newUrl
            
            let response = client.get(newUrl)

            case response.code
            of Http200, Http201, Http202, Http203, Http204, Http205, Http206, Http207, Http208, Http226:
                echo "Found: ", newUrl
            of Http301, Http302, Http303, Http307, Http308:
                echo "Redirect: ", newUrl
            else:
                discard
