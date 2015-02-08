# script-engine-installer

A minimal shell script to install scripting engines locally according to a simple spec file. Designed and implemented to allow easy installation of non-default Ruby and Node versions under a docker container, but should work pretty much everywhere (if it doesn't open an issue, please).
 
(c) Oded Arbel 2015; Licensed under MIT license

Uses a .versions.conf file (as is common practice for RMV) and installs the specified scripting
engines and their management tools, as required.

Currently supported tools:

 - Ruby (using RVM)
 - Node.js (using NVM)

Currently supported operating systems:

 - Ubuntu 14.04

# Usage

`curl https://raw.githubusercontent.com/guss77/script-engine-installer/master/install-script-engine.sh | bash`
