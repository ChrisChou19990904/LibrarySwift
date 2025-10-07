CREATE DATABASE IF NOT EXISTS DBSpringBoot;
USE DBSpringBoot;

DROP TABLE IF EXISTS loans ;
DROP TABLE IF EXISTS book_copies ;
DROP TABLE IF EXISTS books ;
DROP TABLE IF EXISTS category ;
DROP TABLE IF EXISTS publishers ;
DROP TABLE IF EXISTS user_details ;
DROP TABLE IF EXISTS users ;


CREATE TABLE users (
                       id INT PRIMARY KEY AUTO_INCREMENT,
                       card_id VARCHAR(50) UNIQUE NOT NULL,
                       account VARCHAR(50) UNIQUE NOT NULL,
                       password VARCHAR(255) NOT NULL,
                       role VARCHAR(50) NOT NULL DEFAULT 'ROLE_USER' COMMENT '使用者角色 (例如: ROLE_USER, ROLE_ADMIN)'
);


CREATE TABLE user_details (
                              user_id INT PRIMARY KEY,
                              name VARCHAR(100) NOT NULL,
                              email VARCHAR(255) UNIQUE NOT NULL,
                              phone VARCHAR(20),
                              address VARCHAR(255),
                              FOREIGN KEY (user_id) REFERENCES users(id)
);


CREATE TABLE publishers (
                            id INT PRIMARY KEY AUTO_INCREMENT,
                            pub_name VARCHAR(255) UNIQUE NOT NULL
);


CREATE TABLE category (
                          id INT PRIMARY KEY AUTO_INCREMENT,
                          category_title VARCHAR(100) UNIQUE NOT NULL
);


CREATE TABLE books (
                       id INT PRIMARY KEY AUTO_INCREMENT,
                       image_url VARCHAR(255) DEFAULT NULL,
                       title VARCHAR(255) NOT NULL,
                       author VARCHAR(255) NOT NULL,
                       category_id INT,
                       publish_year INT,
                       publisher_id INT,
                       price DECIMAL(10, 2),
                       FOREIGN KEY (category_id) REFERENCES category(id),
                       FOREIGN KEY (publisher_id) REFERENCES publishers(id)
);
CREATE INDEX idx_books_title ON books (title);
CREATE INDEX idx_books_author ON books (author);
CREATE INDEX idx_books_publisher ON books (publisher_id);

CREATE TABLE book_copies (
                             id INT PRIMARY KEY AUTO_INCREMENT,
                             book_id INT NOT NULL,
                             unique_code VARCHAR(50) UNIQUE NOT NULL,
                             status ENUM('A', 'L', 'R') DEFAULT 'A', -- R (Reserved) 表預約
                             FOREIGN KEY (book_id) REFERENCES books(id)
);
CREATE INDEX idx_book_copies_unique_code ON book_copies (unique_code);


CREATE TABLE loans (
                       id INT PRIMARY KEY AUTO_INCREMENT,
                       user_id INT NOT NULL,
                       book_copies_id INT NOT NULL,
                       loan_date DATETIME DEFAULT CURRENT_TIMESTAMP,
                       return_date DATETIME NULL, -- 允許為 NULL，表示尚未歸還
                       FOREIGN KEY (user_id) REFERENCES users(id),
                       FOREIGN KEY (book_copies_id) REFERENCES book_copies(id)
);
CREATE INDEX idx_loans_user_id ON loans (user_id);
CREATE INDEX idx_loans_book_copies_id ON loans (book_copies_id);


-- mock data
-- 1. 插入 publishers 資料
INSERT INTO publishers (pub_name) VALUES
                                      ('皇冠文化'),
                                      ('究竟出版'),
                                      ('三采文化'),
                                      ('東立出版'),
                                      ('碁峯資訊'),
                                      ('博碩文化');

-- 2. 插入 category 資料
INSERT INTO category (category_title) VALUES
                                          ('文學小說'),
                                          ('漫畫'),
                                          ('程式設計'),
                                          ('心理勵志');

-- 3. 插入 users 資料，只有一個指定為ROLE_ADMIN
INSERT INTO users (card_id, account, password, role) VALUES
                                                         ('LIB001', 'adminJAVA', '$2a$10$6SdLHZBE4tE6KfW9SrgKpeVl0fxUxyPbVHVJpjO5giOwr/6/tkWAm', 'ROLE_ADMIN'),
                                                         ('LIB002', 'userJAVA', '$2a$10$6SdLHZBE4tE6KfW9SrgKpeVl0fxUxyPbVHVJpjO5giOwr/6/tkWAm', 'ROLE_USER'),
                                                         ('LIB003', 'changthird33', 'hashed_password_3', 'ROLE_USER'),
                                                         ('LIB004', 'leefour44', 'hashed_password_4', 'ROLE_USER'),
                                                         ('LIB005', 'wongfive55', 'hashed_password_5', 'ROLE_USER');

