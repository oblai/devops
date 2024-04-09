#!/bin/bash

set -x

start_time=$(date +%s)

# Функция создания резервной копии БД ${db_name}
backup_database() {
    local db_name=db"$1"
    local backup_dir="/srv/hdd-storage/backup/${db_name}_$(date +'%Y-%m-%d')"

    mkdir -p "$backup_dir"

    docker run --rm --name xtrabackup -v "$backup_dir":"$backup_dir" --volumes-from percona percona/percona-xtrabackup:2.4 \
    xtrabackup --backup --databases="$db_name" --datadir=/var/lib/mysql/ --target-dir="$backup_dir" --user=root --password=******** --use-memory=5G

    docker run --rm --name xtrabackup -v "$backup_dir":"$backup_dir" --volumes-from percona percona/percona-xtrabackup:2.4 \
    xtrabackup --prepare --target-dir="$backup_dir"
}

# Функция создания единого архива
archive() {
    local db_name=db"$1"
    local web_name="$1".ru

    cd /srv/hdd-storage/backup/
    tar -cf full_backup_${web_name}_$(date +'%Y%m%d--%H%M').tar --exclude='/srv/web-roots/${web_name}/www/bitrix/backup/' ${db_name}_$(date +'%Y-%m-%d') -C /srv/web-roots ${web_name}
	find /srv/hdd-storage/backup/ -name ${db_name}_$(date +'%Y-%m-%d') -type d -exec rm -rf {} \;
    find /srv/hdd-storage/backup/ -type f -name "full_backup_${web_name}_*.tar" ! -newermt '1 hours ago' -delete
}

backup_database "site1"
archive "site1"
backup_database "site2"
archive "site2"

end_time=$(date +%s)
duration_seconds=$((end_time - start_time))
duration_minutes=$((duration_seconds / 60))

echo "Start Time: $(date -d @$start_time)" >> /srv/hdd-storage/backup/execution_time.txt
echo "End Time: $(date -d @$end_time)" >> /srv/hdd-storage/backup/execution_time.txt
echo "Duration: ${duration_minutes} min
" >> /srv/hdd-storage/backup/execution_time.txt











# Функция создания резервной копии данных сайта ${web_name}
backup_site() {
    local web_name="$1".ru

    rsync -av /srv/web-roots/${web_name} /srv/hdd-storage/backup/${web_name}_$(date +'%Y-%m-%d')
}

backup_site "test"

	tar -cf full_backup_${web_name}_$(date +'%Y%m%d_%H%M').tar ${db_name}_$(date +'%Y-%m-%d') ${web_name}_$(date +'%Y-%m-%d') && \
    rm -rf ${db_name}_$(date +'%Y-%m-%d') \
    rm -rf ${web_name}_$(date +'%Y-%m-%d')