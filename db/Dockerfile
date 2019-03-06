FROM postgres:11.2-alpine

ENV PGUSER            postgres
ENV POSTGRES_PASSWORD passwd/.,
ENV POSTGRES_USER     postgres

RUN mkdir -p /docker-entrypoint-initdb.d
COPY 01-init.sh /docker-entrypoint-initdb.d/01-init.sh
