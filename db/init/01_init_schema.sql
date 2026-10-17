DROP TABLE IF EXISTS workstation_bookings CASCADE;
DROP TABLE IF EXISTS service_order_items CASCADE;
DROP TABLE IF EXISTS service_orders CASCADE;
DROP TABLE IF EXISTS services CASCADE;
DROP TABLE IF EXISTS service_categories CASCADE;
DROP TABLE IF EXISTS fines CASCADE;
DROP TABLE IF EXISTS loan_items CASCADE;
DROP TABLE IF EXISTS loans CASCADE;
DROP TABLE IF EXISTS book_copies CASCADE;
DROP TABLE IF EXISTS book_authors CASCADE;
DROP TABLE IF EXISTS books CASCADE;
DROP TABLE IF EXISTS authors CASCADE;
DROP TABLE IF EXISTS genres CASCADE;
DROP TABLE IF EXISTS publishers CASCADE;
DROP TABLE IF EXISTS reader_profiles CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS roles CASCADE;

CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description TEXT
);

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    role_id INT NOT NULL REFERENCES roles(id),
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(150) NOT NULL,
    phone VARCHAR(30),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at TIMESTAMP WITH TIME ZONE NULL
);

CREATE TABLE reader_profiles (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL UNIQUE REFERENCES users(id),
    library_card_number VARCHAR(50) NOT NULL UNIQUE,
    address VARCHAR(255),
    date_of_birth DATE,
    total_fines_due NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    updated_by INT NULL REFERENCES users(id)
);

CREATE TABLE publishers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(150) NOT NULL UNIQUE,
    address VARCHAR(255),
    phone VARCHAR(50),
    website VARCHAR(150),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT clock_timestamp()
);

CREATE TABLE genres (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE authors (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    country VARCHAR(100),
    bio TEXT
);

CREATE TABLE books (
    id SERIAL PRIMARY KEY,
    isbn VARCHAR(20) NOT NULL UNIQUE,
    title VARCHAR(255) NOT NULL,
    publication_year INT CHECK (publication_year >= 1400 AND publication_year <= EXTRACT(YEAR FROM CURRENT_DATE) + 1),
    publisher_id INT NOT NULL REFERENCES publishers(id),
    genre_id INT NOT NULL REFERENCES genres(id),
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    updated_by INT NULL REFERENCES users(id),
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at TIMESTAMP WITH TIME ZONE NULL
);

CREATE TABLE book_authors (
    book_id INT NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    author_id INT NOT NULL REFERENCES authors(id),
    author_role VARCHAR(50) NOT NULL DEFAULT 'Primary Author',
    PRIMARY KEY (book_id, author_id)
);

CREATE TABLE book_copies (
    id SERIAL PRIMARY KEY,
    book_id INT NOT NULL REFERENCES books(id),
    inventory_number VARCHAR(50) NOT NULL UNIQUE,
    location_shelf VARCHAR(50) NOT NULL,
    condition VARCHAR(50) NOT NULL DEFAULT 'Good',
    status VARCHAR(30) NOT NULL DEFAULT 'Available' 
        CHECK (status IN ('Available', 'Borrowed', 'Damaged', 'Lost', 'Under_Maintenance')),
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at TIMESTAMP WITH TIME ZONE NULL
);

CREATE TABLE loans (
    id SERIAL PRIMARY KEY,
    reader_profile_id INT NOT NULL REFERENCES reader_profiles(id),
    staff_user_id INT NOT NULL REFERENCES users(id),
    loan_date DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date DATE NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'Active' 
        CHECK (status IN ('Active', 'Closed', 'Overdue')),
    notes TEXT
);

CREATE TABLE loan_items (
    id SERIAL PRIMARY KEY,
    loan_id INT NOT NULL REFERENCES loans(id) ON DELETE CASCADE,
    book_copy_id INT NOT NULL REFERENCES book_copies(id),
    returned_at TIMESTAMP WITH TIME ZONE NULL,
    condition_on_return VARCHAR(50) NULL
);

CREATE TABLE fines (
    id SERIAL PRIMARY KEY,
    loan_id INT NULL REFERENCES loans(id),
    reader_profile_id INT NOT NULL REFERENCES reader_profiles(id),
    amount NUMERIC(10,2) NOT NULL CHECK (amount >= 0),
    reason VARCHAR(100) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'Pending' 
        CHECK (status IN ('Pending', 'Paid', 'Waived')),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    updated_by INT NULL REFERENCES users(id)
);

CREATE TABLE service_categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE services (
    id SERIAL PRIMARY KEY,
    category_id INT NOT NULL REFERENCES service_categories(id),
    name VARCHAR(150) NOT NULL,
    description TEXT,
    unit_price NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),
    pricing_unit VARCHAR(30) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    updated_by INT NULL REFERENCES users(id),
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at TIMESTAMP WITH TIME ZONE NULL
);

CREATE TABLE service_orders (
    id SERIAL PRIMARY KEY,
    reader_profile_id INT NOT NULL REFERENCES reader_profiles(id),
    staff_user_id INT NOT NULL REFERENCES users(id),
    order_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    total_amount NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    payment_status VARCHAR(30) NOT NULL DEFAULT 'Paid' 
        CHECK (payment_status IN ('Pending', 'Paid', 'Cancelled')),
    payment_method VARCHAR(30) NOT NULL DEFAULT 'Cash' 
        CHECK (payment_method IN ('Cash', 'Card', 'Online', 'Reader_Deposit'))
);

CREATE TABLE service_order_items (
    id SERIAL PRIMARY KEY,
    order_id INT NOT NULL REFERENCES service_orders(id) ON DELETE CASCADE,
    service_id INT NOT NULL REFERENCES services(id),
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0),
    subtotal NUMERIC(10,2) NOT NULL CHECK (subtotal >= 0)
);

CREATE TABLE workstation_bookings (
    id SERIAL PRIMARY KEY,
    reader_profile_id INT NOT NULL REFERENCES reader_profiles(id),
    workstation_code VARCHAR(50) NOT NULL,
    booking_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'Confirmed' 
        CHECK (status IN ('Confirmed', 'Completed', 'Cancelled'))
);
