Скрипт выполняет следующие задачи:
- Физический бекап базы
- Сжатие базы
- Отправка в S3
- Проверка в S3 и удаление локально бекапов старше 50 часов
- Логирование времени
- Логирование размера
- Нотификация в ТГ информации по бекапу и в случае неудачи

Скрипт рассчитан на выполнение не чаще, чем раз в сутки

Образ `bitnami/percona-xtrabackup` используется, потому что официальный образ построен на fedora и требует avx инструкции

Пример уведомления в телеграмм:
```text
Размер БД db1: 72G
Размер архива БД db1: 20G
Cоздание резервной копии БД db1: 46 min
Отправка архива БД db1 в S3: 3 min
         
Размер БД db2: 24G
Размер архива БД db2: 1.4G
Cоздание резервной копии БД db2: 8 min
Отправка архива БД db2 в S3: 0 min
         
Start Time: Wed Aug 21 03:00:01 AM UTC 2024
End Time: Wed Aug 21 03:58:34 AM UTC 2024
Duration: 58 min
```