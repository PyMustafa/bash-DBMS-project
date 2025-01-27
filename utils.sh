normalize_name() {
    local name="$1"
    local max_length=$((NAMEDATALEN - 1))
    
    # convert to lowercase if configured
    [[ "$CASE_INSENSITIVE_NAMES" == true ]] && name="${name,,}"
    
    # truncate to maximum allowed length
    echo "${name:0:$max_length}"
}

error_message() {
gum style --foreground 196 "Error: $1"
}

success_message(){
gum style --foreground 82 "$1"

}

info_message(){
gum style --foreground 39 "$1"
}

invalid_query_message(){
    error_message "Invalid query, $1"
}


# Comparison functions
compare_numbers() {
    local val1="$1" val2="$2" op="$3"
    case "$op" in
        "=")  result=$(echo "$val1 == $val2" | bc -l) ;;
        "!=") result=$(echo "$val1 != $val2" | bc -l) ;;
        "<")  result=$(echo "$val1 < $val2" | bc -l) ;;
        ">")  result=$(echo "$val1 > $val2" | bc -l) ;;
        "<=") result=$(echo "$val1 <= $val2" | bc -l) ;;
        ">=") result=$(echo "$val1 >= $val2" | bc -l) ;;
        *)    echo "false"; return 1 ;;
    esac
    [[ "$result" -eq 1 ]] && echo "true" || echo "false"
}

compare_strings() {
    local val1="$1" val2="$2" op="$3"
    case "$op" in
        "=")  [[ "$val1" == "$val2" ]] && echo "true" || echo "false" ;;
        "!=") [[ "$val1" != "$val2" ]] && echo "true" || echo "false" ;;
        *)    echo "false" ;;
    esac
}

compare_booleans() {
    local val1="$1" val2="$2" op="$3"
    compare_strings "$val1" "$val2" "$op"  # Reuse string comparison
}