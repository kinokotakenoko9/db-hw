-- ===============================================================
-- Удаление таблиц
-- ===============================================================
DROP TABLE IF EXISTS waiting_list CASCADE;
DROP TABLE IF EXISTS reservation CASCADE;
DROP TABLE IF EXISTS loan CASCADE;
DROP TABLE IF EXISTS book_author CASCADE;
DROP TABLE IF EXISTS book CASCADE;
DROP TABLE IF EXISTS visitor CASCADE;
DROP TABLE IF EXISTS author CASCADE;
DROP TABLE IF EXISTS publisher CASCADE;

-- ===============================================================
-- Удаление логики: тригеры, функции, процедуры
-- ===============================================================

DROP TRIGGER IF EXISTS tr_book_became_free ON book;
DROP FUNCTION IF EXISTS tf_check_waiting_list;

DROP TRIGGER IF EXISTS tr_check_res_dates ON reservation;
DROP FUNCTION IF EXISTS tf_check_res_dates;

DROP TRIGGER IF EXISTS tr_on_return ON loan;
DROP FUNCTION IF EXISTS tf_on_return;

DROP PROCEDURE IF EXISTS calculate_fines;
DROP PROCEDURE IF EXISTS register_loan;
DROP FUNCTION IF EXISTS check_book_availability;

-- ===============================================================
-- Удаление представлений
-- ===============================================================

DROP VIEW IF EXISTS v_visitor_stats;
DROP VIEW IF EXISTS v_active_loans;
DROP VIEW IF EXISTS v_full_catalog;
