#!/bin/bash

# Check if gum is installed
if ! command -v gum &> /dev/null; then
    echo -e "\033[1;31mError: Gum is required but not installed.\033[0m"
    echo -e "Please run \033[1;34m./install.sh\033[0m to install dependencies"
    echo -e "Or install manually: \033[4;34mhttps://github.com/charmbracelet/gum#installation\033[0m"
    exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
# source dependencies using absolute paths
. "${SCRIPT_DIR}/utils.sh"
. "${SCRIPT_DIR}/validators.sh"
. "${SCRIPT_DIR}/database_functions.sh"
. "${SCRIPT_DIR}/select.sh"
. "${SCRIPT_DIR}/update.sh"
. "${SCRIPT_DIR}/delete.sh"

clear

# display welcome message
gum style --foreground 212 --border-foreground 212 --border double --align center --width 50 --padding "1 3" "Welcome to our DBMS!"

help_menu() {
    gum style --foreground 156 "Valid SQL Commands (not case sensitive):"
    info_message "CREATE DATABASE <name>"
    info_message "DROP DATABASE <name>"
    info_message "USE <database>"
    info_message "LIST DB"

    info_message "SHOW TABLES"
    info_message "CREATE TABLE <Table_name> <col1(type)> <col2(type)> ..."
    info_message "Avaliable Datatypes: INT,FLOAT,BOOL,STRING"
    info_message "DROP TABLE <table_name>"
    info_message "INSERT INTO <table_name> VALUES <value1>, <value2>, ..."
    info_message "SELECT all FROM <table_name>", "SELECT <columns> FROM <table_name>"
    info_message "UPDATE <table_name> SET <column_name> = <value> WHERE <column_name> = <value>"
    info_message "EXIT"
    echo ""
}

parse_sql_query() {
    local query="$1"
    # convert query to lowercase and split into words
    local -a queryWords=($(echo "$query" | tr '[:upper:]' '[:lower:]'))

    # basic query validation
    [[ ${#queryWords[@]} -eq 0 ]] && {
        error_message "Empty query"
        return 1
    }

    # natch single-word commands first
    case "${queryWords[0]}" in
        "-help")
            help_menu
            return 0
            ;;
        "use")
            # Validate argument count
            [[ ${#queryWords[@]} -eq 2 ]] || {
                error_message "Usage: USE <database>"
                return 1
            }
            use_database "${queryWords[1]}"
            return 0
            ;;
            "select")
            
            [[ -z "$current_db" ]] && {
                error_message "you are not connected to a database. Use 'use db_name' first."
                return 1
            }
            execute_select "${queryWords[@]}"
            return 0
            ;;
            "update")
            
            [[ -z "$current_db" ]] && {
                error_message "you are not connected to a database. Use 'use db_name' first."
                return 1
            }
            execute_update "${queryWords[@]}"
            return 0
            ;;
        "disconnect")
            exit_db
            return 0
            ;;
    esac

    # match multi-word commands
    case "${queryWords[0]} ${queryWords[1]-}" in
        "create database")
            [[ ${#queryWords[@]} -eq 3 ]] || {
                error_message "Usage: CREATE DATABASE <name>"
                return 1
            }
            create_database "${queryWords[2]}"
            ;;
        "drop database")
            [[ ${#queryWords[@]} -eq 3 ]] || {
                error_message "Usage: DROP DATABASE <name>"
                return 1
            }
            drop_database "${queryWords[2]}"
            ;;
        "list db")
            list_db
            ;;
        "create table")
            [[ ${#queryWords[@]} -ge 3 ]] || {
                error_message "Usage: CREATE TABLE <name> <columns...>"
                return 1
            }
            # create_table "${queryWords[@]:2}"
            create_table "${queryWords[@]}"
            ;;
        
        "show tables")
            show_tables
            ;;
        "drop table")
            [[ ${#queryWords[@]} -eq 3 ]] || {
                error_message "Usage: DROP TABLE <table_name>"
                return 1
            }
            drop_table
            ;;
         "insert into")
            [[ ${#queryWords[@]} -ge 4 ]] || {
                error_message "Usage: INSERT INTO <table_name> VALUES <value1> <value2> ..."
                return 1
            }
            insert_into_table "${queryWords[2]}" "${queryWords[@]:4}"
            ;;
        "delete from")
            [[ -z "$current_db" ]] && {
                error_message "You are not connected to a database. Use 'use db_name' first."
                return 1
            }
            delete_from_table "${queryWords[@]}"
            ;;
        *)
            error_message "Invalid input: ${queryWords[*]}"
            return 1
            ;;
    esac
}

main() {
    gum style --foreground 141 "'exit', '-help' or 'clear'"
    # Array of valid SQL keywords for each function
    keywords=("create" "drop" "list" "use" "exit" "show" "insert" "delete")

    while true; do
        query=$(gum input --placeholder "Enter SQL query or command" --prompt "> ")
        if [[ "${query,,}" == "exit" ]]; then
            gum confirm "Are you sure you want to exit?" && break;
        elif [[ "${query,,}" == "clear" ]]; then
            clear
        else
            parse_sql_query "$query"
        fi
        
    done
}

# Entry point
main