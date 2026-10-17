using LibraryManagement.App.Models;

namespace LibraryManagement.App.Repositories;

public interface IBookRepository
{
    Task<IReadOnlyList<BookCatalogItem>> GetActiveCatalogAsync();
    Task SoftDeleteBookAsync(int bookId, int staffUserId);
}
