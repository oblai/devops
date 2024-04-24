mkdir nginx-conf nginx-logs nginx-certs && \
mv nginx.conf nginx-conf && \
mv gitlab.conf nginx-conf && \
mkdir gitlab-config gitlab-data gitlab-logs && \
mkdir postgresql-data && \
mkdir redis-data && \
mkdir gitlab-runner/config gitlab-runner/data


# REGISTER RUNNER
docker-compose exec gitlab-runner \
    gitlab-runner register \
    --non-interactive \
    --url https://gitlab.DOMAIN.com \
    --registration-token <REGISTRATION TOCKEN FROM gitlab>\
    --executor docker \
    --description "Runner 1" \
    --docker-image "docker:stable" \
    --docker-volumes /var/run/docker.sock:/var/run/docker.sock