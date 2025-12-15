-- ===============================================================
-- Создание таблиц
-- ===============================================================

-- Издательства
CREATE TABLE IF NOT EXISTS publisher (
    publisher_id    INTEGER         NOT NULL,
    name            VARCHAR(100)    NOT NULL UNIQUE,
    city            VARCHAR(50),
    CONSTRAINT publisher_pk PRIMARY KEY (publisher_id)
);

-- Авторы
CREATE TABLE IF NOT EXISTS author (
    author_id       INTEGER         NOT NULL,
    last_name       VARCHAR(50)     NOT NULL,
    first_name      VARCHAR(50)     NOT NULL,
    middle_name     VARCHAR(50),
    birth_year      INTEGER         CHECK (birth_year > 0 AND birth_year < 2025),
    CONSTRAINT author_pk PRIMARY KEY (author_id)
);

-- Посетители
CREATE TABLE IF NOT EXISTS visitor (
    visitor_id      INTEGER         NOT NULL,
    last_name       VARCHAR(50)     NOT NULL,
    first_name      VARCHAR(50)     NOT NULL,
    passport_num    VARCHAR(20)     NOT NULL UNIQUE,
    phone           VARCHAR(20)     NOT NULL,
    email           VARCHAR(100),
    registration_date DATE          NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT visitor_pk PRIMARY KEY (visitor_id)
);

-- Книги
CREATE TABLE IF NOT EXISTS book (
    book_id         INTEGER         NOT NULL,
    title           VARCHAR(200)    NOT NULL,
    publisher_id    INTEGER,
    publish_year    INTEGER         CHECK (publish_year <= EXTRACT(YEAR FROM CURRENT_DATE)),
    circulation     INTEGER         CHECK (circulation > 0),
    estimated_value DECIMAL(10, 2)  CHECK (estimated_value > 0),
    is_available    BOOLEAN         NOT NULL DEFAULT TRUE,
    CONSTRAINT book_pk PRIMARY KEY (book_id)
);

-- Книги-Авторы
CREATE TABLE IF NOT EXISTS book_author (
    book_id         INTEGER         NOT NULL,
    author_id       INTEGER         NOT NULL,
    CONSTRAINT book_author_pk PRIMARY KEY (book_id, author_id)
);

-- Выдача книг
CREATE TABLE IF NOT EXISTS loan (
    loan_id             INTEGER     NOT NULL,
    book_id             INTEGER     NOT NULL,
    visitor_id          INTEGER     NOT NULL,
    issue_date          DATE        NOT NULL DEFAULT CURRENT_DATE,
    return_date         DATE,       -- Планируемая дата возврата
    actual_return_date  DATE,       -- Фактическая дата
    CONSTRAINT loan_pk PRIMARY KEY (loan_id),
    CONSTRAINT chk_loan_dates CHECK (actual_return_date >= issue_date OR actual_return_date IS NULL)
);

-- Бронирование
CREATE TABLE IF NOT EXISTS reservation (
    reservation_id  INTEGER         NOT NULL,
    book_id         INTEGER         NOT NULL,
    visitor_id      INTEGER         NOT NULL,
    start_date      DATE            NOT NULL,
    end_date        DATE            NOT NULL,
    created_at      TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT reservation_pk PRIMARY KEY (reservation_id),
    CONSTRAINT chk_res_dates CHECK (end_date >= start_date)
);

-- Очередь ожидания
CREATE TABLE IF NOT EXISTS waiting_list (
    wait_id         INTEGER         NOT NULL,
    book_id         INTEGER         NOT NULL,
    visitor_id      INTEGER         NOT NULL,
    request_date    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status          VARCHAR(20)     DEFAULT 'active' CHECK (status IN ('active', 'fulfilled', 'cancelled')),
    CONSTRAINT waiting_list_pk PRIMARY KEY (wait_id)
);

-- ===============================================================
-- Добавление FK
-- ===============================================================

ALTER TABLE book
ADD CONSTRAINT FK_Book_Publisher
FOREIGN KEY (publisher_id) REFERENCES publisher(publisher_id) ON DELETE SET NULL;

ALTER TABLE book_author
ADD CONSTRAINT FK_BookAuthor_Book
FOREIGN KEY (book_id) REFERENCES book(book_id) ON DELETE CASCADE;

ALTER TABLE book_author
ADD CONSTRAINT FK_BookAuthor_Author
FOREIGN KEY (author_id) REFERENCES author(author_id) ON DELETE CASCADE;

ALTER TABLE loan
ADD CONSTRAINT FK_Loan_Book
FOREIGN KEY (book_id) REFERENCES book(book_id);

ALTER TABLE loan
ADD CONSTRAINT FK_Loan_Visitor
FOREIGN KEY (visitor_id) REFERENCES visitor(visitor_id);

ALTER TABLE reservation
ADD CONSTRAINT FK_Reservation_Book
FOREIGN KEY (book_id) REFERENCES book(book_id) ON DELETE CASCADE;

ALTER TABLE reservation
ADD CONSTRAINT FK_Reservation_Visitor
FOREIGN KEY (visitor_id) REFERENCES visitor(visitor_id) ON DELETE CASCADE;

ALTER TABLE waiting_list
ADD CONSTRAINT FK_Waiting_Book
FOREIGN KEY (book_id) REFERENCES book(book_id) ON DELETE CASCADE;

ALTER TABLE waiting_list
ADD CONSTRAINT FK_Waiting_Visitor
FOREIGN KEY (visitor_id) REFERENCES visitor(visitor_id) ON DELETE CASCADE;

-- ===============================================================
-- Индексы
-- ===============================================================
CREATE INDEX idx_book_title ON book(title);
CREATE INDEX idx_loan_active ON loan(visitor_id) WHERE actual_return_date IS NULL;
CREATE INDEX idx_reservation_dates ON reservation(book_id, start_date, end_date);
CREATE INDEX idx_visitor_lastname ON visitor(last_name);
