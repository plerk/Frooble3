#!/usr/bin/env bash


set -ex

psql -v ON_ERROR_STOP=1 <<'EOSQL'

  CREATE USER frooble3 WITH PASSWORD 'frooble3';
  CREATE DATABASE frooble3 WITH OWNER frooble3;

EOSQL

psql -U frooble3 frooble3 -v ON_ERROR_STOP=1 <<'EOSQL'

  CREATE TYPE release_type AS ENUM ('latest','cpan','backpan','unknown');

  CREATE TABLE release (
    id SERIAL PRIMARY KEY NOT NULL,
    author VARCHAR(128),
    dist VARCHAR(128) NOT NULL,
    version VARCHAR(128) NOT NULL,
    type release_type NOT NULL DEFAULT 'unknown',
    UNIQUE(dist,version)
  );

  CREATE FUNCTION
    lookup_release(d TEXT, v TEXT) RETURNS INTEGER AS $$
      DECLARE
        id INTEGER;
      BEGIN
        v := COALESCE(v, '-');
        SELECT
          r.id INTO id
        FROM
          release AS r
        WHERE
          r.dist = d AND r.version = v;
        IF id IS NULL THEN
          BEGIN
            INSERT INTO
              release (dist,version)
            VALUES
              (d,v);
            SELECT
              currval(pg_get_serial_sequence('release','id'))
            INTO
              id;
          END;
        END IF;
        RETURN id;
      END;
    $$ LANGUAGE plpgsql;

  CREATE TABLE os (
    id SERIAL PRIMARY KEY NOT NULL,
    name VARCHAR(128) NOT NULL,
    version VARCHAR(128) NOT NULL,
    platform VARCHAR(128) NOT NULL,
    UNIQUE(name,version,platform)
  );

  CREATE FUNCTION
    lookup_os(n TEXT, v TEXT, p TEXT) RETURNS INTEGER AS $$
      DECLARE
        id INTEGER;
      BEGIN
        n := COALESCE(n, '-');
        v := COALESCE(v, '-');
        p := COALESCE(p, '-');
        SELECT
          o.id INTO id
        FROM
          os AS o
        WHERE
          o.name = n AND o.version = v AND o.platform = p;
        IF id IS NULL THEN
          BEGIN
            INSERT INTO
              os (name, version, platform)
            VALUES
              (n,v,p);
            SELECT
              currval(pg_get_serial_sequence('os','id'))
            INTO
              id;
          END;
        END IF;
        RETURN id;
      END;
    $$ LANGUAGE plpgsql;

  CREATE TABLE perl (
    id SERIAL PRIMARY KEY NOT NULL,
    name VARCHAR(128) UNIQUE NOT NULL
  );

  CREATE FUNCTION
    lookup_perl(n TEXT) RETURNS INTEGER AS $$
      DECLARE
        id INTEGER;
      BEGIN
        n := COALESCE(n, '-');
        SELECT
          p.id INTO id
        FROM
          perl AS p
        WHERE
          p.name = n;
        IF id IS NULL THEN
          BEGIN
            INSERT INTO
              perl (name)
            VALUES
              (n);
            SELECT
              currval(pg_get_serial_sequence('perl','id'))
            INTO
              id;
          END;
        END IF;
        RETURN id;
      END;
    $$ LANGUAGE plpgsql;

  CREATE TABLE reporter (
    id SERIAL PRIMARY KEY NOT NULL,
    name VARCHAR(128) UNIQUE NOT NULL
  );

  CREATE FUNCTION
    lookup_reporter(n TEXT) RETURNS INTEGER AS $$
      DECLARE
        id INTEGER;
      BEGIN
        n := COALESCE(n, '-');
        SELECT
          r.id INTO id
        FROM
          reporter AS r
        WHERE
          r.name = n;
        IF id IS NULL THEN
          BEGIN
            INSERT INTO
              reporter (name)
            VALUES
              (n);
            SELECT
              currval(pg_get_serial_sequence('reporter','id'))
            INTO
              id;
          END;
        END IF;
        RETURN id;
      END;
    $$ LANGUAGE plpgsql;

  CREATE TYPE grade_type AS ENUM ('pass','fail','na','unknown','-');

  CREATE TABLE ignore_report (
    id SERIAL PRIMARY KEY NOT NULL,
    create_at TIMESTAMP DEFAULT now(),
    reason TEXT
  );

  CREATE TABLE report_data (
    guid             CHAR(36) PRIMARY KEY NOT NULL,
    date             DATE,
    release_id       INTEGER REFERENCES release(id) NOT NULL,
    grade            grade_type NOT NULL,
    os_id            INTEGER REFERENCES os(id) NOT NULL,
    perl_id          INTEGER REFERENCES perl(id) NOT NULL,
    reporter_id      INTEGER REFERENCES reporter(id) NOT NULL,
    ignore_report_id INTEGER REFERENCES ignore_report
  );

  CREATE TABLE report_text (
    guid CHAR(36) PRIMARY KEY NOT NULL REFERENCES report_data(guid),
    text TEXT NOT NULL
  );

  CREATE VIEW
    report
  AS
    SELECT
      rp.guid             AS guid,
      rp.date             AS date,
      rl.dist             AS dist,
      rl.version          AS version,
      rp.grade            AS grade,
      o.name              AS osname,
      o.version           AS osvers,
      o.platform          AS platform,
      p.name              AS perl,
      u.name              AS reporter,
      rp.ignore_report_id AS ignore_report_id
    FROM
      report_data AS rp                           JOIN
      release     AS rl ON rp.release_id  = rl.id JOIN
      perl        AS p  ON rp.perl_id     = p.id  JOIN
      reporter    AS u  ON rp.reporter_id = u.id  JOIN
      os          AS o  ON rp.os_id       = o.id
  ;

  CREATE FUNCTION triggerf_insert_report() RETURNS TRIGGER AS $$
    BEGIN
      INSERT INTO report_data
        (guid, date, release_id, grade, os_id, perl_id, reporter_id, ignore_report_id)
      VALUES
        (NEW.guid, NEW.date,
          lookup_release(NEW.dist,NEW.version),
          COALESCE(NEW.grade, '-'),
          lookup_os(NEW.osname, NEW.osvers, NEW.platform),
          lookup_perl(NEW.perl),
          lookup_reporter(NEW.reporter),
          NEW.ignore_report_id
        );
      RETURN NEW;
    END;
  $$ LANGUAGE plpgsql;

  CREATE TRIGGER trigger_insert_report INSTEAD OF INSERT ON report FOR EACH ROW
  EXECUTE PROCEDURE triggerf_insert_report();

  CREATE TABLE url (
    guid CHAR(36) PRIMARY KEY NOT NULL REFERENCES report_data(guid),
    note TEXT NOT NULL,
    url TEXT NOT NULL
  );

EOSQL
