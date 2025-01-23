# Database main functions
createDb(){
    if [[ -z "${queryWords[2]}" ]]; then
        gum style --foreground 196 "Error: Database name cannot be empty."
        return
    fi
    dbName="${queryWords[2]}" 
    if ! [[ "$dbName" =~ ^[a-zA-Z] ]]; then
        gum style --foreground 196 "Error: Database name must start with a letter."
        return
    fi

    if [ -d "$dbName" ]; then
        gum style --foreground 196 "Error: Database '$dbName' already exists."
        return
    fi

    if [ -e "$dbName" ]; then
        gum style --foreground 196 "Error: '$dbName' already exists as a file or directory."
        return
    fi

    mkdir "$dbName"
    gum style --foreground 82 "Database '$dbName' created successfully."
}

listDb() {
    if [[ "${queryWords[0]}" != "list" || "${queryWords[1]}" != "database" ]]; then
        gum style --foreground 196 "Invalid query. Please enter 'list database'."
        return
    fi
    
    gum style --foreground 39 "Listing all databases:"
    for db in */; do
        if [ -d "$db" ]; then
            gum style --foreground 39 "${db%/}"
        fi
    done
}

useDb() {
    if [[ "${queryWords[0]}" != "use" || -z "${queryWords[1]}" ]]; then
        gum style --foreground 196 "Invalid query. Please enter 'use yourDbName'."
        return
    fi
    dbName="${queryWords[1]}" 
    if [ ! -d "$dbName" ]; then
        gum style --foreground 196 "Error: Database '$dbName' does not exist."
        return
    fi
    cd "$dbName" || { echo "Failed to enter database directory."; return; }
    gum style --foreground 82 "Now using database '$dbName'."
}

dropDb() {
    if [[ "${queryWords[0]}" != "drop" || "${queryWords[1]}" != "database" ]]; then
        gum style --foreground 196 "Invalid query. Please enter 'drop database db_name'."
        return
    fi
    if [[ -z "${queryWords[2]}" ]]; then
        gum style --foreground 196 "Error: Database name cannot be empty."
        return
    fi

    dbName="${queryWords[2]}" 
    if [ ! -d "$dbName" ]; then
        gum style --foreground 196 "Error: Database '$dbName' does not exist."
        return
    fi

    rm -rf "$dbName"
    gum style --foreground 82 "Database '$dbName' dropped successfully."
}