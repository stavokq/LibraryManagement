using LibraryManagement.App.Models;

namespace LibraryManagement.App.Repositories;

public interface ILoanRepository
{
    Task<int> BorrowBooksAsync(int readerProfileId, int staffUserId, int[] copyIds, int loanDays);
    Task<int?> ReturnBookCopyAsync(int loanId, int copyId, string condition, int staffUserId);
    Task<IReadOnlyList<OverdueLoanItem>> GetOverdueLoansAsync();
}
