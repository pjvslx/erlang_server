#!/bin/sh
DATABASE="cssm0"
LOG_DATABASE="cssm_log0"
DB_HOST="127.0.0.1"
DB_USER="root"
DB_PASSWORD="636a8ecfdc6588df"

function dump_table () {
     mysqldump -d --add-drop-table -u${DB_USER} -p${DB_PASSWORD} -h ${DB_HOST} ${DATABASE} --tables  $1;
}

function dump_log_table () {
     mysqldump -d --add-drop-table -u${DB_USER} -p${DB_PASSWORD} -h ${DB_HOST} ${LOG_DATABASE} --tables  $1;
}

function import_table () {
    mysql -u${DB_USER} -p${DB_PASSWORD} -h ${DB_HOST} < $1;
}

function import_log_table () {
    mysql -u${DB_USER} -p${DB_PASSWORD} -h ${DB_HOST} < $1;
}

function show_all_tables () {
    echo "use ${DATABASE}; show tables;" | mysql -u${DB_USER} -p${DB_PASSWORD} -h ${DB_HOST}
}

function show_all_log_tables () {
    echo "use ${LOG_DATABASE}; show tables;" | mysql -u${DB_USER} -p${DB_PASSWORD} -h ${DB_HOST}
}

function update_game_tables () {
    for table in `show_all_tables | grep -v Tables_in_ | grep -v temp_ | grep -v config_`;
    do
        echo "dump_table ${table}";
        echo "use ${DATABASE};" > /tmp/${table}.sql
        dump_table ${table}  >> /tmp/${table}.sql
        import_table /tmp/${table}.sql
        #rm -f /tmp/${table}.sql
    done
}

function update_log_tables () {
    for table in `show_all_log_tables | grep -v Tables_in_ | grep -v config_`;
    do
        echo "dump_log_table ${table}";
        echo "use ${LOG_DATABASE};" > /tmp/${table}.sql
        dump_log_table ${table}  >> /tmp/${table}.sql
        import_log_table /tmp/${table}.sql
        #rm -f /tmp/${table}.sql
    done
}

update_game_tables

update_log_tables