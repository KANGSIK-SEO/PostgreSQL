-- ============================================================
-- 핵심 쿼리 15개
-- 각 쿼리 위에 "무엇을 확인하는 쿼리인지" 한 줄 설명을 붙인다.
-- ============================================================

-- [기본조회 1] 프리미엄 회원을 가입일 최신순으로 5명까지 조회
SELECT id, email, is_premium, created_at
FROM users
WHERE is_premium = TRUE
ORDER BY created_at DESC
LIMIT 5;

-- [기본조회 2] met 출처 작품을 제작연도 오래된 순으로 조회
SELECT id, title, artist, year_start
FROM artworks
WHERE source = 'met'
ORDER BY year_start ASC;

-- [기본조회 3] 응답에 실패(error)한 채팅 로그를 최근순으로 조회
SELECT id, user_id, question, status, created_at
FROM chats
WHERE status = 'error'
ORDER BY created_at DESC;

-- [기본조회 4] cma 출처 작품을 제목순으로 상위 5개 조회
SELECT id, title, artist
FROM artworks
WHERE source = 'cma'
ORDER BY title ASC
LIMIT 5;

-- [조인 1 - INNER] 회원별 채팅 질문/응답 내역 조회
SELECT u.email, c.question, c.answer, c.status, c.created_at
FROM users u
INNER JOIN chats c ON c.user_id = u.id
ORDER BY c.created_at;

-- [조인 2 - INNER] 즐겨찾기한 회원과 작품 정보를 함께 조회
SELECT u.email, a.title, a.artist, f.created_at AS favorited_at
FROM favorites f
INNER JOIN users u ON u.id = f.user_id
INNER JOIN artworks a ON a.id = f.artwork_id
ORDER BY f.created_at;

-- [조인 3 - INNER] 저작권 발급 기록을 작품·회원 정보와 함께 조회 (비로그인 발급 제외)
SELECT r.number, a.title, u.email, r.issued_at
FROM rights_records r
INNER JOIN artworks a ON a.id = r.artwork_id
INNER JOIN users u ON u.id = r.user_id
ORDER BY r.issued_at;

-- [조인 4 - LEFT] 모든 회원을 기준으로, 저작권 발급 기록이 없는 회원도 함께 조회
SELECT u.email, r.number, r.issued_at
FROM users u
LEFT JOIN rights_records r ON r.user_id = u.id
ORDER BY u.id;

-- [집계 1 - COUNT] 회원별 채팅 횟수 집계
SELECT user_id, COUNT(*) AS chat_count
FROM chats
GROUP BY user_id
ORDER BY chat_count DESC;

-- [집계 2 - AVG] 출처(source)별 작품 평균 제작연도 집계
SELECT source, ROUND(AVG(year_start), 1) AS avg_year_start
FROM artworks
GROUP BY source
ORDER BY avg_year_start;

-- [집계 3 - SUM] 채팅 상태(status)별 총 응답 지연시간(ms) 합계
SELECT status, SUM(latency_ms) AS total_latency_ms, COUNT(*) AS cnt
FROM chats
GROUP BY status;

-- [서브쿼리] 채팅 기록이 한 번도 없는 회원 찾기
SELECT email
FROM users
WHERE id NOT IN (SELECT DISTINCT user_id FROM chats);

-- [수정] 채팅을 2회 이상 사용한 회원을 프리미엄으로 승급
UPDATE users
SET is_premium = TRUE
WHERE id IN (
    SELECT user_id FROM chats GROUP BY user_id HAVING COUNT(*) >= 2
) AND is_premium = FALSE;

-- [삭제] 응답에 실패(error)하고 지연시간이 2000ms를 넘는 채팅 로그 삭제 (장애성 기록 정리)
DELETE FROM chats
WHERE status = 'error' AND latency_ms > 2000;

-- [인덱스] 회원별 최근 채팅 조회가 가장 빈번해 (user_id, created_at) 복합 인덱스를 둔다
-- (01_schema.sql에서 이미 생성됨: idx_chats_user_time)
CREATE INDEX IF NOT EXISTS idx_chats_user_time ON chats (user_id, created_at);
