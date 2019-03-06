#!/usr/bin/env bash

set -ex

# 36
# 123456789012345678901234567890123456
# 62781e2a-3dc8-11e9-bf31-80c71e9d5857

psql -v ON_ERROR_STOP=1 <<EOSQL

  CREATE USER frooble3 WITH PASSWORD 'frooble3';
  CREATE DATABASE frooble3 WITH OWNER frooble3;

EOSQL

psql -U frooble3 frooble3 -v ON_ERROR_STOP=1 <<EOSQL

  CREATE TABLE report_text (
    guid CHAR(36) PRIMARY KEY,
    text TEXT NOT NULL
  );

  CREATE TABLE dist (
    id SERIAL PRIMARY KEY,
    name VARCHAR(128)
  );

  CREATE TABLE os (
    id SERIAL PRIMARY KEY,
    name VARCHAR(128)
  );

  CREATE TABLE perl (
    id SERIAL PRIMARY KEY,
    name VARCHAR(128)
  );

  CREATE TABLE platform (
    id SERIAL PRIMARY KEY,
    name VARCHAR(128)
  );

  CREATE TABLE reporter (
    id SERIAL PRIMARY KEY,
    name VARCHAR(128)
  );

  CREATE TABLE version (
    id SERIAL PRIMARY KEY,
    name VARCHAR(128)
  );

  CREATE TYPE grade_type AS ENUM ('pass','fail','na','unknown','unprovided');

  CREATE TABLE report (
    guid        CHAR(36) PRIMARY KEY,
    date        DATE,
    dist_id     INTEGER REFERENCES dist(id) NOT NULL,
    grade       grade_type NOT NULL,
    os_id       INTEGER REFERENCES os(id),
    perl_id     INTEGER REFERENCES perl(id),
    platform_id INTEGER REFERENCES platform(id),
    reporter_id INTEGER REFERENCES reporter(id),
    version_id  INTEGER REFERENCES version(id)
  );

EOSQL