-- 4. 插入 user_details 資料
INSERT INTO user_details (user_id, name, email, phone, address) VALUES
                                                                    (1, '管理者', 'admin@example.com', '0912345678', '台北市信義區忠孝東路100號'),
                                                                    (2, '一般人', 'user@example.com', '0911222333', '新北市板橋區文化路200號'),
                                                                    (3, '張三', 'changthird@example.com', '0934567890', '台中市西屯區台灣大道300號'),
                                                                    (4, '李四', 'leefour@example.com', '0945678901', '高雄市苓雅區中山路400號'),
                                                                    (5, '王五', 'wongfive@example.com', '0945678901', '台南市中西區西門路一段500號');

-- 5. 插入 books 資料
INSERT INTO books (title, author, category_id, publish_year, publisher_id, price, image_url) VALUES
                                                                                      ('GOTH斷掌事件', '乙一', (SELECT id FROM category WHERE category_title = '文學小說'), 2002, (SELECT id FROM publishers WHERE pub_name = '皇冠文化'), 270.00, 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTuxofcdv-oOC_4Qvao34xUbCrHA_871k0_7kD4kNnR7wvuWGTRyO3WolbOZ0xRVYHUz5E&usqp=CAU'),
                                                                                      ('哈利波特：神秘的魔法石', 'J.K.羅琳', (SELECT id FROM category WHERE category_title = '文學小說'), 1997, (SELECT id FROM publishers WHERE pub_name = '皇冠文化'), 350.00, 'https://upload.wikimedia.org/wikipedia/zh/3/3c/Hp1tw.jpg'),
                                                                                      ('被討厭的勇氣', '岸見一郎', (SELECT id FROM category WHERE category_title = '心理勵志'), 2014, (SELECT id FROM publishers WHERE pub_name = '究竟出版'), 280.00, 'https://cdn.kobo.com/book-images/78553f24-ced7-4f1d-8515-5546421ebd4d/1200/1200/False/nvedXSs0ujimMMwueunJew.jpg'),
                                                                                      ('世界盡頭的咖啡館', 'John Strelecky', (SELECT id FROM category WHERE category_title = '心理勵志'), 2021, (SELECT id FROM publishers WHERE pub_name = '三采文化'), 320.00, 'https://resize-image.vocus.cc/resize?norotation=true&quality=80&url=https%3A%2F%2Fimages.vocus.cc%2Fd9412fd5-5947-4663-85f3-40452909fb8e.jpg&width=740&sign=cZ31-LFPPLPVTsSmQQkt81cfS6jT6vWSAJcctnQAt-c'),
                                                                                      ('銀魂', '空知英秋', (SELECT id FROM category WHERE category_title = '漫畫'), 2003, (SELECT id FROM publishers WHERE pub_name = '東立出版'), 95.00, 'https://upload.wikimedia.org/wikipedia/zh/4/44/%E9%8A%80%E9%AD%8201.jpg'),
                                                                                      ('鏈鋸人', '藤本タツキ', (SELECT id FROM category WHERE category_title = '漫畫'), 2018, (SELECT id FROM publishers WHERE pub_name = '東立出版'), 110.00, 'https://upload.wikimedia.org/wikipedia/zh/e/e7/Chainsaw_Man_Volume_1_Cover.jpg'),
                                                                                      ('Java SE 17 技術手冊', '林信良', (SELECT id FROM category WHERE category_title = '程式設計'), 2019, (SELECT id FROM publishers WHERE pub_name = '碁峯資訊'), 680.00, 'https://im1.book.com.tw/image/getImage?i=https://www.books.com.tw/img/001/092/37/0010923732.jpg&v=626bbe47k&w=375&h=375'),
                                                                                      ('你的第一本 Linux 入門書', '陳會安', (SELECT id FROM category WHERE category_title = '程式設計'), 2018, (SELECT id FROM publishers WHERE pub_name = '博碩文化'), 620.00, 'https://s.eslite.com/b2b/newItem/ebook_init/main1_457605.jpg');


-- 6. 插入 book_copies 資料
INSERT INTO book_copies (book_id, unique_code, status) VALUES
                                                           ((SELECT id FROM books WHERE title = 'GOTH斷掌事件'), 'GOTH001A', 'A'), -- Available
                                                           ((SELECT id FROM books WHERE title = 'GOTH斷掌事件'), 'GOTH001B', 'A'), -- Available
                                                           ((SELECT id FROM books WHERE title = 'GOTH斷掌事件'), 'GOTH001C', 'A'), -- Available
                                                           ((SELECT id FROM books WHERE title = '哈利波特：神秘的魔法石'), 'HP001A', 'A'),
                                                           ((SELECT id FROM books WHERE title = '哈利波特：神秘的魔法石'), 'HP001B', 'L'), -- On Loan
                                                           ((SELECT id FROM books WHERE title = '哈利波特：神秘的魔法石'), 'HP001C', 'A'), -- On Loan
                                                           ((SELECT id FROM books WHERE title = '被討厭的勇氣'), 'DY001A', 'A'),
                                                           ((SELECT id FROM books WHERE title = '被討厭的勇氣'), 'DY001B', 'L'),
                                                           ((SELECT id FROM books WHERE title = '被討厭的勇氣'), 'DY001C', 'A'),
                                                           ((SELECT id FROM books WHERE title = '世界盡頭的咖啡館'), 'WEC001A', 'A'),
                                                           ((SELECT id FROM books WHERE title = '世界盡頭的咖啡館'), 'WEC001B', 'A'),
                                                           ((SELECT id FROM books WHERE title = '世界盡頭的咖啡館'), 'WEC001C', 'A'),
                                                           ((SELECT id FROM books WHERE title = '銀魂'), 'GINTAMA001', 'A'),
                                                           ((SELECT id FROM books WHERE title = '銀魂'), 'GINTAMA002', 'L'),
                                                           ((SELECT id FROM books WHERE title = '銀魂'), 'GINTAMA003', 'A'),
                                                           ((SELECT id FROM books WHERE title = '鏈鋸人'), 'CSM001A', 'A'),
                                                           ((SELECT id FROM books WHERE title = '鏈鋸人'), 'CSM001B', 'A'),
                                                           ((SELECT id FROM books WHERE title = '鏈鋸人'), 'CSM001C', 'L'),
                                                           ((SELECT id FROM books WHERE title = 'Java SE 17 技術手冊'), 'JAVA17A', 'A'),
                                                           ((SELECT id FROM books WHERE title = 'Java SE 17 技術手冊'), 'JAVA17B', 'L'),
                                                           ((SELECT id FROM books WHERE title = 'Java SE 17 技術手冊'), 'JAVA17C', 'A'),
                                                           ((SELECT id FROM books WHERE title = '你的第一本 Linux 入門書'), 'LINUX001', 'A'),
                                                           ((SELECT id FROM books WHERE title = '你的第一本 Linux 入門書'), 'LINUX002', 'A'),
                                                           ((SELECT id FROM books WHERE title = '你的第一本 Linux 入門書'), 'LINUX003', 'A');


-- 7. 插入 loans 資料
INSERT INTO loans (user_id, book_copies_id, loan_date, return_date) VALUES
                                                                        ((SELECT id FROM users WHERE account = 'adminJAVA'), (SELECT id FROM book_copies WHERE unique_code = 'HP001B'), '2025-06-28 10:00:00', NULL), -- 劉一借了哈利波特B，未還
                                                                        ((SELECT id FROM users WHERE account = 'userJAVA'), (SELECT id FROM book_copies WHERE unique_code = 'DY001B'), '2025-06-25 14:30:00', NULL), -- 陳二借了被討厭的勇氣B，未還
                                                                        ((SELECT id FROM users WHERE account = 'changthird33'), (SELECT id FROM book_copies WHERE unique_code = 'GINTAMA002'), '2025-06-20 09:00:00', NULL), -- 張三借了銀魂002，未還
                                                                        ((SELECT id FROM users WHERE account = 'leefour44'), (SELECT id FROM book_copies WHERE unique_code = 'CSM001C'), '2025-06-18 11:00:00', NULL), -- 李四借了鏈鋸人C，未還
                                                                        ((SELECT id FROM users WHERE account = 'wongfive55'), (SELECT id FROM book_copies WHERE unique_code = 'JAVA17B'), '2025-06-22 15:00:00', NULL), -- 王五借了Java SE 17 B，未還
                                                                        ((SELECT id FROM users WHERE account = 'adminJAVA'), (SELECT id FROM book_copies WHERE unique_code = 'GOTH001A'), '2025-06-01 11:00:00', '2025-06-10 16:00:00'), -- 劉一借了GOTH001A，已還
                                                                        ((SELECT id FROM users WHERE account = 'userJAVA'), (SELECT id FROM book_copies WHERE unique_code = 'WEC001A'), '2025-05-20 10:00:00', '2025-06-05 12:00:00'); -- 陳二借了世界盡頭的咖啡館A，已還



SELECT * FROM users ;
SELECT * FROM user_details ;
SELECT * FROM publishers ;
SELECT * FROM category ;
SELECT * FROM books ;
SELECT * FROM book_copies ;
SELECT * FROM loans ;



-- 借閱 --
INSERT INTO loans (user_id, book_copies_id, loan_date, return_date) VALUES
    (1,  1, '2025-07-28 10:00:00', NULL);

SELECT * FROM book_copies WHERE book_id = 7 AND status = 'A' ORDER BY id ASC LIMIT 1;

SELECT * FROM loans WHERE user_id = 2 AND return_date IS NULL ;
SELECT * FROM loans;

-- 歸還 --
START TRANSACTION;

UPDATE loans
SET return_date = NOW() -- 設定歸還日期為當前時間
WHERE book_copies_id = (SELECT id FROM book_copies WHERE unique_code = 'GOTH001A' )
  AND user_id = 2;

UPDATE book_copies
SET status = 'A' -- 更新副本狀態為可借閱
WHERE  unique_code = 'GOTH001A' ; -- 假設這是要歸還的書籍碼

COMMIT;




