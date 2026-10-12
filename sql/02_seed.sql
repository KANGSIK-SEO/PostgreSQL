-- ============================================================
-- 샘플 데이터 입력
-- 주의: FK가 참조하는 부모 테이블(users, artworks)을 먼저 채우고,
--       그 다음 자식 테이블(chats, favorites, rights_records)을 채운다.
-- 각 테이블 id는 BIGSERIAL이 1부터 순서대로 부여하므로, 아래 주석의
-- 번호(users 1~10, artworks 1~12)를 그대로 FK 값으로 사용한다.
-- ============================================================

-- 1. users (10행)  id 1~10
INSERT INTO users (email, password_hash, is_premium, created_at) VALUES
('yuna.kim@example.com',    'hash_a1b2c3', TRUE,  '2026-01-05 09:12:00'),
('minho.lee@example.com',   'hash_d4e5f6', FALSE, '2026-01-08 14:30:00'),
('sora.park@example.com',   'hash_g7h8i9', FALSE, '2026-01-12 10:05:00'),
('jihun.choi@example.com',  'hash_j1k2l3', TRUE,  '2026-01-20 18:45:00'),
('haeun.jung@example.com',  'hash_m4n5o6', FALSE, '2026-02-02 08:20:00'),
('dowon.kang@example.com',  'hash_p7q8r9', FALSE, '2026-02-10 21:00:00'),
('seoyeon.yoon@example.com','hash_s1t2u3', TRUE,  '2026-02-15 13:10:00'),
('taeyang.song@example.com','hash_v4w5x6', FALSE, '2026-03-01 11:55:00'),
('narae.han@example.com',   'hash_y7z8a9', FALSE, '2026-03-09 16:40:00'),
('eunwoo.shin@example.com', 'hash_b1c2d3', TRUE,  '2026-03-18 19:25:00');

-- 2. artworks (12행)  id 1~12
INSERT INTO artworks (source, source_id, title, artist, year_start, year_end, medium, origin, is_public_domain, license, collected_at) VALUES
('met', 'MET-0001', 'Wheat Field with Cypresses',        'Vincent van Gogh',  1889, 1889, 'Oil on canvas',    'Dutch',    TRUE, 'CC0', '2026-01-02 00:00:00'),
('met', 'MET-0002', 'The Starry Night Over the Rhone',   'Vincent van Gogh',  1888, 1888, 'Oil on canvas',    'Dutch',    TRUE, 'CC0', '2026-01-02 00:10:00'),
('met', 'MET-0003', 'Self-Portrait with a Straw Hat',    'Vincent van Gogh',  1887, 1887, 'Oil on canvas',    'Dutch',    TRUE, 'CC0', '2026-01-02 00:20:00'),
('aic', 'AIC-1001', 'A Sunday on La Grande Jatte',        'Georges Seurat',    1884, 1886, 'Oil on canvas',    'French',   TRUE, 'CC0', '2026-01-03 00:00:00'),
('aic', 'AIC-1002', 'Nighthawks',                         'Edward Hopper',     1942, 1942, 'Oil on canvas',    'American', TRUE, 'CC0', '2026-01-03 00:10:00'),
('aic', 'AIC-1003', 'American Gothic',                    'Grant Wood',        1930, 1930, 'Oil on beaverboard','American',TRUE, 'CC0', '2026-01-03 00:20:00'),
('cma', 'CMA-2001', 'La Vie',                             'Pablo Picasso',     1903, 1903, 'Oil on canvas',    'Spanish',  TRUE, 'CC0', '2026-01-04 00:00:00'),
('cma', 'CMA-2002', 'The Repast of the Lion',             'Henri Rousseau',    1907, 1907, 'Oil on canvas',    'French',   TRUE, 'CC0', '2026-01-04 00:10:00'),
('met', 'MET-0004', 'Madame X',                           'John Singer Sargent',1884,1884, 'Oil on canvas',    'American', TRUE, 'CC0', '2026-01-05 00:00:00'),
('aic', 'AIC-1004', 'The Old Guitarist',                  'Pablo Picasso',     1903, 1904, 'Oil on panel',     'Spanish',  TRUE, 'CC0', '2026-01-06 00:00:00'),
('cma', 'CMA-2003', 'The Fisherman',                      'Paul Gauguin',      1888, 1888, 'Oil on canvas',    'French',   TRUE, 'CC0', '2026-01-07 00:00:00'),
('met', 'MET-0005', 'Cypresses',                          'Vincent van Gogh',  1889, 1889, 'Oil on canvas',    'Dutch',    TRUE, 'CC0', '2026-01-08 00:00:00');

