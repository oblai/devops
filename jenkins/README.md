mkdir -p jenkins/jenkins_home jenkins/ssl && \
openssl req -x509 -nodes -newkey rsa:2048 -keyout key.pem -out crt.pem -days 365 -subj "/C=RU/ST=Moscow/L=Moscow/O=Example Inc./OU=IT Department/CN=example.com"
