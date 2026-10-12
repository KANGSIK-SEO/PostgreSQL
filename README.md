# 정보를 깔끔하게 정리하는 디지털 서랍장 만들기 (PostgreSQL)

**주제: 퍼블릭 도메인 명화 챗봇 서비스 로그 DB**

[AITOOLLEARN-7-1](https://github.com/KANGSIK-SEO/AITOOLLEARN-7-1) 레포에서 실제로 설계·운영 중인
`users` / `artworks` / `chats` / `favorites` / `rights_records` 테이블의 PK-FK 관계
(`app/db.py`의 `SCHEMA`, `PG_SCHEMA`)를 이 과제 조건에 맞게 재구성했다.
백엔드 프레임워크, 뷰/프로시저/트리거는 사용하지 않고 순수 SQL로만 구성했다.

## 1. 테이블 구성 (5개 테이블, 1:N 관계 5개)

| 테이블 | 설명 | PK |
|---|---|---|
| `users` | 회원 | `id` |
| `artworks` | 공공 소장 명화 (출처 기관에서 수집) | `id` |
| `chats` | 채팅 로그 | `id` |
| `favorites` | 즐겨찾기 | `id` |
| `rights_records` | 퍼블릭 도메인 저작권 발급 기록 | `number` |

```
users (1) ──< chats (N)            FK: chats.user_id -> users.id
users (1) ──< favorites (N)        FK: favorites.user_id -> users.id
artworks (1) ──< favorites (N)     FK: favorites.artwork_id -> artworks.id
artworks (1) ──< rights_records (N) FK: rights_records.artwork_id -> artworks.id
users (1) ──< rights_records (N)   FK: rights_records.user_id -> users.id (NULL 허용, 비로그인 발급)
```

제약조건: `users.email` UNIQUE, `favorites(user_id, artwork_id)` UNIQUE,
`chats.status` / `artworks.source` CHECK, 각 FK 모두 `ON DELETE` 동작 지정으로 실제 참조
무결성이 동작한다 (보너스 2번에서 직접 깨뜨려 확인).

## 2. 파일 구성

```
sql/01_schema.sql   스키마 생성 (DROP → CREATE TABLE, PK/FK/제약조건/인덱스)
sql/02_seed.sql     샘플 데이터 (users 10, artworks 12, chats 15, favorites 12, rights_records 10)
sql/03_queries.sql  핵심 쿼리 15개 (기본조회 4 / 조인 4 / 집계 3 / 서브쿼리 1 / 수정·삭제 2 / 인덱스 1)
sql/04_bonus.sql    보너스 과제 (JOIN vs 서브쿼리, FK 위반 실험, 미니 리포트 3종)
results/            각 스크립트를 로컬 PostgreSQL 16에 실제로 실행한 결과 캡처(텍스트)
```

## 3. 개발 환경 및 실행 방법

- DB: PostgreSQL 16 (Homebrew로 로컬 설치: `brew install postgresql@16`)
- 도구: `psql` CLI

```bash
createdb artlog_mission
psql -d artlog_mission -f sql/01_schema.sql
psql -d artlog_mission -f sql/02_seed.sql
psql -d artlog_mission -f sql/03_queries.sql
psql -d artlog_mission -f sql/04_bonus.sql
```

`results/` 폴더의 `.txt` 파일은 위 명령을 실제로 실행해 나온 결과를 그대로 캡처한 것이다
(`01_schema_result.txt`, `02_seed_result.txt`, `03_queries_result.txt`, `04_bonus_result.txt`,
그리고 FK 위반을 직접 발생시켜 캡처한 `05_fk_violation_demo.txt`).

## 4. 과제 목표 자가 점검

- **엑셀과의 차이**: 엑셀은 시트 간 관계를 강제하지 않지만, 여기서는 `chats.user_id` 같은 FK가
  존재하지 않는 회원을 참조하면 INSERT 자체를 막는다 (`05_fk_violation_demo.txt` 참고).
- **PK/FK와 1:N**: 하나의 회원(`users`)이 여러 채팅(`chats`)·즐겨찾기(`favorites`)를 가질 수
  있고, 하나의 작품(`artworks`)도 여러 번 즐겨찾기/발급될 수 있다 — FK가 그 "여러 개"를
  부모 한 행에 묶어준다.
- **SELECT/INSERT/UPDATE/DELETE 구분**: `sql/03_queries.sql`에 조회 8개, 수정 1개, 삭제 1개로
  각각 언제 쓰는지 예시로 분리해 두었다.
- **JOIN/GROUP BY**: 조인 4개(`03_queries.sql`)와 집계 3개로 "회원-채팅-즐겨찾기-작품"을
  엮어서 한 번에 뽑는 방법을 보여준다.
- **인덱스**: `idx_chats_user_time`은 "회원별 최근 채팅 조회"가 가장 빈번한 접근 경로라서
  FK 컬럼과 정렬 기준을 묶어 인덱스로 뒀다.
