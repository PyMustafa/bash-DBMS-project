# Bash DBMS Project

## Overview

This project implements a basic Database Management System (DBMS) using Bash scripts, **developed as part of the [ITI](https://iti.gov.eg/home) (Information Technology Institute) training program**. It provides a command-line interface with SQL-like syntax for database operations, featuring colorful output and interactive elements powered by [Charm's Gum library](https://github.com/charmbracelet/gum).


## Features

### Database Operations
- Create and drop databases
- List all databases
- Connect to and disconnect from databases
- Switch between databases

### Table Operations
- Create tables with typed columns (INT, FLOAT, BOOL, STRING)
- Define primary keys
- Drop tables
- List all tables in a database

### Data Operations
- Insert rows with type validation
- Select data with column filtering
- Update existing records with WHERE conditions
- Delete rows with WHERE conditions
- Support for various comparison operators (`=`, `!=`, `<`, `>`, `<=`, `>=`)

## Prerequisites

- Bash shell environment
- Root/sudo access for installation
- Internet connection for installing dependencies

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/PyMustafa/bash-DBMS-project.git
   cd bash-DBMS-project
   ```

2. Make the installation script executable:
   ```bash
   chmod +x install.sh
   ```

3. Run the installation script:
   ```bash
   sudo ./install.sh
   ```

Alternatively, you can run it directly with `bash`:
```bash
sudo bash install.sh
```

### Manual Installation
If you prefer to review the installation process:
1. Download the install script
2. Review its contents
3. Make it executable and run it after confirming it's safe

## Usage

1. Start the DBMS using either method:
   ```bash
   ./core.sh         # Preferred method (requires execute permissions)
   bash core.sh      # Alternate method if needed

2. Use SQL-like commands to interact with the system:

   ### Database Commands
   ```sql
   CREATE DATABASE dbname
   DROP DATABASE dbname
   USE dbname
   LIST DB
   ```

   ### Table Commands
   ```sql
   CREATE TABLE tablename col1(type) col2(type) ...
   DROP TABLE tablename
   SHOW TABLES
   ```

   ### Data Commands
   ```sql
   INSERT INTO tablename VALUES value1 value2 ...
   SELECT column1 column2 FROM tablename [WHERE condition]
   SELECT ALL FROM tablename [WHERE condition]
   UPDATE tablename SET column = value WHERE condition
   DELETE FROM tablename WHERE condition
   ```

   ### Other Commands
   ```sql
   -help   -- Show help menu
   clear   -- Clear screen
   exit    -- Exit the program
   ```

## Data Types
- `INT`: Integer values
- `FLOAT`: Decimal numbers
- `STRING`: Text values
- `BOOL`: true/false values


## Security Notes
- The system performs type checking and validation on all inputs
- Table and database names are sanitized
- Reserved keywords are protected
- Primary key constraints are enforced

## Contributing
Feel free to submit issues and enhancement requests!

## License
This project is open-source and available under the MIT License.
