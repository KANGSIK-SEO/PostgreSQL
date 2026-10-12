-- ============================================================
-- 보너스 과제
-- ============================================================

-- 1) 같은 요구를 JOIN과 서브쿼리 두 방식으로 풀어보기
--    요구: "하나 이상의 즐겨찾기를 가진 회원의 이메일 목록"

-- 1-A. JOIN 방식 (DISTINCT로 중복 제거)
SELECT DISTINCT u.email
FROM users u
JOIN favorites f ON f.user_id = u.id
ORDER BY u.email;

-- 1-B. 서브쿼리(EXISTS) 방식
SELECT u.email
FROM users u
WHERE EXISTS (SELECT 1 FROM favorites f WHERE f.user_id = u.id)
ORDER BY u.email;
-- 비교: JOIN은 일치하는 행만큼 결과가 늘어날 수 있어 DISTINCT가 필요하고,
-- EXISTS는 조건을 만족하는지만 보고 멈추므로 중복 처리가 필요 없다. 결과는 동일하다.

-- 2) 데이터 정합성 깨뜨려 보기: 존재하지 않는 회원을 참조하는 채팅을 넣어본다
-- INSERT INTO chats (user_id, question, status) VALUES (9999, '테스트', 'ok');
-- 실행 결과(실제 캡처): ERROR:  insert or update on table "chats" violates foreign key
--            constraint "chats_user_id_fkey"
--            상세정보:  Key (user_id)=(9999) is not present in table "users".
-- 막히는 이유: chats.user_id가 users(id)를 참조하는 FOREIGN KEY라, 부모 테이블에
--            없는 값은 자식 테이블에 들어갈 수 없다(참조 무결성).
-- 고치는 방법: 존재하는 user_id를 쓰거나, users 테이블에 그 회원을 먼저 추가한다.

-- 3) 미니 리포트: 이 DB로 뽑을 수 있는 핵심 지표 3개

-- 3-1. 월별 채팅 건수 추이
SELECT to_char(created_at, 'YYYY-MM') AS month, COUNT(*) AS chat_count
FROM chats
GROUP BY month
ORDER BY month;

-- 3-2. 가장 즐겨찾기가 많이 된 작품 TOP 5
SELECT a.title, a.artist, COUNT(*) AS favorite_count
FROM favorites f
JOIN artworks a ON a.id = f.artwork_id
GROUP BY a.id, a.title, a.artist
ORDER BY favorite_count DESC
LIMIT 5;

-- 3-3. 채팅 실패율(error 비율)이 가장 높은 회원 목록
SELECT u.email,
       COUNT(*) AS total_chats,
       SUM(CASE WHEN c.status = 'error' THEN 1 ELSE 0 END) AS error_chats,
       ROUND(100.0 * SUM(CASE WHEN c.status = 'error' THEN 1 ELSE 0 END) / COUNT(*), 1) AS error_rate_pct
FROM users u
JOIN chats c ON c.user_id = u.id
GROUP BY u.id, u.email
HAVING SUM(CASE WHEN c.status = 'error' THEN 1 ELSE 0 END) > 0
ORDER BY error_rate_pct DESC;
