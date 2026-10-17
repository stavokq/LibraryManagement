using System.Data;
using Dapper;
using LibraryManagement.App.Models;
using Npgsql;
using NpgsqlTypes;

namespace LibraryManagement.App.Repositories;

public class ServiceOrderRepository : IServiceOrderRepository
{
    private readonly NpgsqlConnection _connection;
    private readonly NpgsqlTransaction? _transaction;

    public ServiceOrderRepository(NpgsqlConnection connection, NpgsqlTransaction? transaction)
    {
        _connection = connection;
        _transaction = transaction;
    }

    public async Task<IReadOnlyList<ServiceCatalogItem>> GetActiveServicesAsync()
    {
        const string sql = "SELECT * FROM vw_active_services_catalog ORDER BY service_id;";
        var results = await _connection.QueryAsync<ServiceCatalogItem>(sql, transaction: _transaction);
        return results.AsList();
    }

    public async Task<int> CreateServiceOrderAsync(int readerProfileId, int staffUserId, int[] serviceIds, int[] quantities, string paymentMethod)
    {
        await using var cmd = new NpgsqlCommand("CALL sp_create_service_order(@p_reader_profile_id, @p_staff_user_id, @p_service_ids, @p_quantities, @p_payment_method, @p_order_id);", _connection, _transaction);

        cmd.Parameters.AddWithValue("p_reader_profile_id", readerProfileId);
        cmd.Parameters.AddWithValue("p_staff_user_id", staffUserId);
        cmd.Parameters.AddWithValue("p_service_ids", serviceIds);
        cmd.Parameters.AddWithValue("p_quantities", quantities);
        cmd.Parameters.AddWithValue("p_payment_method", paymentMethod);

        var orderParam = new NpgsqlParameter("p_order_id", NpgsqlDbType.Integer)
        {
            Direction = ParameterDirection.InputOutput,
            Value = DBNull.Value
        };
        cmd.Parameters.Add(orderParam);

        await cmd.ExecuteNonQueryAsync();

        if (orderParam.Value is int orderId)
            return orderId;

        throw new InvalidOperationException("Процедура не повернула ID створеного замовлення послуги.");
    }

    public async Task<IReadOnlyList<ReaderServiceSpendingItem>> GetReaderSpendingSummaryAsync()
    {
        const string sql = "SELECT * FROM vw_reader_service_spending ORDER BY total_spent_uah DESC;";
        var results = await _connection.QueryAsync<ReaderServiceSpendingItem>(sql, transaction: _transaction);
        return results.AsList();
    }
}
