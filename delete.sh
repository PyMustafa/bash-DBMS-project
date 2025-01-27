#!/bin/bash

# Function to delete all rows from a table
delete_all_from_table() {
    local tableName="$1"
    local normalized_tableName=$(normalize_name "$tableName")
    local tableFile="${current_db}/${normalized_tableName}.csv"
    local metadataFile="${current_db}/.${normalized_tableName}"

    # Validate table existence
    [[ ! -f "$tableFile" || ! -f "$metadataFile" ]] && {
        error_message "Table '$tableName' does not exist."
        return 1
    }

    # Confirm deletion
    gum confirm "Are you sure you want to delete all rows from '$tableName'? This action cannot be undone." && {
        # Keep the header and remove all rows
        header=$(head -n 1 "$tableFile")
        echo "$header" > "$tableFile"
        success_message "All rows deleted from '$tableName'."
    } || {
        info_message "Deletion canceled."
    }
}

# Function to delete rows based on a condition
delete_from_table_where() {
    local tableName="$1"
    local whereClause=("${@:2}")
    local normalized_tableName=$(normalize_name "$tableName")
    local tableFile="${current_db}/${normalized_tableName}.csv"
    local metadataFile="${current_db}/.${normalized_tableName}"

    # Validate table existence
    [[ ! -f "$tableFile" || ! -f "$metadataFile" ]] && {
        error_message "Table '$tableName' does not exist."
        return 1
    }

    # Validate WHERE clause
    validate_where_clause "$tableName" "${whereClause[@]}" || return 1

    # Parse WHERE clause
    local where_col="${whereClause[0]}"
    local where_op="${whereClause[1]}"
    local where_val="${whereClause[2]}"

    # Load metadata
    local columns=() types=()
    while IFS= read -r line; do
        case "$line" in
            columns:*) IFS=',' read -ra columns <<< "${line#columns:}" ;;
            types:*)   IFS=',' read -ra types <<< "${line#types:}" ;;
        esac
    done < "$metadataFile"

    # Find WHERE column index and type
    local where_col_idx=-1 where_type
    for i in "${!columns[@]}"; do
        if [[ "${columns[$i]}" == "$where_col" ]]; then
            where_col_idx=$i
            where_type="${types[$i]}"
            break
        fi
    done

    # Process table data
    local header=$(head -n 1 "$tableFile")
    local rows=()
    local deleted=0

    while IFS=',' read -ra row; do
        # Skip header
        [[ "$(IFS=,; echo "${row[*]}")" == "$header" ]] && continue

        # Check WHERE condition
        local field_value="${row[$where_col_idx]}"
        case "$where_type" in
            int|float)
                compare_result=$(compare_numbers "$field_value" "$where_val" "$where_op")
                ;;
            string|bool)
                compare_result=$(compare_strings "$field_value" "$where_val" "$where_op")
                ;;
            *)
                error_message "Unsupported type '$where_type'"
                return 1
                ;;
        esac

        # Skip rows that don't match the condition
        [[ "$compare_result" != "true" ]] && rows+=("$(IFS=,; echo "${row[*]}")") || ((deleted++))
    done < "$tableFile"

    # Write updated rows back to the file
    echo "$header" > "$tableFile"
    for row in "${rows[@]}"; do
        echo "$row" >> "$tableFile"
    done

    success_message "Deleted $deleted row(s) from '$tableName'."
}

# Main DELETE function
delete_from_table() {
    local queryWords=("$@")
    local tableName="${queryWords[2]}"

    # Validate database context
    [[ -z "$current_db" ]] && {
        error_message "No active database. Use 'use db_name' first."
        return 1
    }

    # Validate basic syntax
    if [[ "${queryWords[0]}" != "delete" || "${queryWords[1]}" != "from" ]]; then
        error_message "Invalid DELETE syntax. Use: DELETE FROM tableName [WHERE condition]"
        return 1
    fi

    # Check for WHERE clause
    if [[ "${queryWords[3]}" == "where" ]]; then
        delete_from_table_where "$tableName" "${queryWords[@]:4}"
    else
        delete_all_from_table "$tableName"
    fi
}