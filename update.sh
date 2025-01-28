#!/bin/bash

execute_update() {
    local args=("$@")
    
    # validate basic syntax
    if [[ "${args[0]}" != "update" || "${#args[@]}" -lt 4 ]]; then
        error_message "Invalid UPDATE syntax"
        return 1
    fi

    # get table name and check if it exists
    local table="${args[1]}"
    normalized_tableName=$(normalize_name "$table")
    local table_file="${current_db}/${normalized_tableName}.csv"
    local metadata_file="${current_db}/.${normalized_tableName}"
    
    if [[ ! -f "$table_file" || ! -f "$metadata_file" ]]; then
        error_message "Table '$table' does not exist"
        return 1
    fi

    # load table metadata
    local columns=() types=()
    while IFS= read -r line; do
        case "$line" in
            columns:*) IFS=',' read -ra columns <<< "${line#columns:}" ;;
            types:*)   IFS=',' read -ra types <<< "${line#types:}" ;;
        esac
    done < "$metadata_file"

    # parse set and where positions
    local set_pos=-1 where_pos=-1
    for i in "${!args[@]}"; do
        case "${args[$i]}" in
            "set") set_pos=$i ;;
            "where") where_pos=$i ;;
        esac
    done

    if [[ $set_pos -eq -1 ]]; then
        error_message "Missing SET clause"
        return 1
    fi

    # extract set clause (handle spaces)
    local set_clause
    if [[ $where_pos -ne -1 ]]; then
        set_clause=$(IFS=' '; echo "${args[*]:set_pos+1:where_pos-set_pos-1}")
    else
        set_clause=$(IFS=' '; echo "${args[*]:set_pos+1}")
    fi

    IFS='=' read -r update_col update_val <<< "$set_clause"
    update_col=$(echo "$update_col" | xargs)
    update_val=$(echo "$update_val" | xargs)
    update_val=$(echo "$update_val" | sed 's/^"\|"$//g')

    # validate update column
    local update_col_idx=-1 update_type
    for i in "${!columns[@]}"; do
        if [[ "${columns[$i]}" == "$update_col" ]]; then
            update_col_idx=$i
            update_type="${types[$i]}"
            break
        fi
    done

    if [[ $update_col_idx -eq -1 ]]; then
        error_message "Column '$update_col' not found"
        return 1
    fi

    # validate value type
    case "$update_type" in
        int)    [[ "$update_val" =~ ^-?[0-9]+$ ]] || { error_message "Invalid integer"; return 1; } ;;
        float)  [[ "$update_val" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] || { error_message "Invalid float"; return 1; } ;;
        bool)   [[ "$update_val" =~ ^(true|false)$ ]] || { error_message "Invalid boolean"; return 1; } ;;
        string) update_val="\"$(echo "$update_val" | sed 's/"/\\"/g')\"" ;; 
    esac

    # parse where clause if present
    local where_col="" where_op="" where_val="" where_type="" where_col_idx=-1
    if [[ $where_pos -ne -1 ]]; then
        where_col="${args[where_pos+1]}"
        where_op="${args[where_pos+2]}"
        where_val=$(IFS=' '; echo "${args[*]:where_pos+3}")
        where_val=$(echo "$where_val" | sed 's/^"\|"$//g')

        # find where column index and type
        for i in "${!columns[@]}"; do
            if [[ "${columns[$i]}" == "$where_col" ]]; then
                where_col_idx=$i
                where_type="${types[$i]}"
                break
            fi
        done

        if [[ $where_col_idx -eq -1 ]]; then
            error_message " Where column '$where_col' not found"
            return 1
        fi
    fi

    # process updates
    local header=$(head -n 1 "$table_file")
    local updated=0
    local new_content=("$header")

    while IFS=',' read -ra row; do
        [[ "${row[*]}" == "$header" ]] && continue

        local should_update=true
        if [[ $where_pos -ne -1 ]]; then
            local field_val="${row[$where_col_idx]//\"}"

            case "$where_type" in
                int|float)
                    if ! update_compare_numbers "$field_val" "$where_val" "$where_op"; then
                        should_update=false
                    fi
                    ;;
                string)
                    if ! update_compare_strings "$field_val" "$where_val" "$where_op"; then
                        should_update=false
                    fi
                    ;;
                bool)
                    if ! update_compare_strings "$field_val" "$where_val" "$where_op"; then
                        should_update=false
                    fi
                    ;;
            esac
        fi

        if $should_update; then
            row[$update_col_idx]="$update_val"
            ((updated++))
        fi

        new_content+=("$(IFS=,; echo "${row[*]}")")
    done < <(tail -n +2 "$table_file")

    printf "%s\n" "${new_content[@]}" > "$table_file"
    info_message "Updated $updated row(s)"
    return 0
}
# helper functions for comparisons
update_compare_numbers() {
    local val1=$1 val2=$2 op=$3
    case $op in
        "=")  [[ $(echo "$val1 == $val2" | bc) -eq 1 ]] ;;
        "!=") [[ $(echo "$val1 != $val2" | bc) -eq 1 ]] ;;
        "<")  [[ $(echo "$val1 < $val2" | bc) -eq 1 ]] ;;
        ">")  [[ $(echo "$val1 > $val2" | bc) -eq 1 ]] ;;
        "<=") [[ $(echo "$val1 <= $val2" | bc) -eq 1 ]] ;;
        ">=") [[ $(echo "$val1 >= $val2" | bc) -eq 1 ]] ;;
        *)    false ;;
    esac
}

update_compare_strings() {
    local val1=$1 val2=$2 op=$3
    case $op in
        "=")  [[ "$val1" == "$val2" ]] ;;
        "!=") [[ "$val1" != "$val2" ]] ;;
        *)    false ;;
    esac
}