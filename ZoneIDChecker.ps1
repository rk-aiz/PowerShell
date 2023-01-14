<#
ZoneIDChecker.ps1
    - ZoneIDを手軽に確認・削除するためのスクリプト

    起動オプション
    -ShowConsole コンソール表示 (デバッグ用)
    -UserDebug デバッグメッセージ表示
#>
using namespace System.Windows
using namespace System.Windows.Media.Imaging
using namespace System.Text

Param(
    [Parameter()]
    [switch] $ShowConsole,
    [Parameter()]
    [switch] $UserDebug
)

if ($ShowConsole -eq $false)
{
    #自身のps1をウィンドウ無しで再実行する
    $strAlwaysOnTop = $(if ($AlwaysOnTop) {'-AlwaysOnTop '} else {''})
    $StartInfo = New-Object Diagnostics.ProcessStartInfo
    $StartInfo.UseShellExecute = $false
    $StartInfo.CreateNoWindow = $true
    $StartInfo.FileName = "powershell.exe"
    $StartInfo.Arguments = '-NoProfile -NonInteractive -ExecutionPolicy Unrestricted -File "{0}" -ShowConsole {1}' -f $MyInvocation.MyCommand.Path, $strAlwaysOnTop
    $Process = New-Object Diagnostics.Process
    $Process.StartInfo = $StartInfo
    $null = $Process.Start()
    return
}

#============================================================================ #
#region WPF
Try {
    [void][MainWindow]
} Catch {
Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Drawing;
using System.Windows;
using System.Windows.Input;
using System.Windows.Data;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Interop;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Threading;
using System.ComponentModel;
using System.Collections.ObjectModel;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;
using System.Configuration;
using System.Diagnostics;
using System.Threading;
using System.Collections.Specialized ;

using System.Threading.Tasks;

#region Paint
public class Paint
{
    public static Color BackgroundColor = new Color{A =255, R = 40, G = 40, B = 40};
    public static Brush BackgroundBrush = new SolidColorBrush(BackgroundColor);

    public static Brush ForegroundBrush = new SolidColorBrush(Colors.WhiteSmoke);

    public static Brush BlueBrush = new SolidColorBrush(Colors.Aqua);
    public static Brush GrayBrush = new SolidColorBrush(Colors.Gray);

    public static Color GrayBorderColor = new Color{A =255, R =65, G = 65, B =65};
    public static Brush GrayBorderBrush = new SolidColorBrush(GrayBorderColor);

    public static Color TextBoxBackgroundColor = new Color{A =255, R = 30, G = 30, B = 30};
    public static Brush TextBoxBackgroundBrush = new SolidColorBrush(TextBoxBackgroundColor);

    public static Color TextBoxBorderColor = new Color{A =255, R = 80, G = 80, B = 80};
    public static Brush TextBoxBorderBrush = new SolidColorBrush(TextBoxBorderColor);

    public static Color ScrollBarBackgroundColor = new Color{A =255, R =40, G = 40, B =40};
    public static Brush ScrollBarBackgroundBrush = new SolidColorBrush(ScrollBarBackgroundColor);

    public static Color MouseOverBackgroundColor = new Color {A = 255, R = 70, G = 70, B = 70};
    public static Brush MouseOverBackgroundBrush = new SolidColorBrush(MouseOverBackgroundColor);

    public static Color ButtonBackgroundColor = new Color {A = 255, R = 55, G = 55, B = 55};
    public static Brush ButtonBackgroundBrush = new SolidColorBrush(ButtonBackgroundColor);

    public static Color ButtonMouseOverBackgroundColor = new Color {A = 255, R = 85, G = 85, B = 85};
    public static Brush ButtonMouseOverBackgroundBrush = new SolidColorBrush(ButtonMouseOverBackgroundColor);

    public static Color ProgressedColor = new Color {A = 255, R = 25, G = 120, B = 235};
    public static Brush ProgressedBrush = new SolidColorBrush(ProgressedColor);

    public static Color ProgressedMouseOverColor = new Color {A = 255, R = 35, G = 145, B = 255};
    public static Brush ProgressedMouseOverBrush = new SolidColorBrush(ProgressedMouseOverColor);

    public static FontFamily IconFontFamily = new FontFamily("Segoe MDL2 Assets");
    public static FontFamily textFontFamily = new FontFamily("Meiryo");
}
#endregion

#region MainWindow
public class MainWindow : System.Windows.Window
{
    public MainWindow()
    {
        InitializeComponent();
    }

    private void InitializeComponent()
    {
        this.Width = 960.0;
        this.Height = 720.0;
        this.ShowActivated = true;
        this.WindowStartupLocation = WindowStartupLocation.CenterScreen;
        //this.SizeToContent = SizeToContent.WidthAndHeight;
        this.Topmost = true;
        this.Background = Paint.BackgroundBrush;
        this.Loaded += (sender, e) => {this.Topmost = false;};
        this.Resources = new CustomResourceDictionary();

        this.Content = new MainGrid();
    }

    public void SetCurrentDirectory(string strCurrentDirectory)
    {
        Data.CurrentDirectory = new DirectoryInfo(strCurrentDirectory);
    }

    ~MainWindow()
    {
        if (true == this.IsVisible)
            Close();
    }
}
#endregion

#region MainGrid
class MainGrid : Grid
{

    public MainGrid()
    {
        this.RowDefinitions.Add(new RowDefinition{Height = new GridLength(60.0), MinHeight = 20.0});
        this.RowDefinitions.Add(new RowDefinition{MinHeight = 20.0});
        this.RowDefinitions.Add(new RowDefinition{Height = new GridLength(25.0)});

        this.Children.Add(new NavigatePanel());
        this.Children.Add(new FilerPanel());
        this.Children.Add(new CustomStatusBar());
    }
}
#endregion MainGrid

#region NavigatePanel
class NavigatePanel : TextBox, INotifyPropertyChanged
{
    public string _strCurrentDirectory;
    public string StrCurrentDirectory
    {
        get
        {
            try {
                _strCurrentDirectory = Data.CurrentDirectory.FullName;
            } catch {
                _strCurrentDirectory = String.Empty;
            }
            return _strCurrentDirectory;
        }
        set { _strCurrentDirectory = value; OnCurrentDirectoryChanging(); }
    }

    public event PropertyChangedEventHandler PropertyChanged = (sender, e) => { };

    private void OnCurrentDirectoryChanging()
    {
        if (Directory.Exists(this._strCurrentDirectory)) {
            Data.CurrentDirectory = new DirectoryInfo(this._strCurrentDirectory);
        }
    }

    public NavigatePanel()
    {
        Grid.SetRow(this, 0);
        var binding = new Binding("StrCurrentDirectory"){
            Source = this,
            Mode = BindingMode.TwoWay,
            UpdateSourceTrigger = UpdateSourceTrigger.LostFocus,
        };
        SetBinding(TextBox.TextProperty, binding);
        Data.CurrentDirectoryChanged += new PropertyChangedEventHandler(Data_CurrentDirectoryChanged);
        this.Template = CreateTextBoxTemplate();
        this.Margin = new Thickness{Left = 5.0, Right = 15.0};
        this.CaretBrush = Paint.ForegroundBrush;
        this.Foreground = Paint.ForegroundBrush;
        this.FontSize = 16.0;

        this.KeyDown += new KeyEventHandler(TextBox_KeyDown);
    }

    private void Data_CurrentDirectoryChanged(object sender, PropertyChangedEventArgs e)
    {
        PropertyChanged.Invoke(this, new PropertyChangedEventArgs("StrCurrentDirectory"));
    }

    private ControlTemplate CreateTextBoxTemplate()
    {
        var scrollViewer = new FrameworkElementFactory(typeof(ScrollViewer), "PART_ContentHost");
        scrollViewer.SetValue(ScrollViewer.VerticalAlignmentProperty, VerticalAlignment.Center);
        scrollViewer.SetValue(ScrollViewer.VerticalContentAlignmentProperty, VerticalAlignment.Center);
        scrollViewer.SetValue(ScrollViewer.MarginProperty, new Thickness{Left = 15.0, Right = 5.0, Top = 0.0, Bottom = 0.0});
        scrollViewer.SetValue(DockPanel.DockProperty, Dock.Left);

        var reloadButton = new FrameworkElementFactory(typeof(TileButton));
        reloadButton.SetValue(TileButton.ContentProperty, "\uE149");
        reloadButton.SetValue(Button.MarginProperty, new Thickness{Left = 0.0, Right = 0.0});
        reloadButton.SetValue(DockPanel.DockProperty, Dock.Right);

        var inlinePanel = new FrameworkElementFactory(typeof(DockPanel));
        //inlinePanel.SetValue(DockPanel.BackgroundProperty, Paint.BlueBrush);
        inlinePanel.AppendChild(reloadButton);
        inlinePanel.AppendChild(scrollViewer);

        var border = new FrameworkElementFactory(typeof(Border));
        border.SetValue(Border.BorderThicknessProperty, new Thickness(1.0));
        border.SetValue(Border.BorderBrushProperty, Paint.TextBoxBorderBrush);
        border.SetValue(Border.HeightProperty, 35.0);
        border.SetValue(Border.CornerRadiusProperty, new CornerRadius(17.5));
        border.AppendChild(inlinePanel);

        var leftArrowButton = new FrameworkElementFactory(typeof(TileButton));
        leftArrowButton.SetValue(TileButton.ContentProperty, "\uE0A6");
        leftArrowButton.SetValue(Button.MarginProperty, new Thickness{Left = 10.0, Right = 5.0});
        leftArrowButton.AddHandler(ButtonBase.ClickEvent, new RoutedEventHandler(LeftArrowButton_Click));

        var rightArrowButton = new FrameworkElementFactory(typeof(TileButton));
        rightArrowButton.SetValue(TileButton.ContentProperty, "\uE0AB");
        rightArrowButton.SetValue(Button.MarginProperty, new Thickness{Left = 5.0, Right = 5.0});
        rightArrowButton.AddHandler(ButtonBase.ClickEvent, new RoutedEventHandler(RightArrowButton_Click));

        var upArrowButton = new FrameworkElementFactory(typeof(TileButton));
        upArrowButton.SetValue(TileButton.ContentProperty, "\uE110");
        upArrowButton.SetValue(Button.MarginProperty, new Thickness{Left = 5.0, Right = 10.0});
        upArrowButton.AddHandler(ButtonBase.ClickEvent, new RoutedEventHandler(UpArrowButton_Click));

        var stackPanel = new FrameworkElementFactory(typeof(StackPanel));
        
        stackPanel.SetValue(StackPanel.OrientationProperty, Orientation.Horizontal);
        stackPanel.SetValue(DockPanel.DockProperty, Dock.Left);
        stackPanel.AppendChild(leftArrowButton);
        stackPanel.AppendChild(rightArrowButton);
        stackPanel.AppendChild(upArrowButton);

        var dockPanel = new FrameworkElementFactory(typeof(DockPanel));

        dockPanel.AppendChild(stackPanel);
        dockPanel.AppendChild(border);

        var ct = new ControlTemplate(typeof(TextBox)){
            VisualTree = dockPanel,
        };
        return ct;
    }

    private void LeftArrowButton_Click(object sender, RoutedEventArgs e)
    {
        try {
            Data.PrevDirectory();
        } catch { }
    }

    private void RightArrowButton_Click(object sender, RoutedEventArgs e)
    {
        try {
            Data.NextDirectory();
        } catch { }
    }

    private void UpArrowButton_Click(object sender, RoutedEventArgs e)
    {
        try {
            Data.CurrentDirectory = Data.CurrentDirectory.Parent;
        } catch { }
    }

    private void TextBox_KeyDown(object sender, KeyEventArgs e)
    {
        if (e.Key != Key.Enter)
        {
            return;
        }

        try {
            var be = BindingOperations.GetBindingExpression((NavigatePanel)sender, TextBox.TextProperty);
            be.UpdateSource();
            Keyboard.ClearFocus();
        } catch { }
    }
}
#endregion NavigatePanel

#region TileButton
class TileButton : System.Windows.Controls.Primitives.ButtonBase, INotifyPropertyChanged
{
    public Brush _backgroundBrush;
    public Brush BackgroundBrush
    {
        get { return this._backgroundBrush; }
        set { this._backgroundBrush = value; OnPropertyChanged("BackgroundBrush"); }
    }
    public TileButton()
    {
        this.Template = CreateTileButtonTemplate();
        this.VerticalAlignment = VerticalAlignment.Center;
        this.Foreground = Paint.ForegroundBrush;
        this.FontFamily = Paint.IconFontFamily;
        this.FontWeight = FontWeights.Medium;
        this.FontSize = 15.0;
        this.MouseEnter += new MouseEventHandler(TileButton_MouseEnter);
        this.MouseLeave += new MouseEventHandler(TileButton_MouseLeave);
    }

    private ControlTemplate CreateTileButtonTemplate()
    {
        var contentPresenter = new FrameworkElementFactory(typeof(ContentPresenter));
        contentPresenter.SetValue(ContentPresenter.VerticalAlignmentProperty, VerticalAlignment.Center);
        contentPresenter.SetValue(ContentPresenter.HorizontalAlignmentProperty, HorizontalAlignment.Center);

        var border = new FrameworkElementFactory(typeof(Border));
        var binding = new Binding("BackgroundBrush"){
            Source = this,
        };
        border.SetBinding(Border.BackgroundProperty, binding);
        border.SetValue(Border.HeightProperty, 32.0);
        border.SetValue(Border.WidthProperty, 32.0);
        border.SetValue(Border.CornerRadiusProperty, new CornerRadius(16));
        border.SetValue(Border.VerticalAlignmentProperty, VerticalAlignment.Center);
        border.SetValue(Border.HorizontalAlignmentProperty, HorizontalAlignment.Center);
        border.AppendChild(contentPresenter);

        var ct = new ControlTemplate(typeof(TileButton)){
            VisualTree = border,
        };
        return ct;
    }

    void TileButton_MouseEnter(object sender, MouseEventArgs e)
    {
        this.BackgroundBrush = Paint.MouseOverBackgroundBrush;
    }

    void TileButton_MouseLeave(object sender, MouseEventArgs e)
    {
        this.BackgroundBrush = Brushes.Transparent;
    }

    public event PropertyChangedEventHandler PropertyChanged = (sender, e) => { };

    private void OnPropertyChanged(string info)
    {
        PropertyChanged.Invoke(this, new PropertyChangedEventArgs(info));
    }
}
#endregion TileButton

#region FilerPanel
class FilerPanel : DataGrid
{
    private object _lockObject = new object();
    public FilerPanel()
    {
        Grid.SetRow(this, 1);
        this.Margin = new Thickness{Left = 10.0, Right = 10.0, Top = 15.0};
        this.Background = Brushes.Transparent;
        this.Foreground = Paint.ForegroundBrush;
        this.FontSize = 15.0;
        this.FontFamily = Paint.textFontFamily;
        this.BorderThickness = new Thickness(0.0);
        this.AutoGenerateColumns = false;
        this.HeadersVisibility = DataGridHeadersVisibility.Column;
        this.HorizontalScrollBarVisibility = ScrollBarVisibility.Hidden;
        VirtualizingPanel.SetScrollUnit(this, ScrollUnit.Pixel);
        Binding binding = new Binding() {
            Source = Data.FileInfoCollection
        };
        this.SetBinding(FilerPanel.ItemsSourceProperty, binding);
        this.ItemContainerStyle = CreateItemContainerStyle();
        this.CellStyle = CreateCellStyle();
        this.ColumnHeaderStyle = CreateColumnHeaderStyle();
        this.GridLinesVisibility = DataGridGridLinesVisibility.Horizontal;
        this.HorizontalGridLinesBrush = Paint.GrayBorderBrush;
        this.Columns.Add(new DataGridTemplateColumn{
            Header = "Name",
            CellTemplate = CreateNameCellTemplate(),
            Width = new DataGridLength(1.0, DataGridLengthUnitType.Star),
            MinWidth = 50.0,
            IsReadOnly = true,
            CanUserSort = true
        });

        this.Columns.Add(new DataGridTemplateColumn{
            Header = "Zone.Identifier",
            CellTemplate = CreateZoneIdCellTemplate(),
            Width = new DataGridLength(150.0),
            MinWidth = 50.0,
            IsReadOnly = true,
            CanUserSort = true
        });

        this.Columns.Add(new DataGridTextColumn{
            Header = "LastWriteTime",
            Binding = new Binding("LastWriteTimeString"),
            Width = new DataGridLength(200.0),
            MinWidth = 50.0,
            ElementStyle = CreateTextBlockStyle(),
            IsReadOnly = true,
            CanUserSort = true
        });

        this.Columns.Add(new DataGridTextColumn{
            //Width = new DataGridLength(50.0),
            ElementStyle = CreateTextBlockStyle(),
            IsReadOnly = true,
        });

        this.AddHandler(DataGridRow.PreviewMouseDoubleClickEvent, new MouseButtonEventHandler(DataGridRow_DoubleClick));
    }

    private void DataGridRow_DoubleClick(object sender, MouseButtonEventArgs e)
    {
        if (MouseButton.Left == e.ChangedButton)
        {
            try {
                var path = ((FileSystemInfoEntry)((FrameworkElement)e.OriginalSource).DataContext).Path;
                if (null != path && Directory.Exists(path))
                {
                    Data.CurrentDirectory =  new DirectoryInfo(path);
                }
            } catch { }
        }
    }

    private DataTemplate CreateNameCellTemplate()
    {
        var icon = new FrameworkElementFactory(typeof(Image));
        icon.SetValue(Image.WidthProperty, 16.0);
        icon.SetValue(Image.HeightProperty, 16.0);
        icon.SetValue(Image.MarginProperty, new Thickness{Left = 5.0, Right = 5.0});
        icon.SetBinding(Image.SourceProperty, new Binding("Icon"));
        icon.SetValue(DockPanel.DockProperty, Dock.Left);

        var name = new FrameworkElementFactory(typeof(TextBlock));
        name.SetValue(TextBlock.MarginProperty, new Thickness{Left = 5.0, Right = 5.0});
        name.SetValue(TextBlock.TextTrimmingProperty, TextTrimming.CharacterEllipsis);
        name.SetValue(TextBlock.VerticalAlignmentProperty, VerticalAlignment.Center);
        name.SetBinding(TextBlock.TextProperty, new Binding("Name"));
        name.SetValue(DockPanel.DockProperty, Dock.Right);
        
        var dockPanel = new FrameworkElementFactory(typeof(DockPanel));
        //stackPanel.SetValue(StackPanel.OrientationProperty, Orientation.Horizontal);
        dockPanel.AppendChild(icon);
        dockPanel.AppendChild(name);

        var template = new DataTemplate{
            VisualTree = dockPanel
        };
        return template;
    }

    private DataTemplate CreateZoneIdCellTemplate()
    {
        var check = new FrameworkElementFactory(typeof(TextBlock));
        check.SetValue(TextBlock.TextProperty, new Binding("HasZoneId"));
        check.SetValue(TextBlock.MarginProperty, new Thickness{Left = 55.0});
        check.SetValue(TextBlock.VerticalAlignmentProperty, VerticalAlignment.Center);
        //check.SetValue(TextBlock.TextAlignmentProperty, TextAlignment.Center);
        check.SetValue(TextBlock.FontSizeProperty, 18.0);
        check.SetValue(TextBlock.FontFamilyProperty, Paint.IconFontFamily);

        var template = new DataTemplate{
            VisualTree = check
        };
        return template;
    }

    private Style CreateColumnHeaderStyle()
    {
        var style = new Style();
        style.Setters.Add(new Setter(Control.BorderThicknessProperty, new Thickness{Right = 1.0}));
        style.Setters.Add(new Setter(Control.BorderBrushProperty, Paint.GrayBrush));
        style.Setters.Add(new Setter(Control.BackgroundProperty, Brushes.Transparent));
        style.Setters.Add(new Setter(Control.FontSizeProperty, 16.0));
        style.Setters.Add(new Setter(Control.FontWeightProperty, FontWeights.Medium));
        style.Setters.Add(new Setter(Control.MarginProperty, new Thickness{Left = 15.0, Bottom = 15.0}));
        return style;
    }

    private Style CreateCellStyle()
    {
        var style = new Style();
        style.Setters.Add(new Setter(Control.BorderThicknessProperty, new Thickness(0.0)));
        //style.Setters.Add(new Setter(Control.PaddingProperty, new Thickness{Left = 10.0, Right = 10.0}));
        return style;
    }

    private Style CreateItemContainerStyle()
    {
        var style = new Style();
        style.Setters.Add(new Setter(Control.BackgroundProperty, Brushes.Transparent));
        style.Setters.Add(new Setter(Control.HeightProperty, 40.0));
        //style.Setters.Add(new Setter(Control.MarginProperty, new Thickness{Top = 1.0, Bottom = 1.0}));
        return style;
    }

    private Style CreateTextBlockStyle()
    {
        var style = new Style();
        //style.Setters.Add(new Setter(TextBlock.PaddingProperty, new Thickness{Left = 5.0, Right = 5.0}));
        style.Setters.Add(new Setter(TextBlock.TextTrimmingProperty, TextTrimming.CharacterEllipsis));
        style.Setters.Add(new Setter(TextBlock.VerticalAlignmentProperty, VerticalAlignment.Center));
        return style;
    }
}
#endregion FilerPanel

#region CustomStatusBar
public class CustomStatusBar : StatusBar
{
    public CustomStatusBar()
    {
        Grid.SetColumnSpan(this, 2);
        Grid.SetRow(this, 2);
    }
}
#endregion CustomStatusBar

#region FileSystemInfoEntry
public class FileSystemInfoEntry
{
    public BitmapSource _icon;
    public string _name;
    public string _path;
    public DateTime _lastWriteTime;
    public bool _isDirectory;
    public bool _hasZoneId;

    public FileSystemInfoEntry(FileSystemInfo fsi)
    {
        this._path = fsi.FullName;
        this._name = fsi.Name;
        this._lastWriteTime = fsi.LastWriteTime;
        this._isDirectory = (bool)((fsi.Attributes & FileAttributes.Directory) == FileAttributes.Directory);
        this._icon = Shell.GetIconBitmapSource(this._path, fsi.Attributes);
        this._icon.Freeze();
        if (false == this._isDirectory) {
            this._hasZoneId = Shell.CheckZoneId(this._path);
        }
    }

    public BitmapSource Icon
    {
        get { return this._icon; }
    }

    public String Name
    {
        get { return this._name; }
    }

    public String Path
    {
        get { return this._path; }
    }

    public string HasZoneId
    {
        get
        {
            if (this._hasZoneId)
                return "\uE72E";
            else
                return String.Empty;
        }
    }

    public DateTime LastWriteTime
    {
        get { return this._lastWriteTime; }
    }

    public string LastWriteTimeString
    {
        get { return this._lastWriteTime.ToString(); }
    }

    public bool IsDirectory
    {
        get { return _isDirectory; }
    }
}
#endregion FileSystemInfoEntry

public static class Shell
{
    private const uint STATUS_BUFFER_OVERFLOW = 0x80000005;
    private static int SIZE_SHFILEINFO;

    static Shell()
    {
        SIZE_SHFILEINFO = Marshal.SizeOf(typeof(SHFILEINFO));
    }

    [DllImport("ntdll.dll")]
    private static extern IntPtr NtQueryInformationFile(SafeFileHandle fileHandle, out IO_STATUS_BLOCK IoStatusBlock, IntPtr pInfoBlock, int length, FILE_INFORMATION_CLASS fileInformation);  

    [DllImport("shell32.dll", CharSet=CharSet.Auto)]
    private static extern IntPtr SHGetFileInfo(string pszPath, FileAttributes dwFileAttributes, out SHFILEINFO psfi, int cbFileInfo, SHGFI uFlags);
    
    [DllImport("shell32.dll", CharSet=CharSet.Auto)]
    private static extern uint ExtractIconEx(string szFileName, int nIconIndex, IntPtr phiconLarge, out IntPtr phiconSmall, int nIcons);
    
    [DllImport("user32.dll", EntryPoint="DestroyIcon")]
    private static extern int DestroyIcon(IntPtr hIcon);

    struct IO_STATUS_BLOCK {
        internal uint status;
        internal ulong information;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    struct FILE_STREAM_INFORMATION {
        internal int NextEntryOffset;
        internal int StreamNameLength;
        internal ulong StreamSize;
        internal ulong StreamAllocationSize;
        [MarshalAsAttribute(UnmanagedType.ByValTStr, SizeConst = 260)]
        internal string StreamName;
    }

    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Auto)]
    private struct SHFILEINFO
    {
        public IntPtr hIcon;
        public int iIcon;
        public uint dwAttributes;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst=260)]
        public string szDisplayName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst=80)]
        public string szTypeName;
    };

    enum SHGFI : uint
    {
        Icon         = 0x000000100,
        LargeIcon    = 0x000000000,
        SmallIcon    = 0x000000001,
        UseFileAttributes= 0x000000010,  
    }

    enum FILE_INFORMATION_CLASS {
        FileDirectoryInformation = 1,     // 1
        FileStreamInformation = 22,       // 22
    }

    public static bool CheckZoneId(string path) {
        bool result = false;
        IntPtr buffer = IntPtr.Zero;
        FileStream fs = null;
        try {
            fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Delete);
        } catch {
            return false;
        }

        try {
            IO_STATUS_BLOCK iosb = new IO_STATUS_BLOCK();
            FILE_STREAM_INFORMATION fsi = new FILE_STREAM_INFORMATION();
            for (int i = 1; i < 255; i++)
            {
                buffer = Marshal.AllocCoTaskMem(1024 * i);
                IntPtr iprc = NtQueryInformationFile(fs.SafeFileHandle, out iosb, buffer, (1024 * i), FILE_INFORMATION_CLASS.FileStreamInformation);
                if (iprc == (IntPtr)STATUS_BUFFER_OVERFLOW)
                {
                    Marshal.FreeCoTaskMem(buffer);
                    continue;
                }
                else if(iprc == IntPtr.Zero)
                {
                    break;
                }
            }

            if (iosb.status == 0)
            {
                //Console.WriteLine(path);
                IntPtr p_fsi = new IntPtr(buffer.ToInt64());
                for (int i = 0; i < 255; i++)
                {
                    fsi = (FILE_STREAM_INFORMATION)Marshal.PtrToStructure(p_fsi, typeof(FILE_STREAM_INFORMATION));
                    //Console.WriteLine(fsi.StreamName.Substring(0, (fsi.StreamNameLength / 2)));
                    result = fsi.StreamName.Substring(0, (fsi.StreamNameLength / 2)).Contains(":Zone.Identifier");
                    if (fsi.NextEntryOffset != 0) {
                        p_fsi += fsi.NextEntryOffset;
                    } else {
                        break;
                    }
                }
            }
        } finally {
            if(null != fs) { fs.Close(); }
            if(buffer != IntPtr.Zero) { Marshal.FreeCoTaskMem(buffer); }
        }
        return result;
    }

    private static BitmapSource GetSystemIcon(int nIconIndex)
    {
        try
        {
            //IntPtr hLIcon = IntPtr.Zero;
            IntPtr hSIcon = IntPtr.Zero;
            ExtractIconEx("shell32.dll", nIconIndex, IntPtr.Zero, out hSIcon, 1);
            var bms = Imaging.CreateBitmapSourceFromHIcon(hSIcon, Int32Rect.Empty, BitmapSizeOptions.FromEmptyOptions());
            //DestroyIcon(hLIcon);
            DestroyIcon(hSIcon);

            return bms;
        } catch { 
            return BitmapSource.Create(24, 24, 96, 96, PixelFormats.Default, BitmapPalettes.WebPalette, new byte[72], 3);
        }
    }

    public static BitmapSource GetIconBitmapSource(string strPath, FileAttributes attr)
    {
        SHFILEINFO info = new SHFILEINFO();
        try {
            SHGetFileInfo(strPath, attr, out info, SIZE_SHFILEINFO, (SHGFI.Icon | SHGFI.SmallIcon | SHGFI.UseFileAttributes));
        } catch {
            return GetSystemIcon(0);
        }

        if (IntPtr.Zero == info.hIcon || null == info.hIcon)
            return GetSystemIcon(0);

        BitmapSource bms = Imaging.CreateBitmapSourceFromHIcon(info.hIcon, Int32Rect.Empty, BitmapSizeOptions.FromEmptyOptions());

        if (null != bms)
        {
            DestroyIcon(info.hIcon);
            return bms;
        }
        else
            return GetSystemIcon(0);
    }
}

