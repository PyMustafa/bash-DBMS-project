#!/bin/bash
source sql_config.sh
source utils.sh

# function to validate table, column and database names
# usage: validate_name "name" "type", type can be table, column or database
validate_name() {
    local name="$1"
    local type="$2"
    local normalized_name=$(normalize_name "$name")

    # empty check
    [[ -z "$name" ]] && {
        error_message "$type name cannot be empty"
        return 1
    }
    # check if the name is a reserved keyword
    for keyword in "${KEYWORDS[@]}"; do
        [[ "$normalized_name" == "$keyword" ]] && {
            error_message "$type name cannot be a reserved keyword: $name"
            return 1
    }
    done

    # naming rules
    [[ ! "$name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] && {
        error_message "Invalid $type name: $name"
        return 1
    }
    return 0
}

validate_int() {
    [[ "$1" =~ ^-?[0-9]+$ ]] || {
        error_message "'$1' is not a valid integer."
        return 1
    }
}

validate_float() {
    [[ "$1" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] || {
        error_message "'$1' is not a valid float."
        return 1
    }
}

validate_bool() {
    [[ "$1" =~ ^(true|false)$ ]] || {
        error_message "'$1' is not a valid boolean (true/false)."
        return 1
    }
}

validate_string() {
    # No validation needed for strings by default
    return 0
}

validate_data() {
    local value="$1"
    local type="$2"

    case "$type" in
        int) validate_int "$value" ;;
        float) validate_float "$value" ;;
        bool) validate_bool "$value" ;;
        string) validate_string "$value" ;;
        *) error_message "Unknown type '$type'"; return 1 ;;
    esac
}

validate_where_clause() {
    local tableName="$1"
    info_message "$tableName"
    shift
    local whereClause=("$@")
    local normalized_tableName=$(normalize_name "$tableName")
    local metadataFile="$current_db/.$normalized_tableName"
    info_message "${#whereClause[@]}" 
    info_message "${whereClause[@]}" 
    # Validate clause structure
    if [[ ${#whereClause[@]} -ne 3 ]]; then
        error_message "Invalid WHERE format. Required: COLUMN OPERATOR VALUE"
        return 1
    fi

    local column="${whereClause[0]}"
    local operator="${whereClause[1]}"
    local value="${whereClause[2]}"

    # Load metadata
    if [[ ! -f "$metadataFile" ]]; then
        error_message "Metadata file for table '$tableName' not found"
        return 1
    fi

    # Parse metadata
    local columns=()
    local types=()
    while IFS= read -r line; do
        case "$line" in
            columns:*)
                IFS=',' read -ra cols <<< "${line#columns:}"
                columns=("${cols[@]}")
                ;;
            types:*)
                IFS=',' read -ra typs <<< "${line#types:}"
                types=("${typs[@]}")
                ;;
        esac
    done < "$metadataFile"

    # Validate metadata consistency
    if [[ ${#columns[@]} -ne ${#types[@]} ]]; then
        error_message "Metadata corruption in '$tableName': Columns/Types mismatch"
        return 1
    fi

    # Validate column exists
    local col_index=-1
    for i in "${!columns[@]}"; do
        if [[ "${columns[$i]}" == "$column" ]]; then
            col_index=$i
            break
        fi
    done

    if [[ $col_index -eq -1 ]]; then
        error_message "Column '$column' does not exist in table '$tableName'"
        return 1
    fi

    # Validate operator
    case "$operator" in
        "="|"!="|"<"|">"|"<="|">=") ;;
        *) error_message "Invalid operator: '$operator'. Supported: = != < > <= >="
        return 1 ;;
    esac

    # Get column type and validate value
    local column_type="${types[$col_index]}"
    validate_data "$value" "$column_type" || return 1
    
    

    return 0
}