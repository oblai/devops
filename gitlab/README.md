mkdir nginx-conf nginx-logs nginx-certs && \
mv nginx.conf nginx-conf && \
mv gitlab.conf nginx-conf && \
mkdir gitlab-config gitlab-data gitlab-logs && \
mkdir postgresql-data && \
mkdir redis-data && \
mkdir gitlab-runner/config gitlab-runner/data