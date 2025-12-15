-- ===============================================================
-- Запросы клиента
-- ===============================================================

-- 1. Фильтры и сортировка
-- "Найти все книги издательства 'Наука', изданные до 1900 года"
SELECT title, publish_year 
FROM book 
WHERE publisher_id = (SELECT publisher_id FROM publisher WHERE name = 'Наука')
  AND publish_year < 1900
ORDER BY publish_year;

-- 2. Left join
-- "Показать всех авторов и книги, которые они написали (если есть)"
SELECT a.last_name, b.title 
FROM author a
LEFT JOIN book_author ba ON a.author_id = ba.author_id
LEFT JOIN book b ON ba.book_id = b.book_id;

-- 3. Group by
-- "Сколько книг каждого издательства есть в фонде?"
SELECT p.name, COUNT(b.book_id) as book_count
FROM publisher p
JOIN book b ON p.publisher_id = b.publisher_id
GROUP BY p.name;

-- 4. Фильтрация групп через having
-- "Издательства, у которых общая стоимость книг превышает 200000"
SELECT p.name, SUM(b.estimated_value) as total_value
FROM publisher p
JOIN book b ON p.publisher_id = b.publisher_id
GROUP BY p.name
HAVING SUM(b.estimated_value) > 200000;

-- 5. Подзапрос в SELECT
-- "Список книг с указанием, насколько их стоимость выше средней по библиотеке"
SELECT title, estimated_value, 
       (estimated_value - (SELECT AVG(estimated_value) FROM book)) as diff_from_avg
FROM book;

-- 6. Подзапрос в WHERE
-- "Книги авторов, родившихся в 19 веке (1801-1900)"
SELECT title 
FROM book 
WHERE book_id IN (
    SELECT book_id 
    FROM book_author ba 
    JOIN author a ON ba.author_id = a.author_id 
    WHERE a.birth_year BETWEEN 1801 AND 1900
);

-- 7. Подзапрос с EXISTS
-- "Посетители, которые никогда не брали книги (нет записей в loan)"
SELECT last_name, first_name 
FROM visitor v
WHERE NOT EXISTS (SELECT 1 FROM loan l WHERE l.visitor_id = v.visitor_id);

-- 8. Соединение запросов через Union
-- "Общий список всех людей в базе (Авторы + Посетители) для рассылки поздравлений"
SELECT first_name, last_name, 'Author' as role FROM author
UNION
SELECT first_name, last_name, 'Visitor' as role FROM visitor
ORDER BY last_name;

-- 9. Update с подзапросом
-- "Поднять оценочную стоимость на 10% для книг самого популярного издательства"
UPDATE book
SET estimated_value = estimated_value * 1.10
WHERE publisher_id = (
    SELECT publisher_id 
    FROM book 
    GROUP BY publisher_id 
    ORDER BY COUNT(*) DESC 
    LIMIT 1
);

-- 10. Удаление с подзапросом
-- "Удалить из очереди ожидания заявки, которым больше года"
DELETE FROM waiting_list
WHERE request_date < (CURRENT_TIMESTAMP - INTERVAL '1 year');

-- 11. Использование созданного view
-- "Получить список особо ценных книг из представления каталога"
SELECT title, authors, publisher 
FROM v_full_catalog
WHERE category = 'Особо ценная';

-- 12. Получение самой популярная книги по "количеству выдач"
SELECT b.title, COUNT(l.loan_id) as loans_cnt
FROM book b
JOIN loan l ON b.book_id = l.book_id
GROUP BY b.title
ORDER BY loans_cnt DESC
LIMIT 1;

-- 13. Update с подзапросом в SELECT
-- "Обновить стоимость книг, изданных до 2000 года, увеличив ее на разницу между текущей ценой и средней ценой книги изданной за последние 5 лет."
UPDATE book
SET estimated_value = estimated_value + (
    SELECT AVG(estimated_value) 
    FROM book 
    WHERE publish_year >= EXTRACT(YEAR FROM CURRENT_DATE) - 5
) / 10
WHERE publish_year < 2000;
