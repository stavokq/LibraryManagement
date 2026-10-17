using LibraryManagement.App.UnitOfWork;

namespace LibraryManagement.App;

public partial class MainForm : Form
{
    private const string ConnectionString = "Host=localhost;Port=5432;Database=library_db;Username=postgres;Password=postgres";

    public MainForm()
    {
        InitializeComponent();
        this.Load += async (s, e) => await InitializeDataAsync();
    }

    private async Task InitializeDataAsync()
    {
        await LoadCatalogAsync();
        await LoadOverdueLoansAsync();
        await LoadServicesCatalogAsync();
        await LoadSpendingAsync();
    }

    private async Task LoadCatalogAsync()
    {
        try
        {
            await using var uow = new UnitOfWork.UnitOfWork(ConnectionString);
            var books = await uow.Books.GetActiveCatalogAsync();
            dgvCatalog.DataSource = books;
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Помилка завантаження каталогу: {ex.Message}", "Помилка", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }

    private async Task SoftDeleteSelectedBookAsync()
    {
        if (dgvCatalog.CurrentRow?.DataBoundItem is not Models.BookCatalogItem selectedBook)
        {
            MessageBox.Show("Будь ласка, оберіть книгу у таблиці для списання.", "Увага", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return;
        }

        var confirm = MessageBox.Show(
            $"Ви дійсно бажаєте списати книгу:\n\"{selectedBook.title}\" (ID: {selectedBook.book_id})?\n\nЗапис залишиться в БД для історії, але зникне з активного каталогу.",
            "Підтвердження списання",
            MessageBoxButtons.YesNo,
            MessageBoxIcon.Question);

        if (confirm != DialogResult.Yes)
            return;

        try
        {
            await using var uow = new UnitOfWork.UnitOfWork(ConnectionString);
            await uow.Books.SoftDeleteBookAsync(selectedBook.book_id, staffUserId: 2);
            MessageBox.Show("Книгу успішно списано", "Успіх", MessageBoxButtons.OK, MessageBoxIcon.Information);
            await LoadCatalogAsync();
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Неможливо списати книгу: {ex.Message}", "Помилка", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }

    private async Task BorrowBooksAsync()
    {
        try
        {
            int readerId = (int)numBorrowReaderId.Value;
            int staffId = (int)numBorrowStaffId.Value;
            int days = (int)numBorrowDays.Value;

            var copyIdStrings = txtBorrowCopies.Text.Split(new[] { ',', ' ' }, StringSplitOptions.RemoveEmptyEntries);
            var copyIds = copyIdStrings.Select(int.Parse).ToArray();

            if (copyIds.Length == 0)
            {
                MessageBox.Show("Вкажіть хоча б один ID примірника.", "Увага", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            await using var uow = new UnitOfWork.UnitOfWork(ConnectionString);
            await uow.BeginTransactionAsync();
            try
            {
                int loanId = await uow.Loans.BorrowBooksAsync(readerId, staffId, copyIds, days);
                await uow.CommitAsync();

                rtbBorrowLog.AppendText($"[{DateTime.Now:HH:mm:ss}] Успішно створено видачу Loan ID: {loanId} для читача #{readerId}. Примірники: #{string.Join(", #", copyIds)}\n");
                MessageBox.Show($"Видачу успішно оформлено! Loan ID: {loanId}", "Успіх", MessageBoxButtons.OK, MessageBoxIcon.Information);

                await LoadCatalogAsync();
            }
            catch (Exception ex)
            {
                await uow.RollbackAsync();
                rtbBorrowLog.AppendText($"[{DateTime.Now:HH:mm:ss}] ПОМИЛКА: {ex.Message}\n");
                MessageBox.Show($"Помилка видачі: {ex.Message}", "Помилка", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Некоректні вхідні дані: {ex.Message}", "Помилка", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }

    private async Task LoadOverdueLoansAsync()
    {
        try
        {
            await using var uow = new UnitOfWork.UnitOfWork(ConnectionString);
            var overdue = await uow.Loans.GetOverdueLoansAsync();
            dgvOverdue.DataSource = overdue;
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Помилка завантаження прострочень: {ex.Message}", "Помилка", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }

    private async Task ReturnBookAsync()
    {
        try
        {
            int loanId = (int)numReturnLoanId.Value;
            int copyId = (int)numReturnCopyId.Value;
            string condition = cmbReturnCondition.SelectedItem?.ToString() ?? "Good";
            int staffId = (int)numReturnStaffId.Value;

            await using var uow = new UnitOfWork.UnitOfWork(ConnectionString);
            int? fineId = await uow.Loans.ReturnBookCopyAsync(loanId, copyId, condition, staffId);

            if (fineId.HasValue)
            {
                MessageBox.Show(
                    $"Примірник #{copyId} повернуто\n\nВиявлено прострочення Процедура автоматично згенерувала штраф Fine ID: {fineId.Value} (fn_calculate_overdue_fine) та оновила аудит.",
                    "Повернення зі штрафом",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Warning);
            }
            else
            {
                MessageBox.Show($"Примірник #{copyId} успішно повернено без штрафів.", "Успіх", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }

            await LoadOverdueLoansAsync();
            await LoadCatalogAsync();
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Помилка повернення: {ex.Message}", "Помилка", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }

    private async Task LoadServicesCatalogAsync()
    {
        try
        {
            await using var uow = new UnitOfWork.UnitOfWork(ConnectionString);
            var services = await uow.Services.GetActiveServicesAsync();
            dgvServices.DataSource = services;
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Помилка завантаження послуг: {ex.Message}", "Помилка", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }

    private async Task LoadSpendingAsync()
    {
        try
        {
            await using var uow = new UnitOfWork.UnitOfWork(ConnectionString);
            var spending = await uow.Services.GetReaderSpendingSummaryAsync();
            dgvSpending.DataSource = spending;
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Помилка завантаження статистики: {ex.Message}", "Помилка", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }

    private async Task CreateServiceOrderAsync()
    {
        try
        {
            int readerId = (int)numOrderReaderId.Value;
            int staffId = (int)numOrderStaffId.Value;
            int serviceId = (int)numOrderServiceId.Value;
            int qty = (int)numOrderQuantity.Value;
            string payment = cmbOrderPaymentMethod.SelectedItem?.ToString() ?? "Card";

            await using var uow = new UnitOfWork.UnitOfWork(ConnectionString);
            int orderId = await uow.Services.CreateServiceOrderAsync(readerId, staffId, new[] { serviceId }, new[] { qty }, payment);

            MessageBox.Show($"Замовлення успішно оформлено Номер чека Order ID: {orderId}", "Успіх", MessageBoxButtons.OK, MessageBoxIcon.Information);

            await LoadSpendingAsync();
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Помилка оформлення замовлення: {ex.Message}", "Помилка", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }
}