#region CustomResourceDictionary
class CustomResourceDictionary : ResourceDictionary
{
    public CustomResourceDictionary()
    {
        this.Add("ScrollBarControlTemplate", CreateCustomScrollBarControlTemplate(Orientation.Horizontal));
        this.Add(typeof(ScrollBar), CreateCustomScrollBarStyle());
    }

    private ControlTemplate CreateCustomScrollBarControlTemplate(Orientation orientation)
    {
        var track = new FrameworkElementFactory(typeof(CustomTrack), "PART_Track");

        var border = new FrameworkElementFactory(typeof(Border));
        border.SetValue(Border.BackgroundProperty, Paint.ScrollBarBackgroundBrush);
        border.AppendChild(track);

        var grid = new FrameworkElementFactory(typeof(Grid));
        grid.SetValue(Grid.SnapsToDevicePixelsProperty, true);
        grid.AppendChild(border);

        var ct = new ControlTemplate(typeof(ScrollBar)){
            VisualTree = grid,
        };
        return ct;
    }

    private Style CreateCustomScrollBarStyle()
    {
        var style = new Style(typeof(ScrollBar));
        style.Setters.Add(new Setter(ScrollBar.MarginProperty, new Thickness{Left = 5.0}));
        style.Setters.Add(new Setter(ScrollBar.TemplateProperty, this["ScrollBarControlTemplate"]));
        return style;
    }
}
#endregion CustomResourceDictionary

#region CustomTrack
class CustomTrack : Track, INotifyPropertyChanged
{
    public Thickness _borderMargin;
    public Thickness BorderMargin
    {
        get { return _borderMargin; }
        set { _borderMargin = value; OnPropertyChanged("BorderMargin"); }
    }

    public CustomTrack()
    {
        this.Thumb = new Thumb{
            Template = CreateThumbTemplate(),
        };
        this.IsDirectionReversed = true;
        this.IsEnabled = true;
        this.DataContext = this;
    }

    private ControlTemplate CreateThumbTemplate()
    {
        var border = new FrameworkElementFactory(typeof(Border));

        border.SetValue(Border.BackgroundProperty, Paint.GrayBrush);
        var bindingBorderMargin = new Binding("BorderMargin"){
            Source = this,
        };
        border.SetBinding(Border.MarginProperty, bindingBorderMargin);
        border.SetValue(Border.CornerRadiusProperty, new CornerRadius(5.0));
        
        var ct = new ControlTemplate(typeof(Thumb)){
            VisualTree = border,
        };
        return ct;
    }

    protected override void OnRender(DrawingContext dc)
    {
        if (Orientation.Horizontal == this.Orientation) {
            this.BorderMargin = new Thickness{Top = 4.0, Bottom = 4.0};
        } else {
            this.BorderMargin = new Thickness{Left = 4.0, Right = 4.0};
        }
    }

    public event PropertyChangedEventHandler PropertyChanged = (sender, e) => { };

    private void OnPropertyChanged(string info)
    {
        PropertyChanged.Invoke(this, new PropertyChangedEventArgs(info));
    }
}
#endregion CustomTrack

#region Data
public static class Data
{
    public static ObservableCollection<FileSystemInfoEntry> FileInfoCollection;
    public static object _lockObject;
    public static CancellationTokenSource cTokenSource = null;

    static Data()
    {
        _lockObject = new object();
        FileInfoCollection = new ObservableCollection<FileSystemInfoEntry>();
        BindingOperations.EnableCollectionSynchronization(FileInfoCollection, _lockObject);
    }

    public static DirectoryInfo _currentDirectory;
    public static DirectoryInfo CurrentDirectory
    {
        get
        {
            if (null == _currentDirectory)
            {
                _currentDirectory = new DirectoryInfo(AppSettings.DesktopFolder);
            }
            return _currentDirectory;
        }
        set
        {
            if (null != _currentDirectory)
            {
                if (0 == _prevDirectories.Count || _prevDirectories[_prevDirectories.Count - 1] != _currentDirectory.FullName)
                {
                    _prevDirectories.Add(_currentDirectory.FullName);
                }
            }
            if (AppSettings.HistoryLimit <= _prevDirectories.Count)
            {
                _prevDirectories.RemoveAt(0);
            }
            if (_nextDirectories.Count > 0)
            {
                _nextDirectories.Clear();
            }
            _currentDirectory = value;
            OnCurrentDirectoryChanged();
        }
    }

