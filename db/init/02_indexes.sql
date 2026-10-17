CREATE INDEX idx_loans_reader_status 
ON loans USING btree (reader_profile_id, status);

CREATE INDEX idx_fines_reader_status 
ON fines USING btree (reader_profile_id, status);

CREATE INDEX idx_service_orders_reader_date 
ON service_orders USING btree (reader_profile_id, order_date DESC);

CREATE INDEX idx_loan_items_copy_returned 
ON loan_items USING btree (book_copy_id, returned_at);

CREATE INDEX idx_books_active 
ON books USING btree (isbn, title) 
WHERE is_deleted = FALSE;

CREATE INDEX idx_book_copies_available 
ON book_copies USING btree (book_id, location_shelf) 
WHERE status = 'Available' AND is_deleted = FALSE;

CREATE INDEX idx_loans_active_due_date 
ON loans USING btree (due_date) 
WHERE status = 'Active';

CREATE INDEX idx_services_active_catalog 
ON services USING btree (category_id, unit_price) 
WHERE is_active = TRUE AND is_deleted = FALSE;

CREATE INDEX idx_books_fts_title_desc 
ON books USING gin (to_tsvector('english', title || ' ' || COALESCE(description, '')));

CREATE INDEX idx_book_copies_inventory_hash 
ON book_copies USING hash (inventory_number);
