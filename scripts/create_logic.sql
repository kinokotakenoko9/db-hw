-- ===============================================================
-- Представления
-- ===============================================================

-- Полный каталог книг (Книги + Авторы одной строкой + Издательство)
CREATE OR REPLACE VIEW v_full_catalog AS
SELECT 
    b.book_id,
    b.title,
    p.name AS publisher,
    b.publish_year,
    STRING_AGG(a.last_name || ' ' || LEFT(a.first_name, 1) || '.', ', ') AS authors,
    b.is_available,
    CASE WHEN b.estimated_value > 50000 THEN 'Особо ценная' ELSE 'Обычная' END AS category
FROM book b
JOIN publisher p ON b.publisher_id = p.publisher_id
JOIN book_author ba ON b.book_id = ba.book_id
JOIN author a ON ba.author_id = a.author_id
GROUP BY b.book_id, b.title, p.name, b.publish_year, b.is_available, b.estimated_value;

-- Активные выдачи (Кто что сейчас читает)
CREATE OR REPLACE VIEW v_active_loans AS
SELECT 
    l.loan_id,
    b.title,
    v.last_name || ' ' || v.first_name AS visitor_name,
    l.issue_date,
    l.return_date,
    (CURRENT_DATE - l.issue_date) AS days_held
FROM loan l
JOIN book b ON l.book_id = b.book_id
JOIN visitor v ON l.visitor_id = v.visitor_id
WHERE l.actual_return_date IS NULL;

-- Рейтинг самых читающих посетителей
CREATE OR REPLACE VIEW v_visitor_stats AS
SELECT 
    v.visitor_id,
    v.last_name,
    COUNT(l.loan_id) as total_loans
FROM visitor v
LEFT JOIN loan l ON v.visitor_id = l.visitor_id
GROUP BY v.visitor_id, v.last_name;

-- ===============================================================
-- Функции и Процедуры
-- ===============================================================

-- Проверка доступности книги (учитывается статус и бронь)
CREATE OR REPLACE FUNCTION check_book_availability(p_book_id INTEGER) 
RETURNS BOOLEAN AS $$
DECLARE
    v_is_avail BOOLEAN;
    v_reserved_count INTEGER;
BEGIN
    SELECT is_available INTO v_is_avail FROM book WHERE book_id = p_book_id;
    
    SELECT COUNT(*) INTO v_reserved_count 
    FROM reservation 
    WHERE book_id = p_book_id 
      AND CURRENT_DATE BETWEEN start_date AND end_date;

    IF v_is_avail = TRUE AND v_reserved_count = 0 THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Регистрация выдачи книги
CREATE OR REPLACE PROCEDURE register_loan(
    p_book_id INTEGER, 
    p_visitor_id INTEGER, 
    p_days INTEGER
) LANGUAGE plpgsql AS $$
BEGIN
    IF NOT check_book_availability(p_book_id) THEN
        RAISE EXCEPTION 'Книга % недоступна для выдачи', p_book_id;
    END IF;

    INSERT INTO loan (loan_id, book_id, visitor_id, issue_date, return_date)
    VALUES (
        (SELECT COALESCE(MAX(loan_id), 0) + 1 FROM loan),
        p_book_id, 
        p_visitor_id, 
        CURRENT_DATE, 
        CURRENT_DATE + p_days
    );

    UPDATE book SET is_available = FALSE WHERE book_id = p_book_id;
    
    COMMIT;
END;
$$;

-- Процедура с курсором: генерация отчета о просрочках (проходим по должникам и начисляет штраф)
CREATE OR REPLACE PROCEDURE calculate_fines()
LANGUAGE plpgsql AS $$
DECLARE
    cur_loans CURSOR FOR 
        SELECT loan_id, (CURRENT_DATE - return_date) as overdue_days 
        FROM loan 
        WHERE actual_return_date IS NULL AND return_date < CURRENT_DATE;
    
    rec RECORD;
    fine_amount DECIMAL;
BEGIN
    OPEN cur_loans;
    
    LOOP
        FETCH cur_loans INTO rec;
        EXIT WHEN NOT FOUND;
        
        fine_amount := rec.overdue_days * 100.00;
        
        RAISE NOTICE 'Запись выдачи #%: просрочка % дн., штраф % руб.', 
                     rec.loan_id, rec.overdue_days, fine_amount;
    END LOOP;
    
    CLOSE cur_loans;
END;
$$;

-- ===============================================================
-- Триггеры
-- ===============================================================

-- Автоматическое обновление статуса книги при возврате
CREATE OR REPLACE FUNCTION tf_on_return() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.actual_return_date IS NOT NULL AND OLD.actual_return_date IS NULL THEN
        UPDATE book SET is_available = TRUE WHERE book_id = NEW.book_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_on_return
AFTER UPDATE ON loan
FOR EACH ROW
EXECUTE FUNCTION tf_on_return();

-- Запрет бронирования, если даты в прошлом
CREATE OR REPLACE FUNCTION tf_check_res_dates() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.start_date < CURRENT_DATE THEN
        RAISE EXCEPTION 'Нельзя бронировать книгу в прошлом!';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_check_res_dates
BEFORE INSERT ON reservation
FOR EACH ROW
EXECUTE FUNCTION tf_check_res_dates();

-- Логирование попадания в очередь ожидания. Если книга освободилась, проверяем очередь ожидания
CREATE OR REPLACE FUNCTION tf_check_waiting_list() RETURNS TRIGGER AS $$
DECLARE
    v_wait_id INTEGER;
BEGIN
    SELECT wait_id INTO v_wait_id 
    FROM waiting_list 
    WHERE book_id = NEW.book_id AND status = 'active' 
    ORDER BY request_date ASC 
    LIMIT 1;

    IF v_wait_id IS NOT NULL THEN
        UPDATE waiting_list SET status = 'fulfilled' WHERE wait_id = v_wait_id;
        RAISE NOTICE 'Книга % освободилась! Заявка % в очереди обработана.', NEW.book_id, v_wait_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_book_became_free
AFTER UPDATE OF is_available ON book
FOR EACH ROW
WHEN (NEW.is_available = TRUE)
EXECUTE FUNCTION tf_check_waiting_list();
