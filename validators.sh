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
