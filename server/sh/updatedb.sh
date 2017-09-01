#!/bin/sh
DATABASE="smxx"
SRC_HOST="192.168.44.51"
SRC_USER="root"
SRC_PASSWORD="root"

DST_HOST="192.168.44.53"
DST_USER="root"
DST_PASSWORD="root"

function dump_table () {
    mysqldump --add-drop-table -u${SRC_USER} -p${SRC_PASSWORD} -h ${SRC_HOST} ${DATABASE} --tables  $1;
}

function import_table () {
    mysql -u${DST_USER} -p${DST_PASSWORD} -h ${DST_HOST} < $1;
}

function show_all_tables () {
    echo "use ${DATABASE}; show tables;" | mysql -u${SRC_USER} -p${SRC_PASSWORD} -h ${SRC_HOST}
}

function update_temp_tables () {
    for table in `show_all_tables | grep temp_`;
    do
        echo "copying ${table}";
        echo "use ${DATABASE};" > /tmp/${table}.sql
        dump_table ${table}  >> /tmp/${table}.sql
        import_table /tmp/${table}.sql
        rm -f /tmp/${table}.sql
    done
}

function update_all_tables () {
    for table in `show_all_tables`;
    do
        echo "copying ${table}";
        echo "use ${DATABASE};" > /tmp/${table}.sql
        dump_table ${table}  >> /tmp/${table}.sql
        import_table /tmp/${table}.sql
        rm -f /tmp/${table}.sql
    done
}

if [ $# -ge 1 ];
then
    if [ "$1" == "all" ]
    then
        update_all_tables;
    else
        echo "$0 all   copying all tables"
        echo "$0       copying only tables name with prefix temp_"
    fi
else
     update_temp_tables;
fi

