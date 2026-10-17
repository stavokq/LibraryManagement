namespace LibraryManagement.App;

partial class MainForm
{
    private System.ComponentModel.IContainer components = null;

    private TabControl tabControlMain;
    private TabPage tabCatalog;
    private TabPage tabBorrow;
    private TabPage tabReturns;
    private TabPage tabServices;

    private DataGridView dgvCatalog;
    private Button btnRefreshCatalog;
    private Button btnSoftDeleteBook;

    private NumericUpDown numBorrowReaderId;
    private NumericUpDown numBorrowStaffId;
    private TextBox txtBorrowCopies;
    private NumericUpDown numBorrowDays;
    private Button btnBorrowBooks;
    private RichTextBox rtbBorrowLog;

    private NumericUpDown numReturnLoanId;
    private NumericUpDown numReturnCopyId;
    private ComboBox cmbReturnCondition;
    private NumericUpDown numReturnStaffId;
    private Button btnReturnCopy;
    private DataGridView dgvOverdue;
    private Button btnRefreshOverdue;

    private DataGridView dgvServices;
    private Button btnRefreshServices;
    private NumericUpDown numOrderReaderId;
    private NumericUpDown numOrderStaffId;
    private NumericUpDown numOrderServiceId;
    private NumericUpDown numOrderQuantity;
    private ComboBox cmbOrderPaymentMethod;
    private Button btnCreateServiceOrder;
    private DataGridView dgvSpending;
    private Button btnRefreshSpending;

    private StatusStrip statusStrip;
    private ToolStripStatusLabel statusLabel;

    protected override void Dispose(bool disposing)
    {
        if (disposing && (components != null))
        {
            components.Dispose();
        }
        base.Dispose(disposing);
    }

    private void InitializeComponent()
    {
        this.tabControlMain = new TabControl();
        this.tabCatalog = new TabPage();
        this.tabBorrow = new TabPage();
        this.tabReturns = new TabPage();
        this.tabServices = new TabPage();

        this.statusStrip = new StatusStrip();
        this.statusLabel = new ToolStripStatusLabel();

        this.SuspendLayout();

        this.tabControlMain.Dock = DockStyle.Fill;
        this.tabControlMain.Font = new Font("Segoe UI", 9.5F);
        this.tabControlMain.Controls.Add(this.tabCatalog);
        this.tabControlMain.Controls.Add(this.tabBorrow);
        this.tabControlMain.Controls.Add(this.tabReturns);
        this.tabControlMain.Controls.Add(this.tabServices);

        InitializeCatalogTab();
        InitializeBorrowTab();
        InitializeReturnsTab();
        InitializeServicesTab();

        this.statusStrip.Items.Add(this.statusLabel);
        this.statusLabel.Text = "PostgreSQL 16 localhost:5432/library_db";

        this.ClientSize = new Size(1100, 700);
        this.Controls.Add(this.tabControlMain);
        this.Controls.Add(this.statusStrip);
        this.Name = "MainForm";
        this.StartPosition = FormStartPosition.CenterScreen;
        this.Text = "Система управління бібліотекою з додатковими послугами";
        this.ResumeLayout(false);
        this.PerformLayout();
    }

    private void InitializeCatalogTab()
    {
        this.tabCatalog.Text = "Каталог книг";
        this.tabCatalog.Padding = new Padding(10);

        var topPanel = new Panel { Dock = DockStyle.Top, Height = 55 };
        this.btnRefreshCatalog = new Button { Text = "Оновити каталог", Width = 180, Height = 36, Location = new Point(5, 8) };
        this.btnSoftDeleteBook = new Button { Text = "Списати книгу", Width = 260, Height = 36, Location = new Point(195, 8) };

        this.btnRefreshCatalog.Click += async (s, e) => await LoadCatalogAsync();
        this.btnSoftDeleteBook.Click += async (s, e) => await SoftDeleteSelectedBookAsync();

        topPanel.Controls.Add(this.btnRefreshCatalog);
        topPanel.Controls.Add(this.btnSoftDeleteBook);

        this.dgvCatalog = new DataGridView
        {
            Dock = DockStyle.Fill,
            ReadOnly = true,
            AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
            SelectionMode = DataGridViewSelectionMode.FullRowSelect,
            MultiSelect = false,
            BackgroundColor = Color.White
        };

        this.tabCatalog.Controls.Add(this.dgvCatalog);
        this.tabCatalog.Controls.Add(topPanel);
    }

    private void InitializeBorrowTab()
    {
        this.tabBorrow.Text = "Видача книг";
        this.tabBorrow.Padding = new Padding(15);

        var group = new GroupBox
        {
            Text = "Оформлення видачі через Unit of Work",
            Dock = DockStyle.Top,
            Height = 240,
            Padding = new Padding(15)
        };

        var lblReader = new Label { Text = "ID профілю читача:", Location = new Point(20, 35), AutoSize = true };
        this.numBorrowReaderId = new NumericUpDown { Location = new Point(320, 32), Width = 120, Minimum = 1, Maximum = 10000, Value = 1 };

        var lblStaff = new Label { Text = "ID співробітника:", Location = new Point(20, 75), AutoSize = true };
        this.numBorrowStaffId = new NumericUpDown { Location = new Point(320, 72), Width = 120, Minimum = 1, Maximum = 10000, Value = 2 };

        var lblCopies = new Label { Text = "ID примірників (напр 1, 4):", Location = new Point(20, 115), AutoSize = true };
        this.txtBorrowCopies = new TextBox { Location = new Point(320, 112), Width = 220, Text = "1, 4" };

        var lblDays = new Label { Text = "Термін видачі (днів):", Location = new Point(20, 155), AutoSize = true };
        this.numBorrowDays = new NumericUpDown { Location = new Point(320, 152), Width = 120, Minimum = 1, Maximum = 365, Value = 21 };

        this.btnBorrowBooks = new Button { Text = "Оформити видачу", Location = new Point(320, 190), Width = 280, Height = 36 };
        this.btnBorrowBooks.Click += async (s, e) => await BorrowBooksAsync();

        group.Controls.AddRange(new Control[] {
            lblReader, this.numBorrowReaderId,
            lblStaff, this.numBorrowStaffId,
            lblCopies, this.txtBorrowCopies,
            lblDays, this.numBorrowDays,
            this.btnBorrowBooks
        });

        this.rtbBorrowLog = new RichTextBox
        {
            Dock = DockStyle.Fill,
            ReadOnly = true,
            BackColor = Color.FromArgb(245, 245, 245),
            Font = new Font("Consolas", 10F)
        };

        this.tabBorrow.Controls.Add(this.rtbBorrowLog);
        this.tabBorrow.Controls.Add(group);
    }

    private void InitializeReturnsTab()
    {
        this.tabReturns.Text = "Повернення та штрафи";
        this.tabReturns.Padding = new Padding(10);

        var topGroup = new GroupBox
        {
            Text = "Повернення примірника книги",
            Dock = DockStyle.Top,
            Height = 120,
            Padding = new Padding(10)
        };

        var lblLoan = new Label { Text = "Loan ID:", Location = new Point(15, 30), AutoSize = true };
        this.numReturnLoanId = new NumericUpDown { Location = new Point(80, 27), Width = 80, Minimum = 1, Maximum = 10000, Value = 2 };

        var lblCopy = new Label { Text = "Copy ID:", Location = new Point(180, 30), AutoSize = true };
        this.numReturnCopyId = new NumericUpDown { Location = new Point(245, 27), Width = 80, Minimum = 1, Maximum = 10000, Value = 7 };

        var lblCond = new Label { Text = "Стан:", Location = new Point(345, 30), AutoSize = true };
        this.cmbReturnCondition = new ComboBox { Location = new Point(395, 27), Width = 120, DropDownStyle = ComboBoxStyle.DropDownList };
        this.cmbReturnCondition.Items.AddRange(new object[] { "Good", "Excellent", "Fair", "Damaged" });
        this.cmbReturnCondition.SelectedIndex = 0;

        var lblStaff = new Label { Text = "Staff ID:", Location = new Point(535, 30), AutoSize = true };
        this.numReturnStaffId = new NumericUpDown { Location = new Point(600, 27), Width = 80, Minimum = 1, Maximum = 10000, Value = 2 };

        this.btnReturnCopy = new Button { Text = "Повернути примірник", Location = new Point(80, 68), Width = 350, Height = 36 };
        this.btnReturnCopy.Click += async (s, e) => await ReturnBookAsync();

        topGroup.Controls.AddRange(new Control[] {
            lblLoan, this.numReturnLoanId,
            lblCopy, this.numReturnCopyId,
            lblCond, this.cmbReturnCondition,
            lblStaff, this.numReturnStaffId,
            this.btnReturnCopy
        });

        var bottomGroup = new GroupBox
        {
            Text = "Прострочені видачі",
            Dock = DockStyle.Fill,
            Padding = new Padding(10)
        };

        this.btnRefreshOverdue = new Button { Text = "Оновити список прострочень", Dock = DockStyle.Top, Height = 32 };
        this.btnRefreshOverdue.Click += async (s, e) => await LoadOverdueLoansAsync();

        this.dgvOverdue = new DataGridView
        {
            Dock = DockStyle.Fill,
            ReadOnly = true,
            AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
            BackgroundColor = Color.White
        };

        bottomGroup.Controls.Add(this.dgvOverdue);
        bottomGroup.Controls.Add(this.btnRefreshOverdue);

        this.tabReturns.Controls.Add(bottomGroup);
        this.tabReturns.Controls.Add(topGroup);
    }

