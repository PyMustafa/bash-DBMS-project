#!/bin/bash
. ./database_Funs.sh
clear
gum style --foreground 212 --border-foreground 212 --border double --align center --width 50 --padding "1 3" "Welcome to our DBMS!"
gum style --foreground 156 "Write your SQL command like that:"
gum style --foreground 39 ". use dbname"
gum style --foreground 39 ". list database"
gum style --foreground 39 ". drop database dbname"
gum style --foreground 39 ". create database dbname"
# gum style --foreground 39 ". drop table tablename"
gum style --foreground 39 ". show tables"
gum style --foreground 39 ". create table tableName id(int) name(string) .. "
echo ""
# Array of valid SQL keywords for each function
keywords=("create" "drop" "list" "use" "exit" "show")

while true; do
    # take user query and save each word in queryWords array
    query=$(gum input --placeholder "Enter your SQL query (or '0' to quit)" --prompt "> " --width 50)
    gum style --foreground 156 "$query"
    queryWords=($query)

    # Exit from the loop if user enters '0' as the first word in the statement
    if [[ "${queryWords[0]}" == "0" ]]; then
        gum style --foreground 9 "Exiting program..."
        break
    fi

    # choose between database operations to execute the functons based on the first word in the statement
    if [[ " ${keywords[@]} " =~ " ${queryWords[0]} " ]]; then
        case ${queryWords[0]} in
            create)
                if [[ "${queryWords[1]}" == "database" ]]; then
                    createDb
                
                elif [[ "${queryWords[1]}" == "table" ]]; then
                    createTable
                else
                    gum style --foreground 196 "Invalid query"  
                fi
                ;;

            use)
                useDb
                ;;

            list)
                listDb
                ;;

            drop)
                dropDb
                ;;

            exit)
                exitDb
                ;;

            show)
                showTables
                ;;

            *)
                gum style --foreground 196 "Invalid query"                
                ;;
        esac
    else
         gum style --foreground 196 "Invalid query"
    fi
done