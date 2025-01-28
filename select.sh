#!/bin/bash
execute_select() {
    local queryWords=("$@")
    local valid=true
    local where=false

    # Find from clause position
    local fromIndex
    for ((fromIndex=1; fromIndex<${#queryWords[@]}; fromIndex++)); do
        [[ "${queryWords[$fromIndex]}" == "from" ]] && break
    done

    # validate from clause
    (( fromIndex >= ${#queryWords[@]} )) && {
        error_message "Missing FROM clause"
        return 1
    }

        # validate table exists
    local tableName="${queryWords[$fromIndex+1]}"
    local normalized_tableName=$(normalize_name "$tableName")
    local tableFile="${current_db}/${normalized_tableName}.csv"
    local metadataFile="${current_db}/.${normalized_tableName}"
    [[ ! -f "$tableFile" || ! -f "$metadataFile" ]] && {
        error_message "Table '$tableName' does not exist"
        return 1
    }

    # Read metadata
    local columns_metadata=() types_metadata=()
    while IFS= read -r line; do
        case "$line" in
            columns:*) IFS=',' read -ra columns_metadata <<< "${line#columns:}" ;;
            types:*)   IFS=',' read -ra types_metadata <<< "${line#types:}" ;;
        esac
    done < "$metadataFile"

    # Process where clause
    local whereClause=()
    local whereIndex=$((fromIndex+2))
    if (( whereIndex < ${#queryWords[@]} )) && [[ "${queryWords[$whereIndex]}" == "where" ]]; then
        whereClause=("${queryWords[@]:$((whereIndex+1))}")
        # validate where clause using existing validator
        validate_where_clause "$tableName" "${whereClause[@]}" || return 1
        where=true
    fi

    local columns=("${queryWords[@]:1:$((fromIndex-1))}")
    # validate selected columns
    if [[ "${columns[0]}" == "all" ]]; then
        columns=("${columns_metadata[@]}")
    else
        for col in "${columns[@]}"; do
            [[ ! " ${columns_metadata[@]} " =~ " $col " ]] && {
                error_message "Invalid column '$col'"
                return 1
            }
        done
    fi

    # get column indices
    local selected_indices=()
    for col in "${columns[@]}"; do
        for i in "${!columns_metadata[@]}"; do
            [[ "${columns_metadata[$i]}" == "$col" ]] && selected_indices+=($i)
        done
    done

    # prepare where components
    local where_col where_op where_val where_type where_index
    if $where; then
        where_col="${whereClause[0]}"
        where_op="${whereClause[1]}"
        where_val="${whereClause[2]}"
        
        # find where column index and type
        for i in "${!columns_metadata[@]}"; do
            [[ "${columns_metadata[$i]}" == "$where_col" ]] && {
                where_index=$i
                where_type="${types_metadata[$i]}"
                break
            }
        done
    fi

    # process table data
    local header=$(head -n 1 "$tableFile")
    local rows=()
    while IFS=',' read -ra fields; do
        # skip header
        [[ "$(IFS=,; echo "${fields[*]}")" == "$header" ]] && continue

        # apply where filtering
        if $where; then
            local field_value="${fields[$where_index]}"
            case "$where_type" in
                int)
                    field_value=$((field_value))
                    where_val_num=$((where_val))
                    compare_result=$(compare_numbers "$field_value" "$where_val_num" "$where_op")
                    ;;
                float)
                    compare_result=$(compare_numbers "${field_value}" "${where_val}" "$where_op")
                    ;;
                string)
                    field_value="${field_value//\"/}"
                    where_val_clean="${where_val//\"/}"
                    compare_result=$(compare_strings "$field_value" "$where_val_clean" "$where_op")
                    ;;
                bool)
                    compare_result=$(compare_booleans "$field_value" "$where_val" "$where_op")
                    ;;
                *)
                    error_message "Unsupported type '$where_type'"
                    return 1
                    ;;
            esac
            [[ "$compare_result" != "true" ]] && continue
        fi

        # select columns
        local selected_row=()
        for idx in "${selected_indices[@]}"; do
            selected_row+=("${fields[$idx]}")
        done
        rows+=("$(IFS=,; echo "${selected_row[*]}")")
    done < "$tableFile"

    # display results
    if [[ ${#rows[@]} -eq 0 ]]; then
        info_message "No results found"
    else
        # create array with header + data
        local full_output=("$(IFS=','; echo "${columns[*]}")" "${rows[@]}")

        # display in table
        printf "%s\n" "${full_output[@]}" | gum table --separator "," \
            --cell.background="134" \
            --header.background="99" \
            --cell.foreground="255" \
            --selected.background="0" \
            --height=10
    fi
    

    return 0
}