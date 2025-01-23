normalizeName() {
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