# CS 411 Project Track 1 - Book Dataset Loader

## Requirements

- A Linux environment (WSL2 Ubuntu was used in testing)

- MySQL on the Linux environment

To install WSL, refer to https://docs.microsoft.com/en-us/windows/wsl/install

To install MySQL for WSL, refer to https://docs.microsoft.com/en-us/windows/wsl/tutorials/wsl-database

## How to load the database

Open this folder (`./`) in a terminal, then type the command:

`sh setup_db.sh`

This will copy all files to `/var/lib/mysql-files/`, which is where WSL looks for MySQL files. This then opens the SQL terminal.

Next, type `source LoadProjData.sql`. This executes the SQL instructions in LoadProjData.sql, loading all of the data from each file.

**Note:** This step may take a few minutes to finish.

Once this is completed, the database will be loaded. You can either use `source <file>` to run SQL commands from a file (recommended), or type them into the SQL console directly.