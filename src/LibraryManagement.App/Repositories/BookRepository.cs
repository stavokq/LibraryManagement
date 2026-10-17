using Dapper;
using LibraryManagement.App.Models;
using Npgsql;

namespace LibraryManagement.App.Repositories;

public class BookRepository : IBookRepository
{
    private readonly NpgsqlConnection _connection;
    private readonly NpgsqlTransaction? _transaction;

    public BookRepository(NpgsqlConnection connection, NpgsqlTransaction? transaction)
    {
        _connection = connection;
        _transaction = transaction;
    }

    public async Task<IReadOnlyList<BookCatalogItem>> GetActiveCatalogAsync()
    {
        const string sql = "SELECT * FROM vw_active_books_catalog ORDER BY book_id;";
        var results = await _connection.QueryAsync<BookCatalogItem>(sql, transaction: _transaction);
        return results.AsList();
    }

    public async Task SoftDeleteBookAsync(int bookId, int staffUserId)
    {
        const string sql = "CALL sp_soft_delete_book(@p_book_id, @p_user_id);";
        await _connection.ExecuteAsync(sql, new { p_book_id = bookId, p_user_id = staffUserId }, _transaction);
    }
}
