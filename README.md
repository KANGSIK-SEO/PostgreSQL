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

---

## 5. 평가문항 답변 스크립트

Codyssey 참여확인 페이지의 "5. 평가문항"에 맞춰, 구술 평가 때 바로 말할 수 있도록
우리 프로젝트 기준으로 답변을 정리했다.

### 항목 1 — 산출물 자체는 위 구조/파일로 충족
- 테이블 5개, 각 PK 존재 ✅
- FK 1:N 관계 4개(요구 2개 이상) ✅, 없는 값 참조는 FK 제약으로 차단됨 — `artist_id=9999`로 INSERT 시도 시
  `insert or update on table "artworks" violates foreign key constraint` 에러로 실제 확인함 ✅
- 전 테이블 10행 이상 ✅ (artists 58 / departments 10 / classifications 12 / artworks 92 / curation_logs 15)
- 쿼리 15개(기본조회4·조인4·집계3·서브쿼리1·수정삭제2·인덱스1) ✅
- 실행 결과 `results/query_results.txt`에 텍스트로 첨부 ✅

### 항목 2 — 설계 이유

**Q. 테이블을 왜 이렇게 나눴는지, 각 테이블의 역할을 말할 수 있는가?**
> 작품 하나의 정보 안에는 "누가 만들었는지(작가)", "어느 기관 어느 부서가 소장하는지(부서)",
> "어떤 종류의 작품인지(분류)"처럼 성격이 다른 정보가 섞여 있습니다. 이걸 artworks 한 테이블에
> 전부 텍스트로 넣으면(실제 원본 AITOOLLEARN-7-1의 `artworks` 테이블이 그렇게 되어 있습니다)
> 같은 작가 이름이 90번 넘게 반복 저장되고, 오타가 나면 같은 사람인데 다른 사람처럼 집계되는
> 문제가 생깁니다. 그래서 반복되는 축(작가/부서/분류)을 각각 테이블로 분리하고 artworks가
> 그 세 테이블을 FK로 "참조"하게 했습니다. 마지막으로 curation_logs는 작품 자체의 속성이
> 아니라 "작품에 대해 누가 언제 무슨 작업을 했는지"라는 시간에 따라 계속 쌓이는 이력 데이터라서
> 별도 테이블로 뒀습니다.

**Q. FK로 연결한 1:N 관계가 실제 도메인에서 어떤 의미인지 예시를 들어 설명할 수 있는가?**
> 예를 들어 artists의 "Albrecht Dürer" 한 행(artist_id)이 artworks에서 "Adam and Eve",
> "Melencolia I" 등 여러 행에 의해 참조됩니다. 즉 작가 1명이 작품 여러 점을 가질 수 있는
> 1:N 관계입니다. 반대로 artworks 쪽에서 artist_id는 반드시 artists에 존재하는 값이어야 하므로,
> "존재하지 않는 작가 번호로 작품을 등록"하는 데이터 오류가 DB 단에서 막힙니다.

**Q. 컬럼 타입(TEXT, INTEGER, DATE 등)을 왜 그렇게 선택했는지 설명할 수 있는가?**
> - `year_start`/`year_end`는 범위 비교(`BETWEEN`, 정렬)가 필요해서 INTEGER로 뒀습니다.
>   원본 API의 `objectDate`처럼 "ca. 1600" 같은 문자열을 그대로 쓰면 연도 비교/정렬을 할 수 없기 때문입니다.
> - `title`, `medium`, `credit_line`처럼 길이가 들쭉날쭉하고 검색에만 쓰이는 값은 TEXT로 뒀습니다.
> - `curation_logs.action_date`는 날짜 계산(예: "2026-06-01 이전 삭제")이 필요해서 DATE로 뒀습니다.
> - `is_public_domain`, `is_highlight`는 참/거짓 두 값만 가지므로 BOOLEAN으로 둬서
>   TEXT로 'Y'/'N' 넣을 때 생기는 오타 가능성을 아예 없앴습니다.
> - `artworks.action` 같은 값은 CHECK 제약으로 허용값을 7개로 제한해 오타성 상태값이 못 들어오게 했습니다.

**Q. 인덱스를 어떤 컬럼에 걸었고, 왜 그 컬럼이어야 하는지 이유를 대답할 수 있는가?**
> `idx_artworks_year`를 `year_start, year_end`에 걸었습니다. "특정 연대 작품 찾기"처럼
> 범위 조건(`WHERE year_start BETWEEN …`)으로 자주 조회될 컬럼이기 때문입니다.
> `idx_artworks_artist_id`는 artist_id로 조인/필터가 매우 잦기 때문에(작가별 작품 목록 조회),
> `idx_curation_logs_artwork_id`는 반대로 특정 작품의 이력을 조회할 때 쓰입니다.
> 다만 지금은 샘플이 92행뿐이라 옵티마이저가 Seq Scan이 더 싸다고 판단할 수도 있어서,
> `sql/03_queries.sql` 마지막 쿼리에서 `EXPLAIN ANALYZE`로 실제 `Index Scan using idx_artworks_year`가
> 선택되는 것까지 확인해 뒀습니다.

### 항목 3 — DB 기본 개념

