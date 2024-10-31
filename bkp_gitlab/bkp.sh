#!/bin/bash
LOG_FILE="/srv/storage/backups/logs/gitlab_backup_$(date +'%Y-%m-%d').log"
exec >> "$LOG_FILE" 2>&1
set -euxo pipefail

BACKUP_DIR="/srv/storage/backups"
GITLAB_DIR="/srv/gitlab"
GITLAB_VERSION="16.3.3-ee"

# бекап конфига
tar -cf ${BACKUP_DIR}/gitlab_config_$(date +'%Y-%m-%d').tar -C ${GITLAB_DIR} config

# бекап gitlab
docker exec -i gitlab bash -c "gitlab-rake gitlab:backup:create STRATEGY=copy"

# все в один архив
tar -cf ${BACKUP_DIR}/full_gitlab_backup_${GITLAB_VERSION}_$(date +'%Y-%m-%d').tar \
    -C ${BACKUP_DIR} gitlab_config_$(date +'%Y-%m-%d').tar \
	-C ${GITLAB_DIR}/data/backups/ $(ls -t ${GITLAB_DIR}/data/backups | head -n 1)

# прибираемся за собой
ll ${BACKUP_DIR}/full_gitlab_backup_${GITLAB_VERSION}_$(date +'%Y-%m-%d').tar && \
rm ${BACKUP_DIR}/gitlab_config_$(date +'%Y-%m-%d').tar & \
rm ${GITLAB_DIR}/data/backups/$(ls -t ${GITLAB_DIR}/data/backups | head -n 1)

# отправка бекапа в S3
docker run --rm \
    -v ${BACKUP_DIR}/aws/.aws:/root/.aws \
    -v ${BACKUP_DIR}/aws/data:/aws \
	-v ${BACKUP_DIR}:${BACKUP_DIR} \
    amazon/aws-cli \
        s3 cp ${BACKUP_DIR}/full_gitlab_backup_${GITLAB_VERSION}_$(date +'%Y-%m-%d').tar s3://backup-git1/full_gitlab_backup_${GITLAB_VERSION}_$(date +'%Y-%m-%d').tar

# проверка бекапа в S3 и удаление в случае успеха
docker run --rm \
        -v ${BACKUP_DIR}/aws/.aws:/root/.aws \
        -v ${BACKUP_DIR}/aws/data:/aws \
        -v ${BACKUP_DIR}:${BACKUP_DIR} \
        amazon/aws-cli \
            s3 ls s3://backup-git1/full_gitlab_backup_${GITLAB_VERSION}_$(date +'%Y-%m-%d').tar && \
            find ${BACKUP_DIR}/ -type f -name "full_gitlab_backup_${GITLAB_VERSION}_*.tar" -mtime +7 -delete