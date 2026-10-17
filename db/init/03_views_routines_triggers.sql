CREATE OR REPLACE VIEW vw_active_books_catalog AS
SELECT 
    b.id AS book_id,
    b.isbn,
    b.title,
    b.publication_year,
    g.name AS genre_name,
    p.name AS publisher_name,
    COALESCE(STRING_AGG(DISTINCT a.first_name || ' ' || a.last_name, ', '), 'Без автора') AS authors_list,
    COUNT(DISTINCT bc.id) AS total_copies,
    COUNT(DISTINCT bc.id) FILTER (WHERE bc.status = 'Available' AND bc.is_deleted = FALSE) AS available_copies,
    b.updated_at,
    b.updated_by
FROM books b
JOIN genres g ON b.genre_id = g.id
JOIN publishers p ON b.publisher_id = p.id
LEFT JOIN book_authors ba ON b.id = ba.book_id
LEFT JOIN authors a ON ba.author_id = a.id
LEFT JOIN book_copies bc ON b.id = bc.book_id AND bc.is_deleted = FALSE
WHERE b.is_deleted = FALSE
GROUP BY b.id, b.isbn, b.title, b.publication_year, g.name, p.name, b.updated_at, b.updated_by;

CREATE OR REPLACE VIEW vw_overdue_loans AS
SELECT 
    l.id AS loan_id,
    rp.id AS reader_profile_id,
    rp.library_card_number,
    u.full_name AS reader_name,
    u.phone AS reader_phone,
    u.email AS reader_email,
    l.loan_date,
    l.due_date,
    (CURRENT_DATE - l.due_date) AS overdue_days,
    COUNT(li.id) AS unreturned_items_count,
    ROUND((CURRENT_DATE - l.due_date) * 15.00 * COUNT(li.id), 2) AS estimated_fine_amount
FROM loans l
JOIN reader_profiles rp ON l.reader_profile_id = rp.id
JOIN users u ON rp.user_id = u.id
JOIN loan_items li ON l.id = li.loan_id
WHERE l.status = 'Active' 
  AND l.due_date < CURRENT_DATE 
  AND li.returned_at IS NULL
GROUP BY l.id, rp.id, rp.library_card_number, u.full_name, u.phone, u.email, l.loan_date, l.due_date;

CREATE OR REPLACE VIEW vw_reader_service_spending AS
SELECT 
    rp.id AS reader_profile_id,
    rp.library_card_number,
    u.full_name AS reader_name,
    COUNT(DISTINCT so.id) AS total_orders,
    COALESCE(SUM(soi.subtotal), 0.00) AS total_spent_uah,
    COALESCE(SUM(soi.quantity) FILTER (WHERE sc.name ILIKE '%друк%' OR sc.name ILIKE '%копіювання%'), 0) AS total_print_pages,
    COALESCE(SUM(soi.quantity) FILTER (WHERE sc.name ILIKE '%коворкінг%' OR sc.name ILIKE '%місце%'), 0) AS total_workspace_hours
FROM reader_profiles rp
JOIN users u ON rp.user_id = u.id
LEFT JOIN service_orders so ON rp.id = so.reader_profile_id AND so.payment_status = 'Paid'
LEFT JOIN service_order_items soi ON so.id = soi.order_id
LEFT JOIN services s ON soi.service_id = s.id
LEFT JOIN service_categories sc ON s.category_id = sc.id
GROUP BY rp.id, rp.library_card_number, u.full_name;

CREATE OR REPLACE VIEW vw_active_services_catalog AS
SELECT 
    s.id AS service_id,
    sc.name AS category_name,
    s.name AS service_name,
    s.description,
    s.unit_price,
    s.pricing_unit,
    s.updated_at
FROM services s
JOIN service_categories sc ON s.category_id = sc.id
WHERE s.is_active = TRUE AND s.is_deleted = FALSE;

CREATE OR REPLACE FUNCTION fn_calculate_overdue_fine(
    p_due_date DATE,
    p_return_date DATE,
    p_daily_rate NUMERIC DEFAULT 15.00
) 
RETURNS NUMERIC AS $$
DECLARE
    v_overdue_days INT;
BEGIN
    IF p_return_date <= p_due_date THEN
        RETURN 0.00;
    END IF;
    
    v_overdue_days := p_return_date - p_due_date;
    RETURN ROUND(v_overdue_days * p_daily_rate, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION fn_get_reader_active_loans_count(
    p_reader_profile_id INT
) 
RETURNS INT AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(li.id) INTO v_count
    FROM loans l
    JOIN loan_items li ON l.id = li.loan_id
    WHERE l.reader_profile_id = p_reader_profile_id 
      AND l.status = 'Active' 
      AND li.returned_at IS NULL;
      
    RETURN COALESCE(v_count, 0);
END;
$$ LANGUAGE plpgsql STABLE;

CREATE OR REPLACE PROCEDURE sp_borrow_books(
    p_reader_profile_id INT,
    p_staff_user_id INT,
    p_copy_ids INT[],
    p_loan_days INT,
    INOUT p_loan_id INT DEFAULT NULL
)
LANGUAGE plpgsql AS $$
DECLARE
    v_copy_id INT;
    v_copy_status VARCHAR(30);
    v_is_deleted BOOLEAN;
    v_unpaid_fines NUMERIC(10,2);
    v_active_loans INT;
BEGIN
    IF p_copy_ids IS NULL OR array_length(p_copy_ids, 1) IS NULL OR array_length(p_copy_ids, 1) = 0 THEN
        RAISE EXCEPTION 'Список примірників для видачі не може бути порожнім';
    END IF;

    SELECT total_fines_due INTO v_unpaid_fines
    FROM reader_profiles 
    WHERE id = p_reader_profile_id;

    IF v_unpaid_fines > 100.00 THEN
        RAISE EXCEPTION 'Неможливо видати книги: у читача є заборгованість по штрафах у розмірі % грн (ліміт 100 грн)', v_unpaid_fines;
    END IF;

    v_active_loans := fn_get_reader_active_loans_count(p_reader_profile_id);
    IF (v_active_loans + array_length(p_copy_ids, 1)) > 5 THEN
        RAISE EXCEPTION 'Перевищено ліміт: читач уже має % книг, не можна взяти більше 5 одночасно', v_active_loans;
    END IF;

    FOREACH v_copy_id IN ARRAY p_copy_ids LOOP
        SELECT status, is_deleted INTO v_copy_status, v_is_deleted
        FROM book_copies 
        WHERE id = v_copy_id;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Примірник книги з ID % не знайдено', v_copy_id;
        END IF;

        IF v_is_deleted THEN
            RAISE EXCEPTION 'Примірник з ID % було списано (Soft Delete)', v_copy_id;
        END IF;

        IF v_copy_status <> 'Available' THEN
            RAISE EXCEPTION 'Примірник з ID % недоступний для видачі (поточний статус: %)', v_copy_id, v_copy_status;
        END IF;
    END LOOP;

    INSERT INTO loans (reader_profile_id, staff_user_id, loan_date, due_date, status)
    VALUES (p_reader_profile_id, p_staff_user_id, CURRENT_DATE, CURRENT_DATE + p_loan_days, 'Active')
    RETURNING id INTO p_loan_id;

    FOREACH v_copy_id IN ARRAY p_copy_ids LOOP
        INSERT INTO loan_items (loan_id, book_copy_id)
        VALUES (p_loan_id, v_copy_id);

        UPDATE book_copies 
        SET status = 'Borrowed'
        WHERE id = v_copy_id;
    END LOOP;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_return_book_copy(
    p_loan_id INT,
    p_copy_id INT,
    p_condition VARCHAR,
    p_staff_user_id INT,
    INOUT p_fine_id INT DEFAULT NULL
)
LANGUAGE plpgsql AS $$
DECLARE
    v_loan_due_date DATE;
    v_reader_profile_id INT;
    v_fine_amount NUMERIC(10,2);
    v_remaining_items INT;
BEGIN
    SELECT l.due_date, l.reader_profile_id 
    INTO v_loan_due_date, v_reader_profile_id
    FROM loans l
    JOIN loan_items li ON l.id = li.loan_id
    WHERE l.id = p_loan_id 
      AND li.book_copy_id = p_copy_id 
      AND li.returned_at IS NULL;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Активну видачу для позики ID % та примірника ID % не знайдено або вже повернуто', p_loan_id, p_copy_id;
    END IF;

    UPDATE loan_items 
    SET returned_at = clock_timestamp(),
        condition_on_return = p_condition
    WHERE loan_id = p_loan_id AND book_copy_id = p_copy_id;

    UPDATE book_copies
    SET status = CASE WHEN p_condition = 'Damaged' THEN 'Damaged' ELSE 'Available' END,
        condition = p_condition
    WHERE id = p_copy_id;

    IF CURRENT_DATE > v_loan_due_date THEN
        v_fine_amount := fn_calculate_overdue_fine(v_loan_due_date, CURRENT_DATE, 15.00);

        INSERT INTO fines (loan_id, reader_profile_id, amount, reason, status, updated_by)
        VALUES (p_loan_id, v_reader_profile_id, v_fine_amount, 
                'Прострочення повернення книги на ' || (CURRENT_DATE - v_loan_due_date) || ' дн.', 
                'Pending', p_staff_user_id)
        RETURNING id INTO p_fine_id;

        UPDATE reader_profiles 
        SET total_fines_due = total_fines_due + v_fine_amount,
            updated_at = clock_timestamp(),
            updated_by = p_staff_user_id
        WHERE id = v_reader_profile_id;
    END IF;

    IF p_condition = 'Damaged' THEN
        INSERT INTO fines (loan_id, reader_profile_id, amount, reason, status, updated_by)
        VALUES (p_loan_id, v_reader_profile_id, 150.00, 'Компенсація за пошкодження книги', 'Pending', p_staff_user_id);

        UPDATE reader_profiles 
        SET total_fines_due = total_fines_due + 150.00,
            updated_at = clock_timestamp(),
            updated_by = p_staff_user_id
        WHERE id = v_reader_profile_id;
    END IF;

    SELECT COUNT(*) INTO v_remaining_items
    FROM loan_items 
    WHERE loan_id = p_loan_id AND returned_at IS NULL;

    IF v_remaining_items = 0 THEN
        UPDATE loans 
        SET status = 'Closed' 
        WHERE id = p_loan_id;
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_create_service_order(
    p_reader_profile_id INT,
    p_staff_user_id INT,
    p_service_ids INT[],
    p_quantities INT[],
    p_payment_method VARCHAR,
    INOUT p_order_id INT DEFAULT NULL
)
LANGUAGE plpgsql AS $$
DECLARE
    v_i INT;
    v_service_id INT;
    v_qty INT;
    v_unit_price NUMERIC(10,2);
    v_subtotal NUMERIC(10,2);
    v_total_amount NUMERIC(10,2) := 0.00;
    v_is_active BOOLEAN;
    v_is_deleted BOOLEAN;
BEGIN
    IF p_service_ids IS NULL OR p_quantities IS NULL OR array_length(p_service_ids, 1) IS NULL OR array_length(p_service_ids, 1) = 0 THEN
        RAISE EXCEPTION 'Список замовлених послуг не може бути порожнім';
    END IF;

    IF array_length(p_service_ids, 1) <> array_length(p_quantities, 1) THEN
        RAISE EXCEPTION 'Кількість послуг не відповідає кількості вказаних обсягів';
    END IF;

    INSERT INTO service_orders (reader_profile_id, staff_user_id, total_amount, payment_status, payment_method)
    VALUES (p_reader_profile_id, p_staff_user_id, 0.00, 'Paid', p_payment_method)
    RETURNING id INTO p_order_id;

    FOR v_i IN 1..array_length(p_service_ids, 1) LOOP
        v_service_id := p_service_ids[v_i];
        v_qty := p_quantities[v_i];

        SELECT unit_price, is_active, is_deleted 
        INTO v_unit_price, v_is_active, v_is_deleted
        FROM services 
        WHERE id = v_service_id;

        IF NOT FOUND OR v_is_deleted OR NOT v_is_active THEN
            RAISE EXCEPTION 'Послуга ID % недоступна для замовлення', v_service_id;
        END IF;

        v_subtotal := ROUND(v_unit_price * v_qty, 2);
        v_total_amount := v_total_amount + v_subtotal;

        INSERT INTO service_order_items (order_id, service_id, quantity, unit_price, subtotal)
        VALUES (p_order_id, v_service_id, v_qty, v_unit_price, v_subtotal);
    END LOOP;

    UPDATE service_orders 
    SET total_amount = v_total_amount 
    WHERE id = p_order_id;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_soft_delete_book(
    p_book_id INT,
    p_user_id INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_borrowed_count INT;
BEGIN
    SELECT COUNT(*) INTO v_borrowed_count
    FROM book_copies bc
    JOIN loan_items li ON bc.id = li.book_copy_id
    JOIN loans l ON li.loan_id = l.id
    WHERE bc.book_id = p_book_id 
      AND l.status = 'Active' 
      AND li.returned_at IS NULL;

    IF v_borrowed_count > 0 THEN
        RAISE EXCEPTION 'Неможливо списати книгу ID %: % примірників наразі перебувають на руках у читачів', p_book_id, v_borrowed_count;
    END IF;

    UPDATE books 
    SET is_deleted = TRUE,
        deleted_at = clock_timestamp(),
        updated_at = clock_timestamp(),
        updated_by = p_user_id
    WHERE id = p_book_id;

    UPDATE book_copies 
    SET is_deleted = TRUE,
        deleted_at = clock_timestamp()
    WHERE book_id = p_book_id;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_pay_fine(
    p_fine_id INT,
    p_staff_user_id INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_reader_id INT;
    v_amount NUMERIC(10,2);
    v_status VARCHAR(30);
BEGIN
    SELECT reader_profile_id, amount, status 
    INTO v_reader_id, v_amount, v_status
    FROM fines 
    WHERE id = p_fine_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Штраф з ID % не знайдено', p_fine_id;
    END IF;

    IF v_status = 'Paid' THEN
        RAISE EXCEPTION 'Штраф з ID % уже сплачено', p_fine_id;
    END IF;

    UPDATE fines 
    SET status = 'Paid',
        updated_at = clock_timestamp(),
        updated_by = p_staff_user_id
    WHERE id = p_fine_id;

    UPDATE reader_profiles 
    SET total_fines_due = GREATEST(0.00, total_fines_due - v_amount),
        updated_at = clock_timestamp(),
        updated_by = p_staff_user_id
    WHERE id = v_reader_id;
END;
$$;

CREATE OR REPLACE FUNCTION fn_trg_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := clock_timestamp();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_books_set_updated_at ON books;
CREATE TRIGGER trg_books_set_updated_at
BEFORE UPDATE ON books
FOR EACH ROW
EXECUTE FUNCTION fn_trg_set_updated_at();

DROP TRIGGER IF EXISTS trg_services_set_updated_at ON services;
CREATE TRIGGER trg_services_set_updated_at
BEFORE UPDATE ON services
FOR EACH ROW
EXECUTE FUNCTION fn_trg_set_updated_at();

DROP TRIGGER IF EXISTS trg_fines_set_updated_at ON fines;
CREATE TRIGGER trg_fines_set_updated_at
BEFORE UPDATE ON fines
FOR EACH ROW
EXECUTE FUNCTION fn_trg_set_updated_at();

CREATE OR REPLACE FUNCTION fn_trg_prevent_delete_borrowed_copy()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF OLD.status = 'Borrowed' THEN
            RAISE EXCEPTION 'Заборонено видаляти примірник ID %, оскільки він зараз знаходиться у читача!', OLD.id;
        END IF;
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        IF NEW.is_deleted = TRUE AND OLD.status = 'Borrowed' THEN
            RAISE EXCEPTION 'Заборонено позначати примірник ID % як списаний (Soft Delete), доки він не повернутий читачем!', OLD.id;
        END IF;
        RETURN NEW;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_book_copies_prevent_delete ON book_copies;
CREATE TRIGGER trg_book_copies_prevent_delete
BEFORE DELETE OR UPDATE OF is_deleted ON book_copies
FOR EACH ROW
EXECUTE FUNCTION fn_trg_prevent_delete_borrowed_copy();
