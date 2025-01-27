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
    local a="$1" b="$2" op="$3"
    case $op in
        "=")  [[ $(echo "$a == $b" | bc) -eq 1 ]] && echo "true" || echo "false" ;;
        "!=") [[ $(echo "$a != $b" | bc) -eq 1 ]] && echo "true" || echo "false" ;;
        "<")  [[ $(echo "$a < $b" | bc) -eq 1 ]] && echo "true" || echo "false" ;;
        ">")  [[ $(echo "$a > $b" | bc) -eq 1 ]] && echo "true" || echo "false" ;;
        "<=") [[ $(echo "$a <= $b" | bc) -eq 1 ]] && echo "true" || echo "false" ;;
        ">=") [[ $(echo "$a >= $b" | bc) -eq 1 ]] && echo "true" || echo "false" ;;
        *)    echo "false" ;;
    esac
}

compare_strings() {
    local a="$1" b="$2" op="$3"
    case $op in
        "=")  [[ "$a" == "$b" ]] && echo "true" || echo "false" ;;
        "!=") [[ "$a" != "$b" ]] && echo "true" || echo "false" ;;
        *)    echo "false" ;;
    esac
}

compare_booleans() {
    local a="$1" b="$2" op="$3"
    case $op in
        "=")  [[ "$a" == "$b" ]] && echo "true" || echo "false" ;;
        "!=") [[ "$a" != "$b" ]] && echo "true" || echo "false" ;;
        *)    echo "false" ;;
    esac
}