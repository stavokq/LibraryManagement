using LibraryManagement.App.Repositories;
using Npgsql;

namespace LibraryManagement.App.UnitOfWork;

public class UnitOfWork : IUnitOfWork
{
    private readonly NpgsqlConnection _connection;
    private NpgsqlTransaction? _transaction;
    private bool _disposed;

    private IBookRepository? _books;
    private ILoanRepository? _loans;
    private IServiceOrderRepository? _services;

    public UnitOfWork(string connectionString)
    {
        _connection = new NpgsqlConnection(connectionString);
    }

    private async Task EnsureConnectionOpenAsync()
    {
        if (_connection.State != System.Data.ConnectionState.Open)
        {
            await _connection.OpenAsync();
        }
    }

    public async Task BeginTransactionAsync()
    {
        await EnsureConnectionOpenAsync();
        if (_transaction != null)
            throw new InvalidOperationException("Транзакція вже відкрита в цьому Unit of Work.");

        _transaction = await _connection.BeginTransactionAsync();
        ResetRepositories();
    }

    public async Task CommitAsync()
    {
        if (_transaction == null)
            throw new InvalidOperationException("Немає активної транзакції для фіксації (Commit).");

        try
        {
            await _transaction.CommitAsync();
        }
        finally
        {
            await _transaction.DisposeAsync();
            _transaction = null;
            ResetRepositories();
        }
    }

    public async Task RollbackAsync()
    {
        if (_transaction == null)
            return;

        try
        {
            await _transaction.RollbackAsync();
        }
        finally
        {
            await _transaction.DisposeAsync();
            _transaction = null;
            ResetRepositories();
        }
    }

    private void ResetRepositories()
    {
        _books = null;
        _loans = null;
        _services = null;
    }

    public IBookRepository Books
    {
        get
        {
            EnsureOpenSync();
            return _books ??= new BookRepository(_connection, _transaction);
        }
    }

    public ILoanRepository Loans
    {
        get
        {
            EnsureOpenSync();
            return _loans ??= new LoanRepository(_connection, _transaction);
        }
    }

    public IServiceOrderRepository Services
    {
        get
        {
            EnsureOpenSync();
            return _services ??= new ServiceOrderRepository(_connection, _transaction);
        }
    }

    private void EnsureOpenSync()
    {
        if (_connection.State != System.Data.ConnectionState.Open)
        {
            _connection.Open();
        }
    }

    public async ValueTask DisposeAsync()
    {
        if (_disposed)
            return;

        if (_transaction != null)
        {
            try
            {
                await _transaction.RollbackAsync();
            }
            catch
            {
            }
            await _transaction.DisposeAsync();
            _transaction = null;
        }

        await _connection.DisposeAsync();
        _disposed = true;
        GC.SuppressFinalize(this);
    }
}
