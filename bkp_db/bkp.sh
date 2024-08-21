#!/bin/bash
set -x

start_time_all=$(date +%s)

# Функция создания резервной копии БД
backup_database() {
    local DB_NAME="$1"
    local BACKUP_DIR="${DB_NAME}_$(date +'%Y-%m-%d')"
    local start_time=$(date +%s)

    mkdir -p "${WORK_DIR}/${BACKUP_DIR}"
    chown -R 1001:1001 "${WORK_DIR}/${BACKUP_DIR}"

    # Создание физического бекапа
    docker run --rm \
        --name xtrabackup \
        -v "${WORK_DIR}/${BACKUP_DIR}":"${WORK_DIR}/${BACKUP_DIR}" \
        --volumes-from percona bitnami/percona-xtrabackup:8.0 \
            --backup \
            --databases="${DB_NAME}" \
            --datadir=/var/lib/mysql/ \
            --target-dir="${WORK_DIR}/${BACKUP_DIR}" \
            --user=root \
            --password=pAssW0rD \
            --use-memory=5G \
            --socket=/var/lib/mysql/mysql.sock

    # Подготовка бекапа
    docker run --rm \
        --name xtrabackup \
        -v "${WORK_DIR}/${BACKUP_DIR}":"${WORK_DIR}/${BACKUP_DIR}" \
        --volumes-from percona bitnami/percona-xtrabackup:8.0 \
            --prepare \
            --target-dir="${WORK_DIR}/${BACKUP_DIR}" \
            --socket=/var/lib/mysql/mysql.sock

    local BACKUP_DIR_SIZE=$(du -sh "${WORK_DIR}/${BACKUP_DIR}" | cut -f1)
    echo "Размер БД ${DB_NAME}: ${BACKUP_DIR_SIZE}" >> ${LOG_FILE}
    
    # Создания сжатого архива .tar.gz. Удаление папки бекапа
    tar -czf ${WORK_DIR}/${BACKUP_DIR}.tar.gz -C ${WORK_DIR} ${BACKUP_DIR} && \
    find ${WORK_DIR}/ -type d -name "survey_*" -exec rm -rf {} \;

    local ZIP_FILE_SIZE=$(du -sh "${WORK_DIR}/${BACKUP_DIR}.tar.gz" | cut -f1)
    echo "Размер архива БД ${DB_NAME}: ${ZIP_FILE_SIZE}" >> ${LOG_FILE}

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local duration_min=$((duration / 60))
    echo "Cоздание резервной копии БД ${DB_NAME}: ${duration_min} min" >> ${LOG_FILE}

    return 0
}

# Функция отправки архива базы в s3
s3_upload() {
    local DB_NAME="$1"
    local BACKUP_DIR="${DB_NAME}_$(date +'%Y-%m-%d')"
    local start_time=$(date +%s)
    local BACKET="backet_name"

    docker run --rm \
        -v ${WORK_DIR}/aws/.aws:/root/.aws \
        -v ${WORK_DIR}/aws/data:/aws \
        -v ${WORK_DIR}:${WORK_DIR} \
        amazon/aws-cli \
            s3 cp ${WORK_DIR}/${BACKUP_DIR}.tar.gz s3://${BACKET}/backups/${BACKUP_DIR}.tar.gz
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local duration_min=$((duration / 60))
    echo "Отправка архива БД ${DB_NAME} в S3: ${duration_min} min
         " >> ${LOG_FILE}

    return 0
}

# Функция проверки бекапа в s3 и удаление, в случае успеха
s3_check() {
    local DB_NAME="$1"
    local BACKUP_DIR="${DB_NAME}_$(date +'%Y-%m-%d')"
    local BACKET="backet_name"

    docker run --rm \
        -v ${WORK_DIR}/aws/.aws:/root/.aws \
        -v ${WORK_DIR}/aws/data:/aws \
        -v ${WORK_DIR}:${WORK_DIR} \
        amazon/aws-cli \
            s3 ls s3://${BACKET}/backups/${BACKUP_DIR}.tar.gz && \
            find ${WORK_DIR}/ -type f -name "${DB_NAME}_*" ! -newermt '50 hours ago' -exec rm -rf {} \;
    
    return 0
}

notification() {
    local MESSAGE=$1
    local TELEGRAM_TOKEN="token"
    local CHAT_ID="chat_id"
    local URL="https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage"
    curl -s -X POST ${URL} -d chat_id=${CHAT_ID} -d text="${MESSAGE}"
}

main() {
    local VALUE="$1"

    backup_database ${VALUE}
    if [ $? -ne 0 ]; then
        notification "step 1/3 Бекап не создан"
        exit 1
    fi

    s3_upload ${VALUE}
    if [ $? -ne 0 ]; then
        notification "step 2/3 Отправка архива в S3 провалена"
        exit 1
    fi

    s3_check ${VALUE}
    if [ $? -ne 0 ]; then
        notification "step 3/3 Проверка архива в S3 провалена"
        exit 1
    fi
}


# Пользовательские данные
# ----- START -----
WORK_DIR="/srv/storage/backups"
LOG_FILE="${WORK_DIR}/backup.log"

main "db1"
main "db2"
# ----- END -----



end_time_all=$(date +%s)
duration_seconds=$((end_time_all - start_time_all))
duration_minutes=$((duration_seconds / 60))

echo "Start Time: $(date -d @$start_time_all)" >> ${LOG_FILE}
echo "End Time: $(date -d @$end_time_all)" >> ${LOG_FILE}
echo "Duration: ${duration_minutes} min

" >> ${LOG_FILE}

LAST_15_LINES=$(tail -n 15 ${LOG_FILE})
notification "${LAST_15_LINES}"