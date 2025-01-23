createDb(){
    if [[ -z "${words[2]}" ]]; then
        echo "Error: Database name cannot be empty."
        return
    fi
    dbName="${words[2]}" 
    if ! [[ "$dbName" =~ ^[a-zA-Z] ]]; then
        echo "Error: Database name must start with a letter."
        return
    fi

    if [ -d "$dbName" ]; then
        echo "Error: Database '$dbName' already exists."
        return
    fi

    if [ -e "$dbName" ]; then
        echo "Error: '$dbName' already exists as a file or directory."
        return
    fi

    mkdir "$dbName"
    echo "Database '$dbName' created successfully."
}
