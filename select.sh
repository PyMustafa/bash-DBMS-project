#!/bin/bash

# a function to split a select statement into columns and where clause arrays
select_split() {
    local queryWords=("$@")
    local fromIndex whereIndex
    local columns=() tableName whereClause=()

    # find position of 'from'
    for ((fromIndex=0; fromIndex<${#queryWords[@]}; fromIndex++)); do
        [[ "${queryWords[$fromIndex]}" == "from" ]] && break
    done

    # error if 'from' not found
    if (( fromIndex >= ${#queryWords[@]} )); then
        invalid_query_message "messing from"
        return 1
    fi

    # extract columns (words between 'select' and 'from')
    columns=("${queryWords[@]:1:$((fromIndex - 1))}")

    # extract table name (word after 'from')
    (( fromIndex + 1 < ${#queryWords[@]} )) && tableName="${queryWords[$fromIndex + 1]}"

    # find position of 'where' (after table name)
    for ((whereIndex=fromIndex+2; whereIndex<${#queryWords[@]}; whereIndex++)); do
        [[ "${queryWords[$whereIndex]}" == "where" ]] && break
    done

    # extract WHERE clause (words after 'where')
    if (( whereIndex < ${#queryWords[@]} )); then
        whereClause=("${queryWords[@]:$((whereIndex + 1))}")
    fi

    # return columns, table name, and where clause as delimited strings
    echo "$(IFS=,; echo "${columns[*]}"):$tableName:$(IFS=,; echo "${whereClause[*]}")"
}

execute_select(){
  local queryWords=("$@")

  # split into table, columns and where clause
  if ! select_split_result=$(select_split "${queryWords[@]}"); then
      exit 1
  fi

  IFS=':' read -ra selectQueryParts <<< "$select_split_result"
  IFS=',' read -ra columns <<< "${selectQueryParts[0]}" 
  tableName="${selectQueryParts[1]}"
  IFS=',' read -ra whereClause <<< "${selectQueryParts[2]}"
  
  # validate table name
  validate_name "$tableName" "table" || return 1
  echo "table name is valid" 
  echo $current_db
  # check if table exists
  [[ ! -f "$current_db/$tableName.csv" ]] && {
      error_message "Table '$tableName' does not exist."
      return 1
  }
    echo "table is exist" 
}