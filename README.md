# 공공 미술관 오픈데이터 소장품 DB (PostgreSQL)

Codyssey "관계형 데이터베이스 설계 & SQL 작성" 미션 제출물.

백엔드 프레임워크 없이 **로컬 PostgreSQL + SQL만으로** 설계·적재·조회한 결과물이다.
도메인은 "도서 대여"가 아니라, 내가 앞서 만든 [AITOOLLEARN-7-1](https://github.com/KANGSIK-SEO/AITOOLLEARN-7-1)
(퍼블릭 도메인 명화 찾기 챗봇) 프로젝트에서 **The Met / Art Institute of Chicago / Cleveland Museum of Art**
오픈 API로 실제 수집해둔 공공 미술작품 데이터(`data/art.db`, CC0)를 가져와 정규화한 것이다.

## 1. 테이블 구조

| 테이블 | 역할 | PK |
|---|---|---|
| `artists` | 작가 정보 (이름/국적/약력) | `artist_id` |
| `departments` | 소장 기관(met/aic/cma)의 전시 부서 | `department_id` |
| `classifications` | 작품 분류(회화/판화/사진/조각 등 12종) | `classification_id` |
| `artworks` | 작품 본체. artist/department/classification을 FK로 참조 | `artwork_id` |
| `curation_logs` | 작품에 대한 큐레이터 작업 이력(등록검수/재감정/비공개처리 등) | `log_id` |

### 관계(FK, 1:N)
- `artworks.artist_id` → `artists.artist_id` (작가 1명 : 작품 여러 점)
- `artworks.department_id` → `departments.department_id` (부서 1개 : 작품 여러 점)
- `artworks.classification_id` → `classifications.classification_id` (분류 1개 : 작품 여러 점)
- `curation_logs.artwork_id` → `artworks.artwork_id` (작품 1점 : 큐레이션 로그 여러 건)

### ERD (텍스트)
```
artists (1) ───< artworks >─── (1) departments
                   │   │
                   │   └───> (1) classifications
                   │
                   (1)
                    │
                    ∨
            curation_logs (N)
```

## 2. 데이터 출처

- 실제 수집 스크립트: `AITOOLLEARN-7-1/scripts/collect_met.py`, `collect_aic.py`, `collect_cma.py`
- 원본 DB: `AITOOLLEARN-7-1/data/art.db` (약 78,000건의 MET/AIC/CMA 퍼블릭 도메인 소장품)
- 이 중 분류(회화/판화/사진/조각/도자기/옥공예/칠기/직물/서적/금속공예/수채화) 12종이 고르게 섞이도록
  실존 작가 58명 · 작품 92점을 선별해 정규화했다 (`sql/02_data.sql`).
- `curation_logs`(큐레이터 작업 이력) 15건은 실제 미술관 운영을 본뜬 교육용 샘플 데이터다.

## 3. 파일 구성

```
sql/01_schema.sql     -- 스키마 생성 (테이블 5개 + 인덱스 3개)
sql/02_data.sql       -- 샘플 데이터 INSERT (artists 58 / departments 10 / classifications 12 / artworks 92 / curation_logs 15)
sql/03_queries.sql    -- 쿼리 15개 (기본조회4 · 조인4 · 집계3 · 서브쿼리1 · 수정·삭제2 · 인덱스1)
results/query_results.txt  -- 위 15개 쿼리의 실제 실행 결과(텍스트 캡처)
```

## 4. 로컬 재현 방법

```bash
brew install postgresql@16
createdb public_art_db
psql -d public_art_db -f sql/01_schema.sql
psql -d public_art_db -f sql/02_data.sql
psql -d public_art_db -f sql/03_queries.sql
```
