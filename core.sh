#!/bin/bash
. ./database_Funs.sh
echo "=============================="
echo "    Welcome to our DBMS!"
echo "=============================="
echo "Write your SQL command like that:"
echo ". create database dbname"
echo ". drop database dbname"
echo ". list database"
echo ". use dbname"
echo ". drop table tablename"
echo ". create table tName id(int) name(string) .. "
echo ". exit"


keywords=("create" "drop" "list" "use")
while true; do
    echo ""
    echo "Enter your Query (or 'exit' to quit)"
    read -p "$ " query 
    echo ""

    queryWords=($query)

    # Exit condition
    if [[ "${queryWords[0]}" == "exit" ]]; then
        echo "Exiting program..."
        break
    fi

    # choose between database operations to execute the functons based on the first word in the statement
    if [[ " ${keywords[@]} " =~ " ${queryWords[0]} " ]]; then
        case ${queryWords[0]} in

            create)
                if [[ "${queryWords[1]}" == "database" ]]; then
                    createDb
                fi
               ;;

            use)
                echo "connect to database...."
                ;;

            list)
                echo "list databases...."
                ;;

            drop)
                echo "drop function ...."
                ;;

            *)
                echo "Invalid query"
                ;;


        esac
    else
        echo "Invalid query"
    fi
done

git config --global user.name "Your Name"  # If not already set