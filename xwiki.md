```bash
bash -cx '
mkdir -p /srv/xwiki/db /srv/xwiki/mysql /srv/xwiki/mysql-init

echo "grant all privileges on *.* to xwiki@'%' identified by 'xwiki'" > /srv/xwiki/db/mysql-init/init.sql

docker run \
    --net=xwiki-nw \
    --name mysql-xwiki \
    --restart=unless-stopped \
    -v /srv/xwiki/db/mysql:/var/lib/mysql \
    -v /srv/xwiki/db/mysql-init:/docker-entrypoint-initdb.d \
    -e MYSQL_ROOT_PASSWORD=xwiki \
    -e MYSQL_USER=xwiki \
    -e MYSQL_PASSWORD=xwiki \
    -e MYSQL_DATABASE=xwiki \
    -d mysql:5.7 \
    --character-set-server=utf8 \
    --collation-server=utf8_bin \
    --explicit-defaults-for-timestamp=1

docker run \
    --net=xwiki-nw \
    --name xwiki \
    --restart=unless-stopped \
    -p 80:8080 \
    -v /srv/xwiki:/usr/local/xwiki \
    -e DB_USER=xwiki \
    -e DB_PASSWORD=xwiki \
    -e DB_DATABASE=xwiki \
    -e DB_HOST=mysql-xwiki \
    -d xwiki:lts-mysql-tomcat'
```