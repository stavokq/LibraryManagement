INSERT INTO roles (id, code, name, description) VALUES
(1, 'ADMIN', 'Адміністратор', 'Повний доступ до налаштувань системи та аудиту'),
(2, 'LIBRARIAN', 'Бібліотекар', 'Видача, повернення книг, робота з каталогом та примірниками'),
(3, 'SERVICE_MGR', 'Менеджер послуг', 'Організація додаткових сервісів, друку та коворкінгу'),
(4, 'READER', 'Читач', 'Користувач бібліотеки, абонемент, замовлення послуг')
ON CONFLICT (id) DO NOTHING;

SELECT setval('roles_id_seq', (SELECT MAX(id) FROM roles));

INSERT INTO users (id, role_id, email, password_hash, full_name, phone) VALUES
(1, 1, 'admin@library.ua', 'hash_admin_123', 'Тарас Григорович Шевченко', '+380671112233'),
(2, 2, 'librarian1@library.ua', 'hash_lib_123', 'Олена Миколаївна Ковальчук', '+380502223344'),
(3, 3, 'services@library.ua', 'hash_srv_123', 'Сергій Васильович Бойко', '+380633334455'),
(4, 4, 'reader.melnyk@gmail.com', 'hash_usr_123', 'Василь Мельник', '+380974445566'),
(5, 4, 'reader.bondarenko@gmail.com', 'hash_usr_123', 'Марія Бондаренко', '+380995556677'),
(6, 4, 'reader.petrenko@gmail.com', 'hash_usr_123', 'Іван Петренко', '+380686667788'),
(7, 4, 'reader.kravchenko@gmail.com', 'hash_usr_123', 'Анна Кравченко', '+380937778899')
ON CONFLICT (id) DO NOTHING;

SELECT setval('users_id_seq', (SELECT MAX(id) FROM users));

INSERT INTO reader_profiles (id, user_id, library_card_number, address, date_of_birth, total_fines_due, updated_by) VALUES
(1, 4, 'LIB-2026-0001', 'м. Київ, вул. Хрещатик, 15, кв. 10', '1998-05-14', 0.00, 2),
(2, 5, 'LIB-2026-0002', 'м. Київ, проспект Перемоги, 37, кв. 82', '2001-11-20', 0.00, 2),
(3, 6, 'LIB-2026-0003', 'м. Київ, вул. Володимирська, 42, кв. 5', '1995-02-03', 30.00, 2),
(4, 7, 'LIB-2026-0004', 'м. Київ, вул. Саксаганського, 108, кв. 14', '2003-08-29', 0.00, 2)
ON CONFLICT (id) DO NOTHING;

SELECT setval('reader_profiles_id_seq', (SELECT MAX(id) FROM reader_profiles));

INSERT INTO publishers (id, name, address, phone, website) VALUES
(1, 'Видавництво Старого Лева', 'м. Львів, вул. Лемківська, 15а', '+380800501508', 'https://starylev.com.ua'),
(2, 'Наш Формат', 'м. Київ, пров. Алли Горської, 5', '+380443388704', 'https://nashformat.ua'),
(3, 'А-ба-ба-га-ла-ма-га', 'м. Київ, вул. Басейна, 1/2', '+380442340316', 'https://ababahalamaha.com.ua'),
(4, 'Vivat', 'м. Харків, вул. Гомоненка, 10', '+380577175271', 'https://vivat-book.com.ua'),
(5, 'Фабула', 'м. Харків, вул. Бакуліна, 11', '+380577660166', 'https://fabulabook.com')
ON CONFLICT (id) DO NOTHING;

SELECT setval('publishers_id_seq', (SELECT MAX(id) FROM publishers));

INSERT INTO genres (id, name, description) VALUES
(1, 'Комп''ютерні науки та IT', 'Програмування, системна архітектура, бази даних, алгоритми'),
(2, 'Наукова фантастика', 'Космічні опери, кіберпанк, альтернативне майбутнє'),
(3, 'Історична література', 'Дослідження, хроніки, історія України та світу'),
(4, 'Нон-фікшн та бізнес', 'Менеджмент, маркетинг, саморозвиток, психологія'),
(5, 'Класична проза', 'Шедеври світової та української літератури')
ON CONFLICT (id) DO NOTHING;

SELECT setval('genres_id_seq', (SELECT MAX(id) FROM genres));

