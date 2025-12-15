-- ===============================================================
-- Запросы для проверки бизнес-логики
-- ===============================================================

-- Предварительная очистка нужных таблиц
TRUNCATE loan, reservation, waiting_list RESTART IDENTITY CASCADE;
UPDATE book SET is_available = TRUE;

-- ---------------------------------------------------------------
-- Проверка register_loan и триггера доступности
-- ---------------------------------------------------------------
DO $$
DECLARE
    v_avail BOOLEAN;
BEGIN
    RAISE NOTICE 'Выдача свободной книги';
    CALL register_loan(1, 1, 14);
    
    -- Проверяем
    SELECT is_available INTO v_avail FROM book WHERE book_id = 1;
    
    IF v_avail = FALSE THEN
        RAISE NOTICE 'OK: Книга успешно выдана (is_available = FALSE)';
    ELSE
        RAISE EXCEPTION 'ERR: Статус книги не изменился';
    END IF;
END $$;

-- ---------------------------------------------------------------
-- Проверка check_book_availability
-- ---------------------------------------------------------------
DO $$
BEGIN
    RAISE NOTICE 'Попытка взять уже выданную книгу';
    CALL register_loan(1, 2, 7);

    RAISE EXCEPTION 'ERR: Получилось выдать занятую книгу';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'OK: Получена ожидаемая ошибка: %', SQLERRM;
END $$;

-- ---------------------------------------------------------------
-- Проверка триггера возврата книги tr_on_return
-- ---------------------------------------------------------------
DO $$
DECLARE
    v_avail BOOLEAN;
BEGIN
    RAISE NOTICE 'Возврат книги и авто-обновление статуса';
    
    UPDATE loan 
    SET actual_return_date = CURRENT_DATE 
    WHERE book_id = 1 AND actual_return_date IS NULL;
    
    SELECT is_available INTO v_avail FROM book WHERE book_id = 1;
    
    IF v_avail = TRUE THEN
        RAISE NOTICE 'OK: Книга возвращена (is_available = TRUE)';
    ELSE
        RAISE EXCEPTION 'ERR: Книга возвращена, статус не обновился';
    END IF;
END $$;

-- ---------------------------------------------------------------
-- Проверка триггера очереди ожидания tr_book_became_free
-- ---------------------------------------------------------------
DO $$
DECLARE
    v_wait_status VARCHAR;
BEGIN
    RAISE NOTICE 'Работа очереди ожидания';
    
    -- Снова выдаем книгу 1 посетителю 2
    CALL register_loan(1, 2, 10);
    
    -- Посетитель 3 встает в очередь на книгу 1
    INSERT INTO waiting_list(wait_id, book_id, visitor_id, status)
    VALUES (100, 1, 3, 'active');
    
    RAISE NOTICE '(Книга выдана)';
    
    -- Возвращаем книгу (срабатывает триггер tr_on_return -> update book -> триггер tr_book_became_free)
    UPDATE loan SET actual_return_date = CURRENT_DATE WHERE book_id = 1 AND visitor_id = 2;
    
    -- Проверяем статус заявки в очереди
    SELECT status INTO v_wait_status FROM waiting_list WHERE wait_id = 100;
    
    IF v_wait_status = 'fulfilled' THEN
        RAISE NOTICE 'OK: Книга освободилась, статус заявки сменился на fulfilled';
    ELSE
        RAISE EXCEPTION 'ERR: Статус заявки остался %', v_wait_status;
    END IF;
END $$;

-- ---------------------------------------------------------------
-- Проверка триггера на дату бронирования tr_check_res_dates
-- ---------------------------------------------------------------
DO $$
BEGIN
    RAISE NOTICE 'Попытка бронирования в прошлом';
    
    INSERT INTO reservation(reservation_id, book_id, visitor_id, start_date, end_date)
    VALUES (999, 2, 1, CURRENT_DATE - 5, CURRENT_DATE - 1);
    
    RAISE EXCEPTION 'ERR: Пропуск даты в прошлом';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'OK: Получена ожидаемая ошибка: %', SQLERRM;
END $$;

-- ---------------------------------------------------------------
-- Провека процедуры расчета штрафов calculate_fines
-- ---------------------------------------------------------------
DO $$
BEGIN
    RAISE NOTICE 'Расчет штрафов';
    
    -- Создаем искусственную просрочку: выдали давно, вернуть должны были вчера, не вернули
    INSERT INTO loan (loan_id, book_id, visitor_id, issue_date, return_date, actual_return_date)
    VALUES (999, 5, 3, CURRENT_DATE - 20, CURRENT_DATE - 5, NULL);
    
    CALL calculate_fines();
    
    RAISE NOTICE 'OK: Процедура выполнена';
END $$;

-- ---------------------------------------------------------------
-- Проверка Представлений
-- ---------------------------------------------------------------
CALL raise_notice('Проверка данных в представлениях');

CALL raise_notice('v_active_loans: Ожидаем 1 просроченную запись с ID 999');
SELECT * FROM v_active_loans WHERE loan_id = 999; 

CALL raise_notice('v_full_catalog: Проверка форматирования авторов');
SELECT title, authors, category FROM v_full_catalog LIMIT 3;

CALL raise_notice('v_visitor_stats: Проверка счетчика');
SELECT * FROM v_visitor_stats WHERE visitor_id = 3;
