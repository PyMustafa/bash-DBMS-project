#!/bin/bash
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
# source dependencies using absolute paths
. "${SCRIPT_DIR}/utils.sh"
. "${SCRIPT_DIR}/validators.sh"
. "${SCRIPT_DIR}/database_functions.sh"


# display welcome message
gum style --foreground 212 --border-foreground 212 --border double --align center --width 50 --padding "1 3" "Welcome to our DBMS!"

help_menu() {
    gum style --foreground 156 "Valid SQL Commands (not case sensitive):"
    gum style --foreground 39 "CREATE DATABASE <name>"
    gum style --foreground 39 "DROP DATABASE <name>"
    gum style --foreground 39 "USE <database>"
    gum style --foreground 39 "LIST DATABASE"
    gum style --foreground 39 "SHOW TABLES"
    gum style --foreground 39 "CREATE TABLE <name> <columns...>"
    gum style --foreground 39 "EXIT"
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
            create_table "${queryWords[@]:2}"
            ;;
        "show tables")
            show_tables
            ;;
        *)
            error_message "Unrecognized command: ${queryWords[*]}"
            return 1
            ;;
    esac
}

main() {
    gum style --foreground 141 "'exit' to exit the DBMS, '-help' for help menu"
    # Array of valid SQL keywords for each function
    keywords=("create" "drop" "list" "use" "exit" "show")

    while true; do
        query=$(gum input --placeholder "Enter SQL query" --prompt "> ")
        if [[ "$query" == "exit" ]]; then
            gum confirm "Are you sure you want to exit?" && break;
        else
            parse_sql_query "$query"
        fi
        
    done
}

# Entry point
main