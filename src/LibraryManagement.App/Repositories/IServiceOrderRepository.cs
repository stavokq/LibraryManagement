using LibraryManagement.App.Models;

namespace LibraryManagement.App.Repositories;

public interface IServiceOrderRepository
{
    Task<IReadOnlyList<ServiceCatalogItem>> GetActiveServicesAsync();
    Task<int> CreateServiceOrderAsync(int readerProfileId, int staffUserId, int[] serviceIds, int[] quantities, string paymentMethod);
    Task<IReadOnlyList<ReaderServiceSpendingItem>> GetReaderSpendingSummaryAsync();
}