**Q. 데이터베이스가 엑셀과 무엇이 다른지, 왜 테이블을 나눠서 저장하는지 비교하며 설명할 수 있는가?**
> 엑셀은 "한 시트에 모든 열을 다 넣고 사람이 보면서 관리"하는 구조라 같은 작가 이름이
> 수십 행에 중복 저장되고, 작가 국적을 하나 고치려면 그 작가가 나오는 모든 행을 찾아 고쳐야 합니다.
> DB는 그 반복되는 정보를 artists라는 별도 표로 한 번만 저장하고, artworks에서는 "몇 번 작가"라는
> 숫자(FK)만 들고 있습니다. 그래서 작가 정보 수정은 artists 테이블 한 행만 고치면 모든 작품에
> 자동으로 반영되고, DB 엔진이 FK 제약으로 "있지도 않은 작가 번호" 같은 깨진 데이터를 애초에
> 막아줍니다. 즉 데이터 중복과 일관성 문제를 DB 자체가 구조적으로 해결해 줍니다.

**Q. PK와 FK의 역할을 구분하고, 1:N 관계가 데이터를 어떻게 연결하는지 본인 스킬 기준으로 보여줄 수 있는가?**
> PK(artist_id, artwork_id …)는 "그 테이블 안에서 이 행을 유일하게 식별하는 값"이고,
> FK(artworks.artist_id)는 "다른 테이블의 PK를 가리키는 값"입니다. artists.artist_id=1이
> "Vincent van Gogh"를 가리키고, artworks 테이블의 여러 행이 artist_id=1을 FK로 들고 있으면
> 그 여러 작품이 전부 반 고흐 작품이라는 뜻이 됩니다. 이게 1:N이고, SQL에서는
> `JOIN artists ON artworks.artist_id = artists.artist_id`로 실제로 연결해서 조회합니다.

**Q. INNER JOIN과 LEFT JOIN의 차이를 실행 결과를 보며 짚어줄 수 있는가?**
> `sql/03_queries.sql`의 [조인 3]을 보면, artworks를 curation_logs와 LEFT JOIN했습니다.
> INNER JOIN이었다면 큐레이션 로그가 한 번도 안 남은 작품(92점 중 상당수)은 결과에서
> 통째로 빠집니다. 하지만 LEFT JOIN을 쓰면 그런 작품도 결과에 남고, 대신 오른쪽 테이블
> (curation_logs) 쪽 컬럼(action, action_date)이 NULL로 채워져서 나옵니다. 실제로
> [서브쿼리] 쿼리(`NOT IN (SELECT artwork_id FROM curation_logs)`)로 로그가 없는 작품만
> 따로 뽑아보면 그 작품들이 LEFT JOIN 결과에서 NULL로 나온 것과 정확히 일치합니다.

**Q. GROUP BY와 집계 함수(COUNT, SUM, AVG)가 어떻게 동작하는지 쿼리 결과를 보며 이야기할 수 있는가?**
> [집계 1]은 `GROUP BY c.name`으로 분류별로 행을 묶은 뒤, 각 묶음 안에서
> `COUNT(*)`(묶음 안 행 개수)와 `AVG(ar.year_start)`(묶음 안 연도 평균)를 계산합니다.
> 결과를 보면 Photographs 묶음은 평균 제작연도가 1881년으로 가장 최근이고,
> Jade Carvings 묶음은 작품 수가 4건으로 가장 적습니다. [집계 3]은 여기에
> `HAVING COUNT(*) >= 5`를 더해서, "묶은 결과 중에서도 집계값이 조건을 만족하는 묶음만"
> 다시 거릅니다 — Edgar Degas, Albrecht Dürer처럼 작품 5점 이상인 작가만 남는 걸 확인했습니다.

### 항목 4 — 회고

**Q. 작성한 쿼리 중 가장 복잡했던 쿼리를 선택하고, 어떻게 풀었는지 단계별로 설명할 수 있는가?**
> [조인 4] "작가별 최고령 작품 1건씩"이 가장 복잡했습니다.
> 1) 먼저 "작가별 가장 오래된 연도가 몇 년인지"를 `GROUP BY artist_id` + `MIN(year_start)`로
>    구하는 서브쿼리(oldest)를 따로 만들었습니다.
> 2) artworks를 이 서브쿼리와 `artist_id`와 `year_start = min_year` 두 조건으로 JOIN해서,
>    "그 작가의 최솟값 연도와 실제로 일치하는 작품 행"만 남겼습니다.
> 3) 마지막으로 artists와 다시 JOIN해서 작가 이름을 붙였습니다.
> 단순히 `ORDER BY year_start LIMIT 1`을 작가별로 하고 싶었지만 LIMIT은 작가별로 따로
> 적용할 수 없어서, "먼저 최솟값을 집계로 구하고 그 값과 다시 매칭한다"는 2단계 접근으로
> 풀었습니다.

**Q. 미션 수행 중 가장 어려웠던 부분과 해결 방법을 구체적으로 말할 수 있는가?**
> 원본 art.db에는 약 78,000건이 있는데, 그대로 쓰면 작가/분류 중복이 너무 많고 전형적인
> "비정규화된 단일 테이블"이라 이 미션(PK/FK 1:N 관계 증명)에는 안 맞았습니다. 그래서
> classification/medium 원본 텍스트(예: "Oil on canvas", "Woodblock print; ink and color on paper")를
> 정규식으로 12개 상위 분류로 다시 묶고, 분류마다 실제 작가가 최소 몇 명씩은 포함되도록
> 샘플을 다시 뽑는 스크립트(`build_data.py`)를 짜는 과정이 가장 오래 걸렸습니다. 특히 처음에는
> 유명 화가 16명만 고정해서 뽑았더니 분류가 "회화/판화/드로잉" 3~4종으로만 쏠려서, 분류별로
> 먼저 후보를 묶고(bucket) 그 안에서 작가를 뽑는 방식으로 바꿔서 분류 12종을 모두 채웠습니다.

### 항목 5 — 보너스
> 이번 제출에는 보너스 문제를 별도로 풀지 않았다 (미부여).