INSERT INTO authors (id, first_name, last_name, country, bio) VALUES
(1, 'Роберт', 'Мартін (Uncle Bob)', 'США', 'Легендарний автор концепцій Clean Code, Clean Architecture та Agile Manifesto'),
(2, 'Мартін', 'Клеппманн', 'Велика Британія', 'Дослідник розподілених систем, автор бестселера Designing Data-Intensive Applications'),
(3, 'Френк', 'Герберт', 'США', 'Культовий письменник-фантаст, творець всесвіту Хронік Дюни'),
(4, 'Джордж', 'Орвелл', 'Велика Британія', 'Видатний письменник, автор антиутопії 1984 та Колгоспу тварин'),
(5, 'Сергій', 'Плохій', 'Україна / США', 'Професор Гарвардського університету, провідний дослідник історії Східної Європи')
ON CONFLICT (id) DO NOTHING;

SELECT setval('authors_id_seq', (SELECT MAX(id) FROM authors));

INSERT INTO books (id, isbn, title, publication_year, publisher_id, genre_id, description, updated_by) VALUES
(1, '978-617-7866-25-0', 'Чистий код (Clean Code)', 2021, 2, 1, 'Посібник з написання гнучкого, елегантного та підтримуваного програмного забезпечення', 2),
(2, '978-617-7866-50-2', 'Чиста архітектура (Clean Architecture)', 2022, 2, 1, 'Структура програмного забезпечення: патерни розробки, розділення обов''язків', 2),
(3, '978-617-679-999-1', 'Високонавантажені додатки (Designing Data-Intensive Applications)', 2023, 2, 1, 'Принципи надійності, масштабованості та підтримуваності баз даних і систем', 2),
(4, '978-966-948-213-6', 'Дюна (Dune)', 2020, 5, 2, 'Епічний науково-фантастичний роман про пустельну планету Арракіс', 2),
(5, '978-617-679-245-2', '1984', 2018, 1, 5, 'Класична антиутопія про тоталітаризм, спостереження та маніпуляцію правдою', 2),
(6, '978-617-7329-87-8', 'Брама Європи. Історія України від скіфських воєн до незалежності', 2022, 5, 3, 'Фундаментальне дослідження історії України від одного з головних істориків сучасності', 2)
ON CONFLICT (id) DO NOTHING;

SELECT setval('books_id_seq', (SELECT MAX(id) FROM books));

INSERT INTO book_authors (book_id, author_id, author_role) VALUES
(1, 1, 'Автор'),
(2, 1, 'Автор'),
(3, 2, 'Автор'),
(4, 3, 'Автор'),
(5, 4, 'Автор'),
(6, 5, 'Автор')
ON CONFLICT (book_id, author_id) DO NOTHING;

INSERT INTO book_copies (id, book_id, inventory_number, location_shelf, condition, status) VALUES
(1, 1, 'INV-CC-001', 'Зала 1, Стелаж A-3', 'Excellent', 'Available'),
(2, 1, 'INV-CC-002', 'Зала 1, Стелаж A-3', 'Good', 'Available'),
(3, 1, 'INV-CC-003', 'Зала 1, Стелаж A-3', 'Good', 'Borrowed'),
(4, 2, 'INV-CA-001', 'Зала 1, Стелаж A-4', 'Excellent', 'Available'),
(5, 2, 'INV-CA-002', 'Зала 1, Стелаж A-4', 'Good', 'Available'),
(6, 3, 'INV-DDIA-001', 'Зала 1, Стелаж B-1', 'Excellent', 'Available'),
(7, 3, 'INV-DDIA-002', 'Зала 1, Стелаж B-1', 'Excellent', 'Borrowed'),
(8, 4, 'INV-DUNE-001', 'Зала 2, Стелаж C-2', 'Good', 'Available'),
(9, 4, 'INV-DUNE-002', 'Зала 2, Стелаж C-2', 'Good', 'Available'),
(10, 5, 'INV-1984-001', 'Зала 3, Стелаж E-1', 'Fair', 'Available'),
(11, 6, 'INV-GATE-001', 'Зала 2, Стелаж D-5', 'Excellent', 'Available')
ON CONFLICT (id) DO NOTHING;

SELECT setval('book_copies_id_seq', (SELECT MAX(id) FROM book_copies));

INSERT INTO service_categories (id, name, description) VALUES
(1, 'Поліграфічні послуги', 'Друк, копіювання, сканування, ламінування та зшивання документів'),
(2, 'Оренда робочих зон та обладнання', 'Коворкінг-місця, комп''ютерні станції, звукоізольовані кабінки, електронні рідери'),
(3, 'Освітні заходи та клуби', 'Лекції, курси, книжкові клуби, майстер-класи')
ON CONFLICT (id) DO NOTHING;

SELECT setval('service_categories_id_seq', (SELECT MAX(id) FROM service_categories));

INSERT INTO services (id, category_id, name, description, unit_price, pricing_unit, is_active, updated_by) VALUES
(1, 1, 'Друк чорно-білий А4', 'Лазерний монохромний друк на папері 80г/м2', 3.00, 'per_page', TRUE, 3),
(2, 1, 'Друк кольоровий А4', 'Високоякісний повнокольоровий струменевий або лазерний друк', 12.00, 'per_page', TRUE, 3),
(3, 1, 'Сканування документів А4', 'Швидкісне оптичне сканування у формат PDF / JPEG', 2.00, 'per_page', TRUE, 3),
(4, 1, 'Ламінування плівкою А4', 'Захисне гаряче ламінування документів', 25.00, 'per_item', TRUE, 3),
(5, 2, 'Оренда ПК-станції в медіатеці', 'Потужний комп''ютер з доступом до швидкісного Інтернету та фахових баз знань', 40.00, 'per_hour', TRUE, 3),
(6, 2, 'Оренда Zoom-кабінки для переговорів', 'Звукоізольована кабінка з освітленням, вебкамерою та гарнітурою', 120.00, 'per_hour', TRUE, 3),
(7, 2, 'Оренда електронної книги Kindle (тиждень)', 'Рідер з підсвічуванням на 7 календарних днів', 80.00, 'per_week', TRUE, 3),
(8, 3, 'Квиток на IT-клуб / Лекцію вихідного дня', 'Вхідний квиток на освітні воркшопи бібліотеки', 150.00, 'per_ticket', TRUE, 3)
ON CONFLICT (id) DO NOTHING;

SELECT setval('services_id_seq', (SELECT MAX(id) FROM services));

INSERT INTO loans (id, reader_profile_id, staff_user_id, loan_date, due_date, status, notes) VALUES
(1, 1, 2, '2026-09-01', '2026-09-21', 'Closed', 'Повернуто вчасно у відмінному стані'),
(2, 3, 2, '2026-09-10', '2026-10-01', 'Active', 'Прострочено повернення DDIA'),
(3, 2, 2, CURRENT_DATE - 5, CURRENT_DATE + 9, 'Active', 'Видано на 14 днів')
ON CONFLICT (id) DO NOTHING;

SELECT setval('loans_id_seq', (SELECT MAX(id) FROM loans));

INSERT INTO loan_items (id, loan_id, book_copy_id, returned_at, condition_on_return) VALUES
(1, 1, 1, '2026-09-20 14:30:00+03', 'Excellent'),
(2, 2, 7, NULL, NULL),
(3, 3, 3, NULL, NULL)
ON CONFLICT (id) DO NOTHING;

SELECT setval('loan_items_id_seq', (SELECT MAX(id) FROM loan_items));

INSERT INTO fines (id, loan_id, reader_profile_id, amount, reason, status, updated_by) VALUES
(1, 2, 3, 30.00, 'Попереднє нарахування за затримку', 'Pending', 2)
ON CONFLICT (id) DO NOTHING;

SELECT setval('fines_id_seq', (SELECT MAX(id) FROM fines));

INSERT INTO service_orders (id, reader_profile_id, staff_user_id, order_date, total_amount, payment_status, payment_method) VALUES
(1, 1, 3, '2026-10-10 11:20:00+03', 60.00, 'Paid', 'Card'),
(2, 2, 3, '2026-10-12 16:45:00+03', 120.00, 'Paid', 'Cash')
ON CONFLICT (id) DO NOTHING;

SELECT setval('service_orders_id_seq', (SELECT MAX(id) FROM service_orders));

INSERT INTO service_order_items (id, order_id, service_id, quantity, unit_price, subtotal) VALUES
(1, 1, 1, 20, 3.00, 60.00),
(2, 2, 6, 1, 120.00, 120.00)
ON CONFLICT (id) DO NOTHING;

SELECT setval('service_order_items_id_seq', (SELECT MAX(id) FROM service_order_items));

INSERT INTO workstation_bookings (id, reader_profile_id, workstation_code, booking_date, start_time, end_time, status) VALUES
(1, 1, 'PC-DESK-04', CURRENT_DATE, '14:00:00', '16:00:00', 'Confirmed'),
(2, 2, 'ZOOM-CABIN-01', CURRENT_DATE, '16:00:00', '17:00:00', 'Confirmed')
ON CONFLICT (id) DO NOTHING;

SELECT setval('workstation_bookings_id_seq', (SELECT MAX(id) FROM workstation_bookings));
