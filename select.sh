#!/bin/bash

# a function to split a select statement into columns and where clause arrays
select_split() {
    

    # return columns, table name, and where clause as delimited strings
    echo "$(IFS=,; echo "${columns[*]}"):$tableName:$(IFS=,; echo "${whereClause[*]}")"
}

execute_select(){
    local queryWords=("$@")
    
    local valid=true
    local where=false


    #* splitting the query and validating ************
    local fromIndex whereIndex
    local columns=() 
    local tableName 
    local whereClause=()

    # find position of 'from'
    for ((fromIndex=0; fromIndex<${#queryWords[@]}; fromIndex++)); do
        [[ "${queryWords[$fromIndex]}" == "from" ]] && break
    done

    # !error if 'from' not found
    if (( fromIndex >= ${#queryWords[@]} )); then
        invalid_query_message "messing from"
        return 1
    fi

    # extract table name (word after 'from')
    (( fromIndex + 1 < ${#queryWords[@]} )) && tableName="${queryWords[$fromIndex + 1]}"

    # ! validate table name
    validate_name "$tableName" "table" || return 1

    # check if table exists
    local normalized_tableName=$(normalize_name "$tableName")

    [[ ! -f "$current_db/$normalized_tableName.csv" ]] && {
        error_message "Table '$tableName' does not exist."
        return 1
    }
    echo "table is exist" 


    # find position of 'where' (after table name)
    for ((whereIndex=fromIndex+2; whereIndex<${#queryWords[@]}; whereIndex++)); do
        [[ "${queryWords[$whereIndex]}" == "where" ]] && break
    done

    # if 'where' not found, check if the table is the end of the query, if not, error
    if (( whereIndex >= ${#queryWords[@]} )) && (( fromIndex + 2 < ${#queryWords[@]} )); then
        error_message "Syntax error: Unexpected input after table name."
        return 1
    fi

    # if 'where' found but the clause is empty, error
    if (( whereIndex < ${#queryWords[@]} )) && [[ -z "${queryWords[$whereIndex + 1]}" ]]; then
        error_message "Syntax error: Empty WHERE clause."
        return 1
    fi

    # extract WHERE clause (words after 'where')
    if (( whereIndex < ${#queryWords[@]} )); then
        whereClause=("${queryWords[@]:$((whereIndex + 1))}")
    fi


    # ! validate WHERE clause if provided
    if [[ ${#whereClause[@]} -gt 0 ]]; then
        validate_where_clause "$tableName" ${whereClause[@]} || return 1
        where=true
    fi

    # extract columns (words between 'select' and 'from')
    local columns=("${queryWords[@]:1:$((fromIndex - 1))}")

    # ! validate columns
    for column in "${columns[@]}"; do
        validate_name "$column" "column" || return 1
    done

}