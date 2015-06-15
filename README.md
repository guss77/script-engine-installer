# script-engine-installer

A minimal shell script to install scripting engines locally according to a simple spec file. Designed and implemented to allow easy installation of non-default Ruby and Node versions under a docker container, but should work pretty much everywhere (if it doesn't - open an issue, please).
 
(c) Oded Arbel 2015; Licensed under MIT license

Uses a .versions.conf file (as is common practice for RVM) and installs the specified scripting
engines and their management tools, as required.

Currently supported tools:

 - Ruby (using RVM)
 - Node.js (using NVM)

Currently supported operating systems:

 - Ubuntu >= 12.04

# Usage

While technically, you can curl|sh like this:

`curl https://raw.githubusercontent.com/guss77/script-engine-installer/master/install-script-engine.sh | bash`

Plaese don't do that because I'm not trustworthy, and while I guarantee you that today this script will not eat your harddrive, I make no such guarantees about the future. Instead:

1. download the release tarball
2. open the tarball and inspect the main script
3. If you think it works for you, put it somewhere in your path, chmod 755 it, and run it where you have a .versions.conf
