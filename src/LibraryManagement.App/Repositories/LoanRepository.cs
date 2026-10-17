using System.Data;
using Dapper;
using LibraryManagement.App.Models;
using Npgsql;
using NpgsqlTypes;

namespace LibraryManagement.App.Repositories;

public class LoanRepository : ILoanRepository
{
    private readonly NpgsqlConnection _connection;
    private readonly NpgsqlTransaction? _transaction;

    public LoanRepository(NpgsqlConnection connection, NpgsqlTransaction? transaction)
    {
        _connection = connection;
        _transaction = transaction;
    }

    public async Task<int> BorrowBooksAsync(int readerProfileId, int staffUserId, int[] copyIds, int loanDays)
    {
        await using var cmd = new NpgsqlCommand("CALL sp_borrow_books(@p_reader_profile_id, @p_staff_user_id, @p_copy_ids, @p_loan_days, @p_loan_id);", _connection, _transaction);
        
        cmd.Parameters.AddWithValue("p_reader_profile_id", readerProfileId);
        cmd.Parameters.AddWithValue("p_staff_user_id", staffUserId);
        cmd.Parameters.AddWithValue("p_copy_ids", copyIds);
        cmd.Parameters.AddWithValue("p_loan_days", loanDays);

        var outParam = new NpgsqlParameter("p_loan_id", NpgsqlDbType.Integer)
        {
            Direction = ParameterDirection.InputOutput,
            Value = DBNull.Value
        };
        cmd.Parameters.Add(outParam);

        await cmd.ExecuteNonQueryAsync();

        if (outParam.Value is int loanId)
            return loanId;

        throw new InvalidOperationException("Процедура не повернула ID створеної позики.");
    }

    public async Task<int?> ReturnBookCopyAsync(int loanId, int copyId, string condition, int staffUserId)
    {
        await using var cmd = new NpgsqlCommand("CALL sp_return_book_copy(@p_loan_id, @p_copy_id, @p_condition, @p_staff_user_id, @p_fine_id);", _connection, _transaction);

        cmd.Parameters.AddWithValue("p_loan_id", loanId);
        cmd.Parameters.AddWithValue("p_copy_id", copyId);
        cmd.Parameters.AddWithValue("p_condition", condition);
        cmd.Parameters.AddWithValue("p_staff_user_id", staffUserId);

        var fineParam = new NpgsqlParameter("p_fine_id", NpgsqlDbType.Integer)
        {
            Direction = ParameterDirection.InputOutput,
            Value = DBNull.Value
        };
        cmd.Parameters.Add(fineParam);

        await cmd.ExecuteNonQueryAsync();

        return fineParam.Value is int fineId ? fineId : null;
    }

    public async Task<IReadOnlyList<OverdueLoanItem>> GetOverdueLoansAsync()
    {
        const string sql = "SELECT * FROM vw_overdue_loans ORDER BY overdue_days DESC;";
        var results = await _connection.QueryAsync<OverdueLoanItem>(sql, transaction: _transaction);
        return results.AsList();
    }
}
