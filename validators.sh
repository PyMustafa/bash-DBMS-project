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