    private static StringCollection _prevDirectories = new StringCollection();
    private static StringCollection _nextDirectories = new StringCollection();
    public static void PrevDirectory()
    {
        if (0 < _prevDirectories.Count)
        {
            string path = _prevDirectories[_prevDirectories.Count - 1];
            _prevDirectories.RemoveAt(_prevDirectories.Count - 1);
            _nextDirectories.Add(CurrentDirectory.FullName);
            _currentDirectory = new DirectoryInfo(path);
            OnCurrentDirectoryChanged();
        }
    }

    public static void NextDirectory()
    {
        if (0 < _nextDirectories.Count)
        {
            string path = _nextDirectories[_nextDirectories.Count - 1];
            _nextDirectories.RemoveAt(_nextDirectories.Count - 1);
            _prevDirectories.Add(CurrentDirectory.FullName);
            _currentDirectory = new DirectoryInfo(path);
            OnCurrentDirectoryChanged();
        }
    }

    public static event PropertyChangedEventHandler CurrentDirectoryChanged = (sender, e) => { };

    public static async void OnCurrentDirectoryChanged()
    {
        CurrentDirectoryChanged.Invoke(null, new PropertyChangedEventArgs("CurrentDirectory"));

        if (!(CurrentDirectory.Exists))
        {
            return;
        }

        if (null != cTokenSource)
        {
            cTokenSource.Cancel();
        }

        lock (_lockObject)
        {
            FileInfoCollection.Clear();
        }

        if (null == cTokenSource)
        {
            cTokenSource = new CancellationTokenSource();
        }
        else
        {
            cTokenSource.Dispose();
            cTokenSource = new CancellationTokenSource();
        }

        await GetCollectionAsync();
    }

