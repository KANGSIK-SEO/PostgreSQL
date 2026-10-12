-- 공공 미술관 오픈데이터(MET/AIC/CMA) 소장품 DB — 쿼리 15개
-- 구성: 기본조회 4 / 조인 4 / 집계 3 / 서브쿼리 1 / 수정·삭제 2 / 인덱스 1

-- =========================================================
-- [기본조회 1] 1900년 이전에 제작된 퍼블릭 도메인 작품을 제작연도 순으로 조회
-- =========================================================
SELECT artwork_id, title, year_start, medium
FROM artworks
WHERE is_public_domain = TRUE AND year_start < 1900
ORDER BY year_start
LIMIT 10;

-- =========================================================
-- [기본조회 2] 분류(classification)가 'Photographs'인 작품만 조회
-- =========================================================
SELECT a.artwork_id, a.title, a.year_start, a.medium
FROM artworks a
JOIN classifications c ON a.classification_id = c.classification_id
WHERE c.name = 'Photographs'
ORDER BY a.year_start;

-- =========================================================
-- [기본조회 3] 하이라이트(대표 소장품)로 지정된 작품 목록
-- =========================================================
SELECT artwork_id, title, source_code, year_start
FROM artworks
WHERE is_highlight = TRUE
ORDER BY year_start;

-- =========================================================
-- [기본조회 4] 작가 이름에 'van'이 들어가는 작가 조회 (대소문자 무시)
-- =========================================================
SELECT artist_id, name, nationality
FROM artists
WHERE name ILIKE '%van%'
ORDER BY name;

-- =========================================================
-- [조인 1] 작품 - 작가 INNER JOIN: 각 작품의 작가 국적 함께 표시
-- =========================================================
SELECT ar.title, au.name AS artist_name, au.nationality
FROM artworks ar
JOIN artists au ON ar.artist_id = au.artist_id
ORDER BY ar.title
LIMIT 15;

-- =========================================================
-- [조인 2] 작품 - 부서 - 분류 3중 JOIN: 소장 기관/부서/분류를 한번에 조회
-- =========================================================
SELECT ar.title, d.museum_name, d.name AS department_name, c.name AS classification_name
FROM artworks ar
JOIN departments d ON ar.department_id = d.department_id
JOIN classifications c ON ar.classification_id = c.classification_id
ORDER BY d.museum_name, d.name
LIMIT 15;

-- =========================================================
-- [조인 3] LEFT JOIN: 전체 작품에 대해 큐레이션 로그가 있으면 함께, 없으면 NULL로 표시
-- (INNER JOIN과 달리 로그가 없는 작품도 결과에서 빠지지 않음을 확인)
-- =========================================================
SELECT ar.artwork_id, ar.title, cl.action, cl.action_date
FROM artworks ar
LEFT JOIN curation_logs cl ON ar.artwork_id = cl.artwork_id
ORDER BY ar.artwork_id
LIMIT 20;

-- =========================================================
-- [조인 4] 작가별 최고령(가장 오래된) 작품 1건씩 — JOIN + 집계 서브쿼리 혼합
-- =========================================================
SELECT au.name AS artist_name, ar.title, ar.year_start
FROM artworks ar
JOIN artists au ON ar.artist_id = au.artist_id
JOIN (
    SELECT artist_id, MIN(year_start) AS min_year
    FROM artworks
    WHERE year_start IS NOT NULL
    GROUP BY artist_id
) oldest ON ar.artist_id = oldest.artist_id AND ar.year_start = oldest.min_year
ORDER BY ar.year_start
LIMIT 15;

-- =========================================================
-- [집계 1] 분류(classification)별 작품 수와 평균 제작연도
-- =========================================================
SELECT c.name AS classification_name, COUNT(*) AS artwork_count, ROUND(AVG(ar.year_start)) AS avg_year
FROM artworks ar
JOIN classifications c ON ar.classification_id = c.classification_id
GROUP BY c.name
ORDER BY artwork_count DESC;

-- =========================================================
-- [집계 2] 소장 기관(museum)별 작품 수
-- =========================================================
SELECT d.museum_name, COUNT(*) AS artwork_count
FROM artworks ar
JOIN departments d ON ar.department_id = d.department_id
GROUP BY d.museum_name
ORDER BY artwork_count DESC;

-- =========================================================
-- [집계 3] 작품을 5건 이상 보유한 작가만 집계 (HAVING)
-- =========================================================
SELECT au.name AS artist_name, COUNT(*) AS artwork_count
FROM artworks ar
JOIN artists au ON ar.artist_id = au.artist_id
GROUP BY au.name
HAVING COUNT(*) >= 5
ORDER BY artwork_count DESC;

-- =========================================================
-- [서브쿼리] 큐레이션 로그가 한 번도 생성되지 않은 작품 찾기 (NOT IN 서브쿼리)
-- =========================================================
SELECT artwork_id, title, year_start
FROM artworks
WHERE artwork_id NOT IN (SELECT artwork_id FROM curation_logs)
ORDER BY artwork_id
LIMIT 15;

-- =========================================================
-- [수정 1] '비공개처리' 로그가 있는 작품은 is_public_domain을 FALSE로 일괄 수정
-- =========================================================
UPDATE artworks
SET is_public_domain = FALSE
WHERE artwork_id IN (
    SELECT artwork_id FROM curation_logs WHERE action = '비공개처리'
);

-- 수정 결과 확인
SELECT ar.artwork_id, ar.title, ar.is_public_domain
FROM artworks ar
WHERE ar.artwork_id IN (SELECT artwork_id FROM curation_logs WHERE action = '비공개처리');

-- =========================================================
-- [삭제 1] 라이선스 확인만 하고 특별한 의미 없는 '라이선스확인' 로그는 보관 기간이 지나 정리
-- =========================================================
DELETE FROM curation_logs
WHERE action = '라이선스확인' AND action_date < '2026-06-01';

-- 삭제 후 남은 로그 건수 확인
SELECT action, COUNT(*) FROM curation_logs GROUP BY action ORDER BY action;

-- =========================================================
-- [인덱스] year_start/year_end 복합 인덱스(idx_artworks_year) 사용 여부 확인
-- 현재 92행뿐이라 옵티마이저가 Seq Scan을 더 싸다고 판단할 수 있으므로,
-- enable_seqscan을 잠시 꺼서 idx_artworks_year가 실제로 사용 가능함을 확인한다.
-- =========================================================
EXPLAIN ANALYZE
SELECT title, year_start, year_end
FROM artworks
WHERE year_start BETWEEN 1800 AND 1900;

SET enable_seqscan = off;

EXPLAIN ANALYZE
SELECT title, year_start, year_end
FROM artworks
WHERE year_start BETWEEN 1800 AND 1900;

SET enable_seqscan = on;
