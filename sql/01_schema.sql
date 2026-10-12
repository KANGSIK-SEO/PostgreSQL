-- 공공 미술관 오픈 데이터 기반 소장품 DB
-- 출처: The Met Open Access(CC0), Art Institute of Chicago API(CC0), Cleveland Museum of Art Open Access(CC0)
-- 원본 수집: github.com/KANGSIK-SEO/AITOOLLEARN-7-1 (scripts/collect_met.py 등)에서 받은 실제 소장품 데이터를
--          교육용으로 artists/departments/classifications/artworks/curation_logs 5개 테이블로 정규화함

DROP TABLE IF EXISTS curation_logs CASCADE;
DROP TABLE IF EXISTS artworks CASCADE;
DROP TABLE IF EXISTS classifications CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
DROP TABLE IF EXISTS artists CASCADE;

CREATE TABLE artists (
    artist_id    SERIAL PRIMARY KEY,
    name         TEXT NOT NULL UNIQUE,
    nationality  TEXT,
    bio          TEXT
);

CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    source_code   TEXT NOT NULL CHECK (source_code IN ('met', 'aic', 'cma')),
    museum_name   TEXT NOT NULL,
    name          TEXT NOT NULL,
    UNIQUE (source_code, name)
);

CREATE TABLE classifications (
    classification_id SERIAL PRIMARY KEY,
    name               TEXT NOT NULL UNIQUE
);

CREATE TABLE artworks (
    artwork_id        SERIAL PRIMARY KEY,
    source_code       TEXT NOT NULL CHECK (source_code IN ('met', 'aic', 'cma')),
    source_object_id  TEXT NOT NULL,
    title             TEXT NOT NULL,
    artist_id         INTEGER NOT NULL REFERENCES artists (artist_id),
    department_id     INTEGER NOT NULL REFERENCES departments (department_id),
    classification_id INTEGER NOT NULL REFERENCES classifications (classification_id),
    year_start        INTEGER,
    year_end          INTEGER,
    medium            TEXT,
    origin            TEXT,
    image_url         TEXT,
    source_url        TEXT,
    credit_line       TEXT,
    is_public_domain  BOOLEAN NOT NULL DEFAULT TRUE,
    is_highlight      BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE (source_code, source_object_id)
);

CREATE TABLE curation_logs (
    log_id       SERIAL PRIMARY KEY,
    artwork_id   INTEGER NOT NULL REFERENCES artworks (artwork_id),
    curator_name TEXT NOT NULL,
    action       TEXT NOT NULL CHECK (action IN
                   ('등록검수', '재감정', '설명수정', '이미지교체', '비공개처리', '공개복구', '라이선스확인')),
    action_date  DATE NOT NULL,
    note         TEXT
);

-- 조회 성능을 위한 인덱스
CREATE INDEX idx_artworks_artist_id ON artworks (artist_id);
CREATE INDEX idx_artworks_year      ON artworks (year_start, year_end);
CREATE INDEX idx_curation_logs_artwork_id ON curation_logs (artwork_id);
