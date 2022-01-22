# GOAL

This repo demonstrates the use of the SQL MERGE statement
using MS SQL Server 2019.

This statement is available in most RDBMS systems.
The syntax various on a few of them, as described here:
https://en.wikipedia.org/wiki/Merge_(SQL)

# REQUIREMENTS

This should run on any system with:
- Bash
- Make
- Docker and Docker-Compose

# TESTING

This was tested on:
- PopOS 21.10 Linux
- Windows 10 using WSL2 with docker integration on Ubuntu18.04

# RUNNING THE CODE

## One-time setup 

```cp sqlserverdb.env.example sqlserverdb.env```

Edit the SA password in sqlserverdb.env, as needed, to prevent external access.

## To run all the code
Just run ```make``` 

## Additional options
Review the Makefile and run scripts for additional commands

