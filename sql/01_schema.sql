-- ============================================================
-- 주제: 퍼블릭 도메인 명화 챗봇 서비스 로그 DB
-- (AITOOLLEARN-7-1 레포에서 실제로 설계/운영 중인 users/artworks/chats/
--  favorites/rights_records 테이블의 PK-FK 관계를 이 과제용으로 재구성)
-- DB: PostgreSQL (표준 SQL 범위 내에서 작성, BIGSERIAL만 Postgres 전용 문법)
--
-- 실행 순서: users, artworks (부모 테이블) -> chats, favorites,
--            rights_records (자식 테이블, FK로 부모를 참조)
-- ============================================================

DROP TABLE IF EXISTS rights_records;
DROP TABLE IF EXISTS favorites;
DROP TABLE IF EXISTS chats;
DROP TABLE IF EXISTS artworks;
DROP TABLE IF EXISTS users;

-- 1. 회원
CREATE TABLE users (
    id            BIGSERIAL PRIMARY KEY,
    email         VARCHAR(255) NOT NULL UNIQUE,     -- 로그인 식별자, 중복 가입 방지
    password_hash TEXT         NOT NULL,
    is_premium    BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMP    NOT NULL DEFAULT now()
);

-- 2. 공공 소장 명화 (출처 기관 API에서 수집)
CREATE TABLE artworks (
    id               BIGSERIAL    PRIMARY KEY,
    source           VARCHAR(20)  NOT NULL CHECK (source IN ('met', 'aic', 'cma')),
    source_id        VARCHAR(50)  NOT NULL,          -- 출처 기관 내부 작품 ID
    title            VARCHAR(300) NOT NULL,
    artist           VARCHAR(200),
    year_start       INTEGER,
    year_end         INTEGER,
    medium           VARCHAR(200),
    origin           VARCHAR(100),                   -- 제작 국가/문화권
    is_public_domain BOOLEAN      NOT NULL DEFAULT TRUE,
    license          VARCHAR(20)  NOT NULL DEFAULT 'CC0',
    collected_at     TIMESTAMP    NOT NULL DEFAULT now(),
    UNIQUE (source, source_id)                        -- 같은 기관의 같은 작품을 중복 수집하지 않음
);

-- 3. 채팅 로그 (users 1 : N chats)
CREATE TABLE chats (
    id          BIGSERIAL   PRIMARY KEY,
    user_id     BIGINT      NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    question    TEXT        NOT NULL,
    answer      TEXT,
    status      VARCHAR(10) NOT NULL CHECK (status IN ('ok', 'error')),
    latency_ms  INTEGER,
    created_at  TIMESTAMP   NOT NULL DEFAULT now()
);

-- 회원별 최근 채팅 조회가 가장 빈번한 접근 경로라, FK 컬럼(user_id)과
-- 정렬 기준(created_at)을 묶은 복합 인덱스를 둔다.
CREATE INDEX idx_chats_user_time ON chats (user_id, created_at);

-- 4. 즐겨찾기 (users 1 : N favorites, artworks 1 : N favorites)
CREATE TABLE favorites (
    id         BIGSERIAL PRIMARY KEY,
    user_id    BIGINT    NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    artwork_id BIGINT    NOT NULL REFERENCES artworks(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT now(),
    UNIQUE (user_id, artwork_id)                       -- 같은 작품을 두 번 즐겨찾기할 수 없음
);

-- 어떤 작품이 즐겨찾기로 많이 쌓였는지 집계할 때 artwork_id로 자주 묻는다.
CREATE INDEX idx_favorites_artwork ON favorites (artwork_id);

-- 5. 저작권(퍼블릭 도메인) 발급 기록 (artworks 1 : N rights_records, users 1 : N rights_records)
CREATE TABLE rights_records (
    number     VARCHAR(20) PRIMARY KEY,                -- 예: PD-2026-0001
    artwork_id BIGINT      NOT NULL REFERENCES artworks(id) ON DELETE CASCADE,
    user_id    BIGINT               REFERENCES users(id) ON DELETE SET NULL,  -- 비로그인 발급이면 NULL
    snapshot   TEXT        NOT NULL,                    -- 발급 시점 판정/출처 표기 스냅숏
    signature  VARCHAR(128) NOT NULL,
    issued_at  TIMESTAMP   NOT NULL DEFAULT now()
);