    public static Task GetCollectionAsync()
    {
        CancellationToken token = cTokenSource.Token;
        return Task.Run(() => GetCollection(token), cTokenSource.Token).ContinueWith(t => {
            cTokenSource.Dispose();
            cTokenSource = null;
        });
    }

    public static void GetCollection(CancellationToken token)
    {
        lock (_lockObject)
        {
            foreach (var info in CurrentDirectory.EnumerateFileSystemInfos())
            {
                if (token.IsCancellationRequested)
                {
                    //token.ThrowIfCancellationRequested();
                    break;
                }
                FileInfoCollection.Add(new FileSystemInfoEntry(info));
            }
        }
    }
}
#endregion

#region AppSettings
static public class AppSettings
{
    private static int _historyLimit = 0;
    public static int HistoryLimit{
        get
        {
            if (0 >= _historyLimit) {
                string strHistoryLimit = ConfigurationManager.AppSettings["HistoryLimit"];
                int limit;
                try {
                    limit = Int32.Parse(strHistoryLimit);
                } catch {
                    limit = 256;
                }
                _historyLimit = limit;
            }
            return _historyLimit;
        }
        set
        {
            _historyLimit = value;
        }
    }

    [DllImport("shell32.dll", CharSet=CharSet.Auto)]
    private static extern int SHGetKnownFolderPath([MarshalAs(UnmanagedType.LPStruct)] Guid rfid, uint dwFlags, IntPtr hToken, out string pszPath);
    
