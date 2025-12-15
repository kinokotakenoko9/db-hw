-- ===============================================================
-- Заполнение данными
-- ===============================================================

INSERT INTO publisher(publisher_id, name, city) VALUES 
(1, 'Наука', 'Москва'),
(2, 'Просвещение', 'Москва'),
(3, 'Азбука-Аттикус', 'Санкт-Петербург'),
(4, 'Academia', 'Москва'),
(5, 'Oxford University Press', 'Oxford');

INSERT INTO author(author_id, last_name, first_name, middle_name, birth_year) VALUES 
(1, 'Пушкин', 'Александр', 'Сергеевич', 1799),
(2, 'Достоевский', 'Федор', 'Михайлович', 1821),
(3, 'Толстой', 'Лев', 'Николаевич', 1828),
(4, 'Булгаков', 'Михаил', 'Афанасьевич', 1891),
(5, 'Набоков', 'Владимир', 'Владимирович', 1899);

INSERT INTO book(book_id, title, publisher_id, publish_year, circulation, estimated_value, is_available) VALUES 
(1, 'Евгений Онегин (Прижизненное)', 1, 1833, 1200, 500000.00, TRUE),
(2, 'Преступление и наказание', 2, 1866, 3000, 150000.00, TRUE),
(3, 'Война и мир. Том 1', 2, 1869, 4800, 200000.00, FALSE), -- На руках
(4, 'Мастер и Маргарита (Рукопись)', 4, 1966, 1, 1000000.00, TRUE),
(5, 'Lolita (First Edition)', 5, 1955, 5000, 12000.50, TRUE);

INSERT INTO book_author(book_id, author_id) VALUES 
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5);

INSERT INTO visitor(visitor_id, last_name, first_name, passport_num, phone, email) VALUES 
(1, 'Иванов', 'Иван', '4020 123456', '+79001112233', 'ivanov@mail.ru'),
(2, 'Петров', 'Петр', '4020 654321', '+79004445566', 'petrov@yandex.ru'),
(3, 'Сидорова', 'Анна', '4505 987654', '+79115556677', 'anna.sid@gmail.com');

INSERT INTO loan(loan_id, book_id, visitor_id, issue_date, return_date, actual_return_date) VALUES 
(1, 1, 1, '2023-01-10', '2023-01-20', '2023-01-19'),
(2, 2, 2, '2023-02-01', '2023-02-15', '2023-02-20'),
(3, 3, 3, '2023-03-05', '2023-03-15', NULL); -- Книга еще у Сидоровой

INSERT INTO reservation(reservation_id, book_id, visitor_id, start_date, end_date) VALUES 
(1, 1, 2, '2023-12-01', '2023-12-10');

-- Иванов ждет книгу 3, которая у Сидоровой
INSERT INTO waiting_list(wait_id, book_id, visitor_id, request_date, status) VALUES 
(1, 3, 1, '2023-03-10 10:00:00', 'active');
