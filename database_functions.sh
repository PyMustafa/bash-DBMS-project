#!/bin/bash
# Database main functions
# Global variable to store the current database name
current_db=""

get_current_db() {
    echo "${current_db##*/}"
}

# Create a new database
create_database() {
    local db_name="$1"
    # validate database name
    validate_name "$db_name" "database" || return 1

    # normalize database name
    local normalized_db_name=$(normalize_name "$db_name")

    # check if database already exist
    if [[ " ${DB_CONTEXT[DATABASES_LIST]} " =~ " ${normalized_db_name} " ]]; then
        error_message "Database '$normalized_db_name' already exists"
        return 1
    fi

    # create database
    mkdir -p "$SCRIPT_DIR/$normalized_db_name" && {
        success_message "Database '$normalized_db_name' created successfully"
        return 0
    }

    display_error "Failed to create database"
    return 1
}

# List all databases
list_db() {
    # List all directories in the current directory
    info_message "Listing all databases:"
    for db in */; do
        if [ -d "$db" ]; then
            gum style --foreground 39 "${db%/}"
        fi
    done
}

# Use a database (connect to a database)
use_database() {
    local db_name="$1"

    # Check if the db_name is valid
    validate_name "$db_name" "database" || return 1

    local normalized_db_name=$(normalize_name "$db_name")

    
    if [ ! -d "$normalized_db_name" ]; then
        error_message "Database '$db_name' does not exist."
        return
    fi
    # Change to the database directory and display success message
    current_db="$SCRIPT_DIR/$normalized_db_name" 
    success_message "Now using database '$normalized_db_name'."
}

# Drop a database
drop_database() {
    local db_name="${queryWords[2]}"
    local current_db_name=$(get_current_db)
    validate_name "$db_name" "database" || return 1
    local normalized_db_name=$(normalize_name "$db_name")
    

    if [ ! -d "$normalized_db_name" ]; then
        error_message "Database '$db_name' does not exist."
        return
    fi

    # Check if the user is inside this database
    if [[ "$normalized_db_name" == "$current_db_name" ]]; then
        error_message "You cannot drop database '$current_db_name' while inside. Use 'disconnect' first."
        return
    fi

    # Confirm the deletion and remove the database directory
    gum confirm "Are you sure you want to delete the database '$db_name'? This action cannot be undone." && \
        { rm -rf "$db_name"; success_message "Database '$db_name' dropped successfully."; } || \
        info_message "Deletion canceled."
}

# Exit the current database (disconnect)
exit_db() {
    # Check if the user is inside a database
    if [[ -z "$current_db" ]]; then
        error_message "You are not inside any database."
        return 1
    fi

    # Change to the parent directory and display success message
    current_db="" 
    success_message "Exited the current database."
}

# Create a new table
create_table() {
    local table_name="${queryWords[2]}"

    # Validate database context
    [[ -z "$current_db" ]] && {
        error_message "No active database. Use 'use db_name' first."
        return
    }

    # Validate table name
    validate_name "$table_name" "table" || return 1

    # Check if columns are provided
    [[ -z "${queryWords[@]:3}" ]] && {
        error_message "No columns provided. Use format: create table table_name col1(type) col2(type)."
        return
    }

    # Check if table already exists
    [[ -f "$current_db/$table_name" ]] && {
        error_message "Table '$table_name' already exists."
        return
    }

    # Process columns and types
    local columns_input="${queryWords[@]:3}"
    local columns=()
    local column_types=()
    local valid=true
    local IFS=' '
    read -r -a columns_array <<< "$columns_input"

    for column in "${columns_array[@]}"; do
        if [[ "$column" =~ ^[a-zA-Z_][a-zA-Z0-9_]*\([a-zA-Z_]+\)$ ]]; then
            local col_name=$(echo "$column" | cut -d'(' -f1)
            local col_type=$(echo "$column" | cut -d'(' -f2 | cut -d')' -f1)

            # Check unique column names
            [[ " ${columns[@]} " =~ " ${col_name} " ]] && {
                error_message "Duplicate column name '$col_name'."
                return
            }

            # Validate column type
            [[ "$col_type" =~ ^(string|int|float|bool)$ ]] || {
                error_message "Invalid column type '$col_type' for column '$col_name'."
                return
            }

            columns+=("$col_name")
            column_types+=("$col_type")
        else
            error_message "Invalid column format '$column'. Use format: column_name(type)."
            return
        fi
    done

    # Select primary key
    local primary_key=""
    while true; do
        primary_key=$(gum input --placeholder "Please enter the primary key column" --prompt "> ")
        [[ " ${columns[@]} " =~ " ${primary_key} " ]] && break
        error_message "The primary key must be one of the defined columns: ${columns[*]}"
    done

    # Create table
    touch "$current_db/$table_name"
    success_message "Table '$table_name' created successfully."

    # Store metadata
    echo "$(IFS=:; echo "${columns[*]}")" > "$current_db/$table_name"
    echo "# Columns: ${columns[*]}" >> "$current_db/$table_name"
    echo "# Types: ${column_types[*]}" >> "$current_db/$table_name"
    echo "# Primary Key: $primary_key" >> "$current_db/$table_name"
}

# Show tables in the current database
show_tables() {
    # Validate database context
    [[ -z "$current_db" ]] && {
        error_message "No active database. Use 'use db_name' first."
        return
    }

    # Validate query syntax
    [[ "${queryWords[0]}" != "show" || "${queryWords[1]}" != "tables" || -n "${queryWords[2]}" ]] && {
        error_message "Invalid query. Use 'show tables'."
        return
    }

    # List tables in the current database directory
    local tables=($(ls "$current_db"))
    [[ ${#tables[@]} -eq 0 ]] && {
        info_message "No tables found in the current database."
        return
    }

    info_message "Tables in the current database:"
    for table in "${tables[@]}"; do
        info_message "• $table"
    done
}

# Drop a table
drop_table() {
    local table_name="${queryWords[2]}"

    # Validate database context
    [[ -z "$current_db" ]] && {
        error_message "No active database. Use 'use db_name' first."
        return
    }

    # Validate table name
    validate_name "$table_name" "table" || return 1

    # Check if table exists
    [[ ! -f "$current_db/$table_name" ]] && {
        error_message "Table '$table_name' does not exist."
        return
    }

    # Confirm deletion
    gum confirm "Are you sure you want to delete the table '$table_name'? This action cannot be undone." && {
        rm -f "$current_db/$table_name"
        success_message "Table '$table_name' dropped successfully."
    } || {
        info_message "Deletion canceled."
    }
}