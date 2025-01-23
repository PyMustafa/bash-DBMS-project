#!/bin/bash
# Database main functions

# Global variable to store the current database name
currentDb=""

# Create a new database
createDb(){
    # Check if the user is inside a database
    if [[ -n "$currentDb" ]]; then
        gum style --foreground 196 "Error: You cannot create a database inside '$currentDb'. Use 'exit' first."
        return
    fi

    # Check if the query is valid
    if [[ -z "${queryqueryWords[2]}" ]]; then
        gum style --foreground 196 "Error: Database name cannot be empty."
        return
    fi
    dbName="${queryqueryWords[2]}" 
    if ! [[ "$dbName" =~ ^[a-zA-Z] ]]; then
        gum style --foreground 196 "Error: Database name must start with a letter."
        return
    fi

    if [ -d "$dbName" ]; then
        gum style --foreground 196 "Error: Database '$dbName' already exists."
        return
    fi

    if [ -e "$dbName" ]; then
        gum style --foreground 196 "Error: '$dbName' already exists as a file or directory."
        return
    fi

    # Create the database directory and display success message
    mkdir "$dbName"
    gum style --foreground 82 "Database '$dbName' created successfully."
}

# List all databases
listDb() {
    # Check if the user is inside a database
    if [[ -n "$currentDb" ]]; then
        gum style --foreground 196 "Error: You cannot list databases inside '$currentDb'. Use 'exit' first."
        return
    fi

    # Check if the query is valid
    if [[ "${queryWords[0]}" != "list" || "${queryWords[1]}" != "database" ]]; then
        gum style --foreground 196 "Invalid query. Please enter 'list database'."
        return
    fi
    
    # List all directories in the current directory
    gum style --foreground 39 "Listing all databases:"
    for db in */; do
        if [ -d "$db" ]; then
            gum style --foreground 39 "${db%/}"
        fi
    done
}

# Use a database
useDb() {
    # Check if the user is inside a database
    if [[ "${queryWords[0]}" != "use" || -z "${queryWords[1]}" ]]; then
        gum style --foreground 196 "Invalid query. Please enter 'use yourDbName'."
        return
    fi

    # Check if the database exists
    dbName="${queryWords[1]}" 
    if [ ! -d "$dbName" ]; then
        gum style --foreground 196 "Error: Database '$dbName' does not exist."
        return
    fi
    # Change to the database directory and display success message
    currentDb="$dbName" 
    cd "$dbName" || { gum style --foreground 196 "Failed to enter database directory."; return; }
    gum style --foreground 82 "Now using database '$dbName'."
}

# Drop a database
dropDb() {
    # Check if the user is inside a database
    if [[ -n "$currentDb" ]]; then
        gum style --foreground 196 "Error: You cannot drop a database inside '$currentDb'. Use 'exit' first."
        return
    fi

    # Check if the query is valid
    if [[ "${queryWords[0]}" != "drop" || "${queryWords[1]}" != "database" ]]; then
        gum style --foreground 196 "Invalid query. Please enter 'drop database db_name'."
        return
    fi
    if [[ -z "${queryWords[2]}" ]]; then
        gum style --foreground 196 "Error: Database name cannot be empty."
        return
    fi


    dbName="${queryWords[2]}" 
    if [ ! -d "$dbName" ]; then
        gum style --foreground 196 "Error: Database '$dbName' does not exist."
        return
    fi

    # Confirm the deletion and remove the database directory
    gum confirm "Are you sure you want to delete the database '$dbName'? This action cannot be undone." && \
        { rm -rf "$dbName"; gum style --foreground 82 "Database '$dbName' dropped successfully."; } || \
        gum style --foreground 39 "Deletion canceled."
}

# Exit the current database
exitDb() {
    # Check if the user is inside a database
    if [[ -z "$currentDb" ]]; then
        gum style --foreground 196 "Error: You are not inside any database."
        return
    fi

    # Change to the parent directory and display success message
    cd ..
    currentDb="" 
    gum style --foreground 82 "Exited the current database."
}


createTable() {
    # Check if the user is inside a database
    if [[ -z "$currentDb" ]]; then
        gum style --foreground 196 "Error: No active database. Use 'use db_name' first."
        return
    fi

    # Check if the query is valid
    if [[ -z "${queryWords[2]}" ]]; then
        gum style --foreground 196 "Error: Table name cannot be empty."
        return
    fi
    table_name=${queryWords[2]}

    # Check if columns are provided
    if [[ -z "${queryWords[@]:3}" ]]; then
        gum style --foreground 196 "Error: No columns provided. Use format: create table table_name col1(type) col2(type)."
        return
    fi

    # Check if table name starts with a number
    if [[ "$table_name" =~ ^[0-9] ]]; then
        gum style --foreground 196 "Error: Table name cannot start with a number."
        return
    fi

    # Check if table already exists in the current directory
    if [ -f "$table_name" ]; then
        gum style --foreground 196 "Error: Table '$table_name' already exists."
        return
    fi

    # Check for columns and their data types from the query
    columns_input="${queryWords[@]:3}"  # Everything after the table name
    columns=()
    column_types=()
    valid=true
    IFS=' ' read -r -a columns_array <<< "$columns_input"  # Split by space

    for column in "${columns_array[@]}"; do
        # Split the column into name and type
        if [[ "$column" =~ ^[a-zA-Z_][a-zA-Z0-9_]*\([a-zA-Z_]+\)$ ]]; then
            col_name=$(echo $column | cut -d'(' -f1)
            col_type=$(echo $column | cut -d'(' -f2 | cut -d')' -f1)

            # Check if column name is unique
            if [[ " ${columns[@]} " =~ " ${col_name} " ]]; then
                gum style --foreground 196 "Error: Duplicate column name '$col_name'."
                valid=false
                break
            fi

            # Validate column type
            if [[ "$col_type" == "string" || "$col_type" == "int" || "$col_type" == "float" || "$col_type" == "bool" ]]; then
                columns+=("$col_name")
                column_types+=("$col_type")
            else
                gum style --foreground 196 "Error: Invalid column type '$col_type' for column '$col_name'. Supported types are: string, int, float, bool."
                valid=false
                break
            fi
        else
            gum style --foreground 196 "Error: Invalid column format '$column'. Use format: column_name(type)."
            valid=false
            break
        fi
    done

    # If valid, ask for the primary key
    if [ "$valid" = true ]; then
        while true; do
            # echo "Please enter the primary key column: " 
            # read primary_key
            primary_key=$(gum input --placeholder "Please enter the primary key column" --prompt "> ")
            if [[ " ${columns[@]} " =~ " ${primary_key} " ]]; then
                break
            else
                gum style --foreground 196 "Error: The primary key must be one of the defined columns: ${columns[*]}"
            fi
        done

        # Create the table
        touch "$table_name"  # Create the table in the current directory
        gum style --foreground 82 "Table '$table_name' created successfully."

        # Store the column names in the first line of the table file
        echo "$(IFS=:; echo "${columns[*]}")" > "$table_name"

        # Store metadata about columns, types, and primary key
        echo "# Columns: ${columns[*]}" >> "$table_name"
        echo "# Types: ${column_types[*]}" >> "$table_name"
        echo "# Primary Key: $primary_key" >> "$table_name"
    fi
}


showTables() {
    # Check if the user is inside a database
    if [[ -z "$currentDb" ]]; then
        gum style --foreground 196 "Error: No active database. Use 'use db_name' first."
        return
    fi
    # Check if the query is exactly "show tables"
    if [[ "${queryWords[0]}" != "show" || "${queryWords[1]}" != "tables" || -n "${queryWords[2]}" ]]; then
        gum style --foreground 196 "Error: Invalid query. Use 'show tables'."
        return
    fi

    # List all files (tables) in the current directory
    tables=($(ls))
    if [[ ${#tables[@]} -eq 0 ]]; then
        gum style --foreground 39 "No tables found in the current directory."
    else
        gum style --foreground 39 "Tables in the current directory:"
        for table in "${tables[@]}"; do
            gum style --foreground 39 "• $table"  # Use a bullet point instead of a hyphen
        done
    fi
}