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
    # Check if a database is selected
    [[ -z "$current_db" ]] && {
        error_message "No active database. Use 'use db_name' first."
        return 1
    }

    # Check if table name is provided
    if [[ -z "${queryWords[2]}" ]]; then
        error_message "Table name cannot be empty."
        return 1
    fi

    local table_name="${queryWords[2]}"
    local metadata_file="${current_db}/.${table_name}_metadata"
    local data_file="${current_db}/${table_name}.csv"

    # Check if table already exists
    if [ -f "$data_file" ] || [ -f "$metadata_file" ]; then
        error_message "Table '$table_name' already exists."
        return 1
    fi

    # Check if columns are provided
    if [[ -z "${queryWords[@]:3}" ]]; then
        error_message "No columns provided. Use format: CREATE TABLE <table_name> <col1(type)> <col2(type)> ..."
        return 1
    fi

    # Process columns and types
    local columns_input="${queryWords[@]:3}"
    local columns=()
    local column_types=()
    local valid=true

    IFS=' ' read -r -a columns_array <<< "$columns_input"

    for column in "${columns_array[@]}"; do
        if [[ "$column" =~ ^([a-zA-Z_][a-zA-Z0-9_]*)\((int|float|string|bool)\)$ ]]; then
            local col_name="${BASH_REMATCH[1]}"
            local col_type="${BASH_REMATCH[2]}"

            # Check for duplicate column names
            if [[ " ${columns[@]} " =~ " ${col_name} " ]]; then
                error_message "Duplicate column name '$col_name'."
                valid=false
                break
            fi

            columns+=("$col_name")
            column_types+=("$col_type")
        else
            error_message "Invalid column format '$column'. Use format: column_name(type)."
            valid=false
            break
        fi
    done

    if [ "$valid" = false ]; then
        return 1
    fi

    # Get primary key
    local primary_key=""
    while true; do
        primary_key=$(gum input --placeholder "Enter primary key column" --prompt "> ")
        if [[ " ${columns[@]} " =~ " ${primary_key} " ]]; then
            break
        else
            error_message "Primary key must be one of: ${columns[*]}"
        fi
    done

    # Create metadata file
    echo "columns:$(IFS=,; echo "${columns[*]}")" > "$metadata_file"
    echo "types:$(IFS=,; echo "${column_types[*]}")" >> "$metadata_file"
    echo "primary_key:$primary_key" >> "$metadata_file"

    # Create CSV file with header
    echo "$(IFS=,; echo "${columns[*]}")" > "$data_file"
    success_message "Table '$table_name' created successfully."
}


# inset into table
insert_into_table() {
    local table_name="$1"
    shift
    local values=("$@")

    # Check if a database is selected
    [[ -z "$current_db" ]] && {
        error_message "You are not connected to a database. Use 'use db_name' first."
        return 1
    }

    # Path to the table and metadata files
    local table_file="${current_db}/${table_name}.csv"
    local metadata_file="${current_db}/.${table_name}_metadata"

    # Check if table exists
    [[ ! -f "$table_file" || ! -f "$metadata_file" ]] && {
        error_message "Table '$table_name' does not exist."
        return 1
    }

    # Read metadata
    local columns=($(grep "^columns:" "$metadata_file" | cut -d':' -f2 | tr ',' ' '))
    local column_types=($(grep "^types:" "$metadata_file" | cut -d':' -f2 | tr ',' ' '))
    local primary_key=$(grep "^primary_key:" "$metadata_file" | cut -d':' -f2)

    # Validate number of values
    [[ ${#values[@]} -ne ${#columns[@]} ]] && {
        error_message "Expected ${#columns[@]} values, got ${#values[@]}."
        return 1
    }

    # Validate data types
    for ((i=0; i<${#values[@]}; i++)); do
        case "${column_types[$i]}" in
            int)
                if [[ ! "${values[$i]}" =~ ^-?[0-9]+$ ]]; then
                    error_message "Invalid data type for column '${columns[$i]}'. Expected integer, got '${values[$i]}'."
                    return 1
                fi
                ;;
            float)
                if [[ ! "${values[$i]}" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
                    error_message "Invalid data type for column '${columns[$i]}'. Expected float, got '${values[$i]}'."
                    return 1
                fi
                ;;
            string)
                # Strings should be enclosed in quotes
                if [[ ! "${values[$i]}" =~ ^\".*\"$ ]]; then
                    error_message "Invalid data type for column '${columns[$i]}'. Expected string (enclosed in quotes), got '${values[$i]}'."
                    return 1
                fi
                ;;
            bool)
                if [[ ! "${values[$i]}" =~ ^(true|false)$ ]]; then
                    error_message "Invalid data type for column '${columns[$i]}'. Expected boolean (true/false), got '${values[$i]}'."
                    return 1
                fi
                ;;
            *)
                error_message "Unknown data type '${column_types[$i]}' for column '${columns[$i]}'."
                return 1
                ;;
        esac
    done

    # Check primary key uniqueness
    local primary_key_index=$(echo "${columns[@]}" | tr ' ' '\n' | grep -n "^${primary_key}$" | cut -d':' -f1)
    local primary_key_value="${values[$((primary_key_index-1))]}"

    if cut -d',' -f"$primary_key_index" "$table_file" | grep -q "^${primary_key_value}$"; then
        error_message "Primary key '$primary_key_value' already exists."
        return 1
    fi

    # Insert into CSV (using commas)
    echo "$(IFS=,; echo "${values[*]}")" >> "$table_file"
    success_message "Data inserted successfully into '$table_name'."
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
    local tables=($(ls "$current_db" | grep -E '^[^_]+\.csv$' | sed 's/\.csv$//'))
    [[ ${#tables[@]} -eq 0 ]] && {
        info_message "No tables found in the current database."
        return
    }

    info_message "Tables in the current database:"
    for table in "${tables[@]}"; do
        info_message "$table"
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

    # Define table and metadata file paths
    local table_file="${current_db}/${table_name}.csv"
    local metadata_file="${current_db}/.${table_name}_metadata"

    # Check if table exists
    if [[ ! -f "$table_file" && ! -f "$metadata_file" ]]; then
        error_message "Table '$table_name' does not exist."
        return
    fi

    # Confirm deletion
    gum confirm "Are you sure you want to delete the table '$table_name'? This action cannot be undone." && {
        # Delete both the table file and metadata file
        rm -f "$table_file" "$metadata_file"
        success_message "Table '$table_name' dropped successfully."
    } || {
        info_message "Deletion canceled."
    }
}