    private void InitializeServicesTab()
    {
        this.tabServices.Text = "Додаткові послуги";
        this.tabServices.Padding = new Padding(10);

        var split = new SplitContainer
        {
            Dock = DockStyle.Fill,
            Orientation = Orientation.Vertical,
            SplitterDistance = 550
        };

        var pnlLeft = new Panel { Dock = DockStyle.Fill };
        var lblServicesTitle = new Label { Text = "Каталог послуг", Dock = DockStyle.Top, Height = 25, Font = new Font("Segoe UI", 9.5F, FontStyle.Bold) };
        this.btnRefreshServices = new Button { Text = "Оновити каталог послуг", Dock = DockStyle.Top, Height = 32 };
        this.btnRefreshServices.Click += async (s, e) => await LoadServicesCatalogAsync();

        this.dgvServices = new DataGridView
        {
            Dock = DockStyle.Top,
            Height = 220,
            ReadOnly = true,
            AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
            BackgroundColor = Color.White
        };

        var grpOrder = new GroupBox
        {
            Text = "Оформлення замовлення",
            Dock = DockStyle.Fill,
            Padding = new Padding(10)
        };

        var lblOR = new Label { Text = "Reader ID:", Location = new Point(15, 30), AutoSize = true };
        this.numOrderReaderId = new NumericUpDown { Location = new Point(100, 27), Width = 80, Minimum = 1, Maximum = 10000, Value = 1 };

        var lblOS = new Label { Text = "Staff ID:", Location = new Point(200, 30), AutoSize = true };
        this.numOrderStaffId = new NumericUpDown { Location = new Point(270, 27), Width = 80, Minimum = 1, Maximum = 10000, Value = 3 };

        var lblOSvc = new Label { Text = "Service ID:", Location = new Point(15, 65), AutoSize = true };
        this.numOrderServiceId = new NumericUpDown { Location = new Point(100, 62), Width = 80, Minimum = 1, Maximum = 10000, Value = 1 };

        var lblOQty = new Label { Text = "Кількість:", Location = new Point(200, 65), AutoSize = true };
        this.numOrderQuantity = new NumericUpDown { Location = new Point(270, 62), Width = 80, Minimum = 1, Maximum = 10000, Value = 10 };

        var lblOPay = new Label { Text = "Оплата:", Location = new Point(15, 105), AutoSize = true };
        this.cmbOrderPaymentMethod = new ComboBox { Location = new Point(100, 102), Width = 150, DropDownStyle = ComboBoxStyle.DropDownList };
        this.cmbOrderPaymentMethod.Items.AddRange(new object[] { "Card", "Cash", "Online" });
        this.cmbOrderPaymentMethod.SelectedIndex = 0;

        this.btnCreateServiceOrder = new Button { Text = "Оформити замовлення", Location = new Point(15, 145), Width = 340, Height = 36 };
        this.btnCreateServiceOrder.Click += async (s, e) => await CreateServiceOrderAsync();

        grpOrder.Controls.AddRange(new Control[] {
            lblOR, this.numOrderReaderId,
            lblOS, this.numOrderStaffId,
            lblOSvc, this.numOrderServiceId,
            lblOQty, this.numOrderQuantity,
            lblOPay, this.cmbOrderPaymentMethod,
            this.btnCreateServiceOrder
        });

        pnlLeft.Controls.Add(grpOrder);
        pnlLeft.Controls.Add(this.dgvServices);
        pnlLeft.Controls.Add(this.btnRefreshServices);
        pnlLeft.Controls.Add(lblServicesTitle);

        var pnlRight = new Panel { Dock = DockStyle.Fill };
        var lblSpendingTitle = new Label { Text = "Витрати читачів на послуги", Dock = DockStyle.Top, Height = 25, Font = new Font("Segoe UI", 9.5F, FontStyle.Bold) };
        this.btnRefreshSpending = new Button { Text = "Оновити статистику витрат", Dock = DockStyle.Top, Height = 32 };
        this.btnRefreshSpending.Click += async (s, e) => await LoadSpendingAsync();

        this.dgvSpending = new DataGridView
        {
            Dock = DockStyle.Fill,
            ReadOnly = true,
            AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
            BackgroundColor = Color.White
        };

        pnlRight.Controls.Add(this.dgvSpending);
        pnlRight.Controls.Add(this.btnRefreshSpending);
        pnlRight.Controls.Add(lblSpendingTitle);

        split.Panel1.Controls.Add(pnlLeft);
        split.Panel2.Controls.Add(pnlRight);

        this.tabServices.Controls.Add(split);
    }
}
