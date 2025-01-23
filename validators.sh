#!/bin/bash
source sql_config.sh
source utils.sh

isValidName() {
    local name="$1"
    local max_length=$((NAMEDATALEN - 1))
    
    # check empty name
    [[ -z "$name" ]] && return 1
    
    # check length
    [[ "${#name}" -gt "$max_length" ]] && return 1
    
    # check naming rules
    [[ "$name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || return 1
    
    return 0
}

# validate create database query (if it is valid query, return 0)
validate_create_database() {
    local query="$1"
    local db_name=$(echo "$query" | sed -nE 's/CREATE DATABASE ([^;]+);?/\1/p')
    
    # validate name
    isValidName "$db_name" || {
        error_message "Invalid database name: '$db_name'"
        return 1
    }
    # normalize name
    db_name=$(normalizeName "$db_name")

    # check existence
    [ -d "$SCRIPT_DIR/$db_name" ] && {
        error_message "Database '$db_name' already exists"
        return 1
    }
    
    return 0
}




