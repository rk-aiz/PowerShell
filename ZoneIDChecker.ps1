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
using System.Windows;
using System.Windows.Input;
using System.Windows.Data;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Interop;
using System.Windows.Controls;
using System.Windows.Controls.Primitives;
using System.ComponentModel;
using System.Collections.ObjectModel;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;
using System.Configuration;

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
}
#endregion

#region MainWindow
public class MainWindow : System.Windows.Window
{

    public MainWindow()
    {
        InitializeComponent();
        Data.OnCurrentDirectoryChanged();
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

        this.Children.Add(new AddressBox());
        this.Children.Add(new FilerPanel());
        this.Children.Add(new CustomStatusBar());
    }
}
#endregion MainGrid

#region AddressBox
class AddressBox : TextBox, INotifyPropertyChanged
{
    public string _strCurrentDirectory;
    public string StrCurrentDirectory
    {
        get
        {
            try {
                _strCurrentDirectory = Data.CurrentDirectory.FullName;
            } catch { }
            return _strCurrentDirectory;
        }
        set { _strCurrentDirectory = value; OnCurrentDirectoryChanging(); }
    }

    public event PropertyChangedEventHandler PropertyChanged = (sender, e) => { };

    private void OnCurrentDirectoryChanging()
    {
        Console.WriteLine("OnCurrentDirectoryChanging");
        if (Directory.Exists(this._strCurrentDirectory)) {
            Data.CurrentDirectory = new DirectoryInfo(this._strCurrentDirectory);
        }
    }

    public AddressBox()
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
        scrollViewer.SetValue(ScrollViewer.MarginProperty, new Thickness{Left = 15.0, Right = 15.0, Top = 0.0, Bottom = 0.0});

        var border = new FrameworkElementFactory(typeof(Border));
        border.SetValue(Border.BorderThicknessProperty, new Thickness(1.0));
        border.SetValue(Border.BorderBrushProperty, Paint.TextBoxBorderBrush);
        border.SetValue(Border.HeightProperty, 35.0);
        border.SetValue(Border.CornerRadiusProperty, new CornerRadius(17.5));
        border.SetValue(DockPanel.DockProperty, Dock.Right);
        border.AppendChild(scrollViewer);

        var leftArrowButton = new FrameworkElementFactory(typeof(TileButton));
        leftArrowButton.SetValue(TileButton.ContentProperty, "\uE0A6");
        leftArrowButton.SetValue(TileButton.VerticalAlignmentProperty, VerticalAlignment.Center);

        var rightArrowButton = new FrameworkElementFactory(typeof(TileButton));
        rightArrowButton.SetValue(TileButton.ContentProperty, "\uE0AB");
        rightArrowButton.SetValue(TileButton.VerticalAlignmentProperty, VerticalAlignment.Center);

        var upArrowButton = new FrameworkElementFactory(typeof(TileButton));
        upArrowButton.SetValue(TileButton.ContentProperty, "\uE110");
        upArrowButton.SetValue(TileButton.VerticalAlignmentProperty, VerticalAlignment.Center);

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
}
#endregion AddressBox

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
        this.Margin = new Thickness{Left = 5.0, Right = 5.0};
        this.Foreground = Paint.ForegroundBrush;
        this.FontFamily = Paint.IconFontFamily;
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
        border.SetValue(Border.HeightProperty, 30.0);
        border.SetValue(Border.WidthProperty, 30.0);
        border.SetValue(Border.CornerRadiusProperty, new CornerRadius(15));
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
    public FilerPanel()
    {
        Grid.SetRow(this, 1);
        this.Margin = new Thickness{Left = 10.0, Right = 10.0, Top = 15.0};
        this.Background = Brushes.Transparent;
        this.Foreground = Paint.ForegroundBrush;
        this.FontSize = 15.0;
        this.BorderThickness = new Thickness(0.0);
        this.AutoGenerateColumns = false;
        this.HeadersVisibility = DataGridHeadersVisibility.Column;
        this.HorizontalScrollBarVisibility = ScrollBarVisibility.Hidden;
        VirtualizingPanel.SetScrollUnit(this, ScrollUnit.Pixel);
        this.ItemsSource = Data.FileInfoCollection;
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
            MinWidth = 50.0,
            IsReadOnly = true,
            CanUserSort = true
        });

        this.Columns.Add(new DataGridTextColumn{
            Header = "LastWriteTime",
            Binding = new Binding("LastWriteTimeString"),
            MinWidth = 50.0,
            ElementStyle = CreateTextBlockStyle(),
            IsReadOnly = true,
            CanUserSort = true
        });

        this.Columns.Add(new DataGridTextColumn{
            Width = new DataGridLength(20.0),
            IsReadOnly = true,
        });

        this.AddHandler(DataGridRow.PreviewMouseDoubleClickEvent, new MouseButtonEventHandler(DataGridRow_DoubleClick));
    }

    private void DataGridRow_DoubleClick(object sender, MouseButtonEventArgs e)
    {
        Console.WriteLine();
        if (MouseButton.Left == e.ChangedButton)
        {
            var path = ((FileSystemInfoEntry)((FrameworkElement)e.OriginalSource).DataContext).Path;
            if (null != path && Directory.Exists(path))
            {
                Console.WriteLine(path);
                Data.CurrentDirectory =  new DirectoryInfo(path);
            }
        }
    }

    private DataTemplate CreateNameCellTemplate()
    {
        var icon = new FrameworkElementFactory(typeof(Image));
        icon.SetValue(Image.WidthProperty, 16.0);
        icon.SetValue(Image.HeightProperty, 16.0);
        icon.SetValue(Image.MarginProperty, new Thickness{Left = 5.0, Right = 5.0});
        icon.SetBinding(Image.SourceProperty, new Binding("Icon"));

        var name = new FrameworkElementFactory(typeof(TextBlock));
        name.SetValue(TextBlock.MarginProperty, new Thickness{Left = 5.0, Right = 5.0});
        name.SetValue(TextBlock.TextTrimmingProperty, TextTrimming.CharacterEllipsis);
        name.SetValue(TextBlock.VerticalAlignmentProperty, VerticalAlignment.Center);
        name.SetBinding(TextBlock.TextProperty, new Binding("Name"));
        
        var stackPanel = new FrameworkElementFactory(typeof(StackPanel));
        stackPanel.SetValue(StackPanel.OrientationProperty, Orientation.Horizontal);
        stackPanel.AppendChild(icon);
        stackPanel.AppendChild(name);

        var template = new DataTemplate{
            VisualTree = stackPanel
        };
        return template;
    }

    private DataTemplate CreateZoneIdCellTemplate()
    {
        var check = new FrameworkElementFactory(typeof(TextBlock));
        check.SetValue(TextBlock.TextProperty, new Binding("HasZoneId"));
        check.SetValue(TextBlock.MarginProperty, new Thickness{Left = 5.0, Right = 5.0});
        check.SetValue(TextBlock.VerticalAlignmentProperty, VerticalAlignment.Center);
        check.SetValue(TextBlock.TextAlignmentProperty, TextAlignment.Center);
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
        style.Setters.Add(new Setter(Control.BackgroundProperty, Brushes.Transparent));
        style.Setters.Add(new Setter(Control.FontSizeProperty, 16.0));
        style.Setters.Add(new Setter(Control.MarginProperty, new Thickness{Left = 10, Right = 10, Bottom = 15.0}));
        return style;
    }

    private Style CreateCellStyle()
    {
        var style = new Style();
        style.Setters.Add(new Setter(Control.BorderThicknessProperty, new Thickness(0.0)));
        style.Setters.Add(new Setter(Control.PaddingProperty, new Thickness{Left = 10.0, Right = 10.0}));
        return style;
    }

    private Style CreateItemContainerStyle()
    {
        var style = new Style();
        style.Setters.Add(new Setter(Control.BackgroundProperty, Brushes.Transparent));
        style.Setters.Add(new Setter(Control.HeightProperty, 40.0));
        style.Setters.Add(new Setter(Control.MarginProperty, new Thickness{Top = 1.0, Bottom = 1.0}));
        return style;
    }

    private Style CreateTextBlockStyle()
    {
        var style = new Style();
        style.Setters.Add(new Setter(TextBlock.MarginProperty, new Thickness{Left = 5.0, Right = 5.0}));
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
public class FileSystemInfoEntry : INotifyPropertyChanged
{
    public BitmapSource _icon;
    public string _name;
    public string _path;
    public DateTime _lastWriteTime;
    public bool _isDirectory;
    public bool _hasZoneId;

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

    [DllImport("shell32.dll", CharSet=CharSet.Auto)]
    private static extern IntPtr SHGetFileInfo(string pszPath, FileAttributes dwFileAttributes, out SHFILEINFO psfi, int cbFileInfo, SHGFI uFlags);

    public FileSystemInfoEntry(FileSystemInfo fsi)
    {
        this._path = fsi.FullName;
        this._name = fsi.Name;
        this._lastWriteTime = fsi.LastWriteTime;
        this._isDirectory = (bool)((fsi.Attributes & FileAttributes.Directory) == FileAttributes.Directory);
        this._icon = GetIconBitmapSource(this._path, fsi.Attributes);
        if (false == this._isDirectory) {
            this._hasZoneId = NTFS.CheckZoneId(this._path);
        }
    }

    public static BitmapSource GetIconBitmapSource(string strPath, FileAttributes attr)
    {
        SHFILEINFO info = new SHFILEINFO();
        SHGFI flags = SHGFI.Icon | SHGFI.SmallIcon | SHGFI.UseFileAttributes;
        SHGetFileInfo(strPath, attr, out info, Marshal.SizeOf(info), flags);
            
        return Imaging.CreateBitmapSourceFromHIcon(info.hIcon, Int32Rect.Empty, BitmapSizeOptions.FromEmptyOptions());
    }

    public BitmapSource Icon
    {
        get { return this._icon; }
        set { this._icon = value; OnPropertyChanged("Icon"); }
    }

    public String Name
    {
        get { return this._name; }
        set { this._name = value; OnPropertyChanged("Name"); }
    }

    public String Path
    {
        get { return this._path; }
        set { this._path = value; OnPropertyChanged("Path"); }
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
        set { this._lastWriteTime = value; OnPropertyChanged("LastWriteTime"); }
    }

    public string LastWriteTimeString
    {
        get { return this._lastWriteTime.ToString(); }
    }

    public bool IsDirectory
    {
        get { return _isDirectory; }
        set { _isDirectory = value; OnPropertyChanged("IsDirectory"); }
    }

    public event PropertyChangedEventHandler PropertyChanged = (sender, e) => { };

    private void OnPropertyChanged(string info)
    {
        PropertyChanged.Invoke(this, new PropertyChangedEventArgs(info));
    }
}
#endregion FileSystemInfoEntry

public static class NTFS 
{
    [DllImport("ntdll.dll", SetLastError=true)]
    private static extern IntPtr NtQueryInformationFile(SafeFileHandle fileHandle, out IO_STATUS_BLOCK IoStatusBlock, IntPtr pInfoBlock, int length, FILE_INFORMATION_CLASS fileInformation);  

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

    enum FILE_INFORMATION_CLASS {
        FileDirectoryInformation = 1,     // 1
        FileStreamInformation = 22,        // 22
    }

    private const uint STATUS_BUFFER_OVERFLOW = 0x80000005;

    public static bool CheckZoneId(string path) {
        bool result = false;
        IntPtr buffer = IntPtr.Zero;
        try {
            IO_STATUS_BLOCK iosb = new IO_STATUS_BLOCK();
            FILE_STREAM_INFORMATION fsi = new FILE_STREAM_INFORMATION();
            using(FileStream fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read)) {
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
            }
        } finally {
            if(buffer != IntPtr.Zero) { Marshal.FreeCoTaskMem(buffer); }
        }
        return result;
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
        var binding = new Binding("BorderMargin"){
            Source = this,
        };
        border.SetBinding(Border.MarginProperty, binding);
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
    public static ObservableCollection<FileSystemInfoEntry> FileInfoCollection = new ObservableCollection<FileSystemInfoEntry>();
    
    public static DirectoryInfo _currentDirectory;
    public static DirectoryInfo CurrentDirectory
    {
        get
        {
            if (null == _currentDirectory)
            {
                _currentDirectory = new DirectoryInfo(AppSettings.DownloadFolder);
            }
        
            return _currentDirectory;
        }
        set { _currentDirectory = value; OnCurrentDirectoryChanged();}
    }

    public static event PropertyChangedEventHandler CurrentDirectoryChanged = (sender, e) => { };

    public static void OnCurrentDirectoryChanged(){
        FileInfoCollection.Clear();
        foreach (FileSystemInfo fsi in CurrentDirectory.EnumerateFileSystemInfos())
        {
            FileInfoCollection.Add(new FileSystemInfoEntry(fsi));
        }
        CurrentDirectoryChanged.Invoke(null, new PropertyChangedEventArgs("CurrentDirectory"));
    }
}
#endregion

#region AppSettings
public class AppSettings
{
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
}
#endregion AppSettings
'@ -ReferencedAssemblies WindowsBase, System.Xaml, PresentationFramework, PresentationCore, System.Configuration -ErrorAction Stop
}

if ($UserDebug) {
    $DebugPreference = 'Continue'
}

# ============================================================================ #
# region Program
function Program
{
    $MainWindow = New-Object MainWindow
    $null = $MainWindow.ShowDialog()
}
# endregion

$mutexObj = New-Object Threading.Mutex($false, ('Global\{0}' -f $MyInvocation.MyCommand.Name))

if ($mutexObj.WaitOne(0, $false)) {
    Program
    $mutexObj.ReleaseMutex()
}

$mutexObj.Close()

