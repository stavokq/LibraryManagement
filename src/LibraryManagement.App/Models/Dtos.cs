namespace LibraryManagement.App.Models;

public record BookCatalogItem(
    int book_id,
    string isbn,
    string title,
    int publication_year,
    string genre_name,
    string publisher_name,
    string authors_list,
    long total_copies,
    long available_copies,
    DateTime updated_at,
    int? updated_by
);

public record OverdueLoanItem(
    int loan_id,
    int reader_profile_id,
    string library_card_number,
    string reader_name,
    string reader_phone,
    string reader_email,
    DateOnly loan_date,
    DateOnly due_date,
    int overdue_days,
    long unreturned_items_count,
    decimal estimated_fine_amount
);

public record ReaderServiceSpendingItem(
    int reader_profile_id,
    string library_card_number,
    string reader_name,
    long total_orders,
    decimal total_spent_uah,
    long total_print_pages,
    long total_workspace_hours
);

public record ServiceCatalogItem(
    int service_id,
    string category_name,
    string service_name,
    string? description,
    decimal unit_price,
    string pricing_unit,
    DateTime updated_at
);