-- 3. chats (15행)  user_id는 users 테이블의 1~10을 참조
INSERT INTO chats (user_id, question, answer, status, latency_ms, created_at) VALUES
(1, '반 고흐의 하늘 그림 보여줘',       '고흐의 밤 풍경 작품 2건을 찾았습니다.', 'ok',    820,  '2026-01-05 09:15:00'),
(1, '같은 작가의 자화상도 있어?',       '자화상 1건을 추가로 찾았습니다.',       'ok',    640,  '2026-01-05 09:20:00'),
(2, '미국 작가의 20세기 그림 추천해줘', 'Nighthawks와 American Gothic을 추천합니다.', 'ok', 910, '2026-01-08 14:35:00'),
(3, '피카소 작품 알려줘',               NULL,                                     'error', 1500, '2026-01-12 10:08:00'),
(3, '피카소 초기작 보여줘',             'La Vie, The Old Guitarist를 찾았습니다.', 'ok',   770,  '2026-01-12 10:12:00'),
(4, '프랑스 화가 작품 중 퍼블릭 도메인만', '프랑스 출신 작가 작품 3건입니다.',     'ok',    690,  '2026-01-20 18:50:00'),
(5, '고갱 작품 있어?',                  'The Fisherman을 찾았습니다.',           'ok',    540,  '2026-02-02 08:25:00'),
(6, '고흐 작품 전체 목록',              NULL,                                     'error', 2100, '2026-02-10 21:05:00'),
(6, '고흐 작품 다시 검색해줘',          '고흐 작품 4건을 찾았습니다.',           'ok',    980,  '2026-02-10 21:10:00'),
(7, '1900년대 초 작품 보여줘',          'La Vie, The Old Guitarist 등 4건입니다.','ok',   860,  '2026-02-15 13:15:00'),
(8, '쇠라 작품 설명해줘',               'A Sunday on La Grande Jatte를 설명합니다.','ok', 710,  '2026-03-01 12:00:00'),
(9, '미국 화가 작품만 보고 싶어',       'Nighthawks, American Gothic, Madame X 3건입니다.','ok',930,'2026-03-09 16:45:00'),
(9, '그 중에 가장 최신 작품은?',        'Nighthawks(1942)가 가장 최신입니다.',  'ok',    610,  '2026-03-09 16:50:00'),
(10,'루소 작품 알려줘',                 'The Repast of the Lion을 찾았습니다.',  'ok',    700,  '2026-03-18 19:30:00'),
(10,'존재하지 않는 작가 검색',          NULL,                                     'error', 1800, '2026-03-18 19:35:00');

-- 4. favorites (12행)  user_id -> users, artwork_id -> artworks
INSERT INTO favorites (user_id, artwork_id, created_at) VALUES
(1, 1,  '2026-01-05 09:16:00'),
(1, 2,  '2026-01-05 09:21:00'),
(2, 5,  '2026-01-08 14:36:00'),
(2, 6,  '2026-01-08 14:38:00'),
(3, 7,  '2026-01-12 10:13:00'),
(4, 4,  '2026-01-20 18:52:00'),
(5, 11, '2026-02-02 08:26:00'),
(6, 1,  '2026-02-10 21:11:00'),
(7, 10, '2026-02-15 13:17:00'),
(8, 4,  '2026-03-01 12:02:00'),
(9, 5,  '2026-03-09 16:46:00'),
(10,8,  '2026-03-18 19:31:00');

-- 5. rights_records (10행)  artwork_id -> artworks, user_id -> users (NULL 허용)
INSERT INTO rights_records (number, artwork_id, user_id, snapshot, signature, issued_at) VALUES
('PD-2026-0001', 1,  1,    '{"source":"met","title":"Wheat Field with Cypresses"}', 'sig_0001', '2026-01-05 09:17:00'),
('PD-2026-0002', 2,  1,    '{"source":"met","title":"The Starry Night Over the Rhone"}', 'sig_0002', '2026-01-05 09:22:00'),
('PD-2026-0003', 5,  2,    '{"source":"aic","title":"Nighthawks"}', 'sig_0003', '2026-01-08 14:37:00'),
('PD-2026-0004', 7,  3,    '{"source":"cma","title":"La Vie"}', 'sig_0004', '2026-01-12 10:14:00'),
('PD-2026-0005', 4,  NULL, '{"source":"aic","title":"A Sunday on La Grande Jatte"}', 'sig_0005', '2026-01-20 18:53:00'),
('PD-2026-0006', 11, 5,    '{"source":"cma","title":"The Fisherman"}', 'sig_0006', '2026-02-02 08:27:00'),
('PD-2026-0007', 1,  6,    '{"source":"met","title":"Wheat Field with Cypresses"}', 'sig_0007', '2026-02-10 21:12:00'),
('PD-2026-0008', 10, 7,    '{"source":"aic","title":"The Old Guitarist"}', 'sig_0008', '2026-02-15 13:18:00'),
('PD-2026-0009', 4,  NULL, '{"source":"aic","title":"A Sunday on La Grande Jatte"}', 'sig_0009', '2026-03-01 12:03:00'),
('PD-2026-0010', 8,  10,   '{"source":"cma","title":"The Repast of the Lion"}', 'sig_0010', '2026-03-18 19:32:00');
