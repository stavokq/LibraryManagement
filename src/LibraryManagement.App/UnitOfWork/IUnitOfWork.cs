using LibraryManagement.App.Repositories;

namespace LibraryManagement.App.UnitOfWork;

public interface IUnitOfWork : IAsyncDisposable
{
    IBookRepository Books { get; }
    ILoanRepository Loans { get; }
    IServiceOrderRepository Services { get; }

    Task BeginTransactionAsync();
    Task CommitAsync();
    Task RollbackAsync();
}