    private static readonly Guid Downloads = new Guid("374DE290-123F-4565-9164-39C4925E467B");
    private static string _downloadFolder = ConfigurationManager.AppSettings["DownloadFolder"];
    public static string DownloadFolder{
        get
        {
            if (null == _downloadFolder) {
                string path;
                SHGetKnownFolderPath(Downloads, 0, IntPtr.Zero, out path);
                _downloadFolder = path;
            }
            return _downloadFolder;
        }
        set
        {
            _downloadFolder = value;
        }
    }

    private static string _desktopFolder = ConfigurationManager.AppSettings["DesktopFolder"];
    public static string DesktopFolder{
        get
        {
            if (null == _desktopFolder) {
                _desktopFolder = Environment.GetFolderPath(Environment.SpecialFolder.Desktop);
            }
            return _desktopFolder;
        }
        set
        {
            _desktopFolder = value;
        }
    }
}
#endregion AppSettings
'@ -ReferencedAssemblies WindowsBase, System.Threading, System.Xaml, PresentationFramework, PresentationCore, System.Configuration -ErrorAction Stop
}

if ($UserDebug) {
    $DebugPreference = 'Continue'
}

# ============================================================================ #
# region Program
function Program
{
    $MainWindow = New-Object MainWindow
    $MainWindow.SetCurrentDirectory([AppSettings]::DownloadFolder)
    $null = $MainWindow.ShowDialog()
    #$MainWindow.Close()
}
# endregion

$mutexObj = New-Object Threading.Mutex($false, ('Global\{0}' -f $MyInvocation.MyCommand.Name))

if ($mutexObj.WaitOne(0, $false)) {
    Program
    $mutexObj.ReleaseMutex()
}

$mutexObj.Close()

