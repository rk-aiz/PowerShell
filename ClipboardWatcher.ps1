<#

#>
using namespace System.Windows
using namespace System.Windows.Media.Imaging
using namespace System.Text

Param(
    [Parameter()]
    [switch] $Disable,
    [Parameter()]
    [switch] $ShowConsole,
    [Parameter()]
    [switch] $UserDebug
)

if ($ShowConsole -eq $false)
{
    #自身のps1をウィンドウ無しで再実行する
    $strDisable = $(if ($Disable) {'-Disable '} else {''})
    $StartInfo = New-Object Diagnostics.ProcessStartInfo
    $StartInfo.UseShellExecute = $false
    $StartInfo.CreateNoWindow = $true
    $StartInfo.FileName = "powershell.exe"
    $StartInfo.Arguments = '-NoProfile -NonInteractive -ExecutionPolicy Unrestricted -File "{0}" -ShowConsole {1}' -f $MyInvocation.MyCommand.Path, $strDisable
    $Process = New-Object Diagnostics.Process
    $Process.StartInfo = $StartInfo
    $null = $Process.Start()
    return
}

#============================================================================ #
#region MainWindow
Try {
    [void][MainWindow]
} Catch {
Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Net;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Threading;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Navigation;
using System.Windows.Media.Imaging;
using System.Diagnostics;
using System.Configuration;
using Microsoft.Win32;
using System.Runtime.InteropServices;
using System.ComponentModel;

public class MainWindow : System.Windows.Window
{
    private MainStackPanel _stackPanel = new MainStackPanel();
    private Rect _workArea = System.Windows.SystemParameters.WorkArea;
    private int windowMargin = 25;

    public MainWindow()
    {
        AllowsTransparency = true;
        WindowStyle = WindowStyle.None;
        Background = Brushes.Transparent;
        ShowInTaskbar = false;
        this.Width = 500;
        this.SizeToContent = SizeToContent.Height;
        
        _stackPanel.RenderSizeChanged += MainStackPanel_RenderSizeChanged ;
        Content = _stackPanel;
    }

    private void MainStackPanel_RenderSizeChanged (object sender, EventArgs e)
    {
        if (this.ActualHeight + windowMargin > _workArea.Height) {
            _stackPanel.Children.RemoveAt(0);
        } else {
            SetWindowLocation();
        }
    }

    protected override void OnClosing (System.ComponentModel.CancelEventArgs e)
    {
        base.OnClosing(e);
    }

    public void AddTextPanel (string text, string sourceText)
    {
        this._stackPanel.Children.Add(new TextPanel(text, sourceText));
    }

    public void AddHyperlinkPanel (string text, string sourceText)
    {
        this._stackPanel.Children.Add(new HyperlinkPanel(text, sourceText));
    }

    public void AddImagePanel (BitmapSource bmpSource, string sourceText)
    {
        this._stackPanel.Children.Add(new ImagePanel(bmpSource, sourceText));
    }

    public void AddImagePanel (BitmapSource bmpSource, Uri sourceUri)
    {
        this._stackPanel.Children.Add(new ImagePanel(bmpSource, sourceUri));
    }

    private void SetWindowLocation()
    {
        if (0 < _workArea.Left)
        {
            this.Left = _workArea.Left + windowMargin;
            this.Top = _workArea.Bottom - this.ActualHeight - windowMargin;
        }
        else if (0 < _workArea.Top)
        {
            this.Left = _workArea.Right - this.ActualWidth - windowMargin;
            this.Top = _workArea.Top + windowMargin;
        }
        else
        {
            this.Left = _workArea.Right - this.ActualWidth - windowMargin;
            this.Top = _workArea.Bottom - this.ActualHeight - windowMargin;
        }
    }
}

class MainStackPanel : StackPanel
{
    public event EventHandler RenderSizeChanged = (sender, e) => { };

    protected override void OnRenderSizeChanged (SizeChangedInfo sizeInfo)
    {
        RenderSizeChanged.Invoke(this, EventArgs.Empty);
    }
}

abstract class CustomPanel : Grid, IDisposable
{
    protected static Brush ForegroundBrush = new SolidColorBrush(Colors.WhiteSmoke);

    protected static Color MouseOverBackgroundColor = new Color {A = 255, R = 70, G = 70, B = 70};
    protected static Brush MouseOverBackgroundBrush = new SolidColorBrush(MouseOverBackgroundColor);

    protected static Color ButtonBackgroundColor = new Color {A = 255, R = 60, G = 60, B = 60};
    protected static Brush ButtonBackgroundBrush = new SolidColorBrush(ButtonBackgroundColor);

    protected static Color ButtonMouseOverBackgroundColor = new Color {A = 255, R = 75, G = 75, B = 75};
    protected static Brush ButtonMouseOverBackgroundBrush = new SolidColorBrush(ButtonMouseOverBackgroundColor);

    protected static FontFamily IconFont = new FontFamily("Segoe MDL2 Assets");

    protected string IconText = "\uF0E3";

    protected Button _closeButton;
    protected Button _copyButton;
    protected TextBlock _sourceTextBegin;
    protected TextBlock _sourceTextEnd;
    protected StackPanel _buttonStack;
    protected DockPanel _textDock;
    protected DockPanel _bottomDock;

    protected abstract void CopyButton_Click (object sender, RoutedEventArgs e);

    public CustomPanel()
    {
        this.HorizontalAlignment = HorizontalAlignment.Stretch;
        this.Margin = new Thickness{Top = 15.0};
        this.Background = new SolidColorBrush(Color.FromRgb(30, 30, 30));
        this.Effect = new System.Windows.Media.Effects.DropShadowEffect
        {
            Color = Colors.Black,
            BlurRadius = 15.0,
            ShadowDepth = 0,
            Opacity = 0.65
        };
        this.RowDefinitions.Add(new RowDefinition{MinHeight = 35.0});
        this.RowDefinitions.Add(new RowDefinition{MinHeight = 35.0});
        this.ColumnDefinitions.Add(new ColumnDefinition{MinWidth = 35.0, Width = GridLength.Auto});
        this.ColumnDefinitions.Add(new ColumnDefinition{Width = new GridLength(1.0, GridUnitType.Star)});
        this.ColumnDefinitions.Add(new ColumnDefinition{MinWidth = 35.0, Width = GridLength.Auto});
    }

    protected void InitializeChildren()
    {
        TextBlock textIcon = new TextBlock {
            FontFamily = IconFont,
            Text = IconText,
            FontSize = 20.0,
            Foreground = ForegroundBrush,
            Margin = new Thickness(10.0, 10.0, 5.0, 0.0)
        };
        SetColumn(textIcon, 0);
        this._closeButton = new Button{
            Style = CloseButtonStyle()
        };
        this._closeButton.Click += new RoutedEventHandler(CloseButton_Click);
        SetColumn(this._closeButton, 2);

        this._copyButton = new Button{
            Style = ActionButtonStyle("Copy")
        };
        this._copyButton.Click += new RoutedEventHandler(CopyButton_Click);

        this._bottomDock = new DockPanel{
            LastChildFill = false
        };
        SetRow(this._bottomDock, 1);
        SetColumnSpan(this._bottomDock, 3);

        this._buttonStack = new StackPanel{
            Orientation = Orientation.Horizontal,
            FlowDirection = FlowDirection.RightToLeft
        };
        DockPanel.SetDock(this._buttonStack, Dock.Right);

        this._textDock = new DockPanel{
            Margin = new Thickness{Left = 10.0, Right = 10.0}
        };
        DockPanel.SetDock(this._textDock, Dock.Left);

        this._sourceTextBegin = new TextBlock{
            VerticalAlignment = VerticalAlignment.Center,
            Foreground = ForegroundBrush,
            TextTrimming = TextTrimming.CharacterEllipsis,
            BaselineOffset = 2
        };
        DockPanel.SetDock(this._sourceTextBegin, Dock.Left);

        this._sourceTextEnd = new TextBlock{
            VerticalAlignment = VerticalAlignment.Center,
            Foreground = ForegroundBrush,
            BaselineOffset = 2
        };
        DockPanel.SetDock(this._sourceTextEnd, Dock.Right);

        this._textDock.Children.Add(this._sourceTextEnd);
        this._textDock.Children.Add(this._sourceTextBegin);

        this._buttonStack.Children.Add(this._copyButton);

        this._bottomDock.Children.Add(this._buttonStack);
        this._bottomDock.Children.Add(this._textDock);


        this.Children.Add(textIcon);
        this.Children.Add(this._closeButton);
        this.Children.Add(this._bottomDock);
    }

    private void CloseButton_Click (object sender, RoutedEventArgs e)
    {
        Dispose();
    }

    private static Style CloseButtonStyle()
    {
        FrameworkElementFactory tb = new FrameworkElementFactory(typeof(TextBlock));
        tb.SetValue(TextBlock.WidthProperty, 15.0);
        tb.SetValue(TextBlock.HeightProperty, 15.0);
        tb.SetValue(TextBlock.TextAlignmentProperty, TextAlignment.Center);
        tb.SetValue(TextBlock.FontSizeProperty, 15.0);
        tb.SetValue(TextBlock.FontWeightProperty, FontWeights.UltraBold);
        tb.SetValue(TextBlock.ForegroundProperty, ForegroundBrush);
        tb.SetValue(TextBlock.FontFamilyProperty, new FontFamily("Segoe MDL2 Assets"));
        tb.SetValue(TextBlock.TextProperty, "\uE10A");

        FrameworkElementFactory factory = new FrameworkElementFactory(typeof(Border));
        factory.Name = "border";
        factory.SetValue(Border.WidthProperty, 25.0);
        factory.SetValue(Border.HeightProperty, 25.0);
        factory.SetValue(Border.VerticalAlignmentProperty, VerticalAlignment.Top);
        factory.SetValue(Border.CornerRadiusProperty, new CornerRadius(5.0));
        factory.AppendChild(tb);
        ControlTemplate ct = new ControlTemplate(typeof(Button));
        ct.VisualTree = factory;

        Trigger mouseOverTrigger = new Trigger();
        mouseOverTrigger.Property = Button.IsMouseOverProperty;
        mouseOverTrigger.Value = true;
        mouseOverTrigger.Setters.Add(new Setter{
            TargetName = "border",
            Property = Border.BackgroundProperty,
            Value = MouseOverBackgroundBrush
        });

        ct.Triggers.Add(mouseOverTrigger);
        Style style = new Style(typeof(Button));
        style.Setters.Add(new Setter(Button.TemplateProperty, ct));
        style.Setters.Add(new Setter(Button.MarginProperty, new Thickness(7.5)));
        return style;
    }

    protected static Style ActionButtonStyle(string caption)
    {
        FrameworkElementFactory tb = new FrameworkElementFactory(typeof(TextBlock));
        tb.SetValue(TextBlock.PaddingProperty, new Thickness(15.0, 5.0, 15.0, 5.0));
        tb.SetValue(TextBlock.FontSizeProperty, 14.0);
        tb.SetValue(TextBlock.TextAlignmentProperty, TextAlignment.Center);
        tb.SetValue(TextBlock.ForegroundProperty, ForegroundBrush);
        tb.SetValue(TextBlock.TextProperty, caption);

        FrameworkElementFactory factory = new FrameworkElementFactory(typeof(Border));
        factory.Name = "border";
        factory.SetValue(Border.VerticalAlignmentProperty, VerticalAlignment.Top);
        factory.SetValue(Border.CornerRadiusProperty, new CornerRadius(5.0));
        factory.SetValue(Border.BackgroundProperty, ButtonBackgroundBrush);
        factory.AppendChild(tb);
        ControlTemplate ct = new ControlTemplate(typeof(Button));
        ct.VisualTree = factory;

        MultiTrigger mouseOverTrigger = new MultiTrigger();
        mouseOverTrigger.Conditions.Add(new Condition{
            Property = Border.IsMouseOverProperty,
            Value = true
        });
        mouseOverTrigger.Conditions.Add(new Condition{
            Property = Border.IsMouseCapturedProperty,
            Value = false
        });
        mouseOverTrigger.Setters.Add(new Setter{
            TargetName = "border",
            Property = Border.BackgroundProperty,
            Value = ButtonMouseOverBackgroundBrush
        });

        ct.Triggers.Add(mouseOverTrigger);
        Style style = new Style(typeof(Button));
        style.Setters.Add(new Setter(Button.TemplateProperty, ct));
        style.Setters.Add(new Setter(Button.MarginProperty, new Thickness{Left = 15.0, Bottom = 15.0})); //FlowDirection.RightToLeftの為 Leftマージンを設定
        return style;
    }

    protected Window GetWindowObject()
    {
        try {
            DependencyObject dpObj = this;
            while (null != dpObj) {
                dpObj = VisualTreeHelper.GetParent(dpObj);
                if (typeof(Window) == dpObj.DependencyObjectType.SystemType) {
                    return (Window)dpObj;
                }
            }
            return null;
        } catch {
            return null;
        }
    }

    public void Dispose()
    {
        try {
            this.Children.Clear();
            ((StackPanel)this.VisualParent).Children.Remove(this);
        } catch { }
    }
}

class TextPanel : CustomPanel
{
    private string _text;

    public TextPanel(string text, string sourceText)
    {
        this._text = text;
        InitializeComponent();
        this._sourceTextBegin.Text = sourceText;
    }

    private void InitializeComponent()
    {
        this.IconText = "\uF000";
        InitializeChildren();

        TextBox textContent = new TextBox
        {
            Text = this._text,
            IsReadOnly = true,
            BorderThickness = new Thickness(0.0),
            Background = Brushes.Transparent,
            Foreground = ForegroundBrush,
            TextAlignment = TextAlignment.Left,
            FontSize = 17.0,
            Margin = new Thickness(5.0)
        };
        SetColumn(textContent, 1);
        this.Children.Add(textContent);
    }

    protected override void CopyButton_Click (object sender, RoutedEventArgs e)
    {
        try {
            DataObject dataObj = new DataObject();
            dataObj.SetText(this._text);
            Clipboard.SetDataObject(dataObj);
            this.Dispose();

        } catch { }
    }
}

class HyperlinkPanel : CustomPanel
{
    private string _urlString;
    private string _savedFilePath;
    private Button _downloadButton;
    private Button _cancelButton;
    private Button _openButton;
    private Button _openFolderButton;
    private WebClient _webClnt;

    public HyperlinkPanel (string urlString, string sourceText)
    {
        this._urlString = urlString;
        InitializeComponent();
        this._sourceTextBegin.Text = sourceText;
    }

    private void InitializeComponent()
    {
        this.IconText = "\uE167";
        InitializeChildren();

        Hyperlink hyperlinkContent = new Hyperlink(new Run(this._urlString))
        {
            NavigateUri = new Uri(this._urlString),
            Foreground = new SolidColorBrush(new Color {A = 255, R = 3, G = 169, B = 245}),
        };
        hyperlinkContent.TextDecorations = new TextDecorationCollection();
        hyperlinkContent.RequestNavigate += new RequestNavigateEventHandler(RequestNavigate);
        hyperlinkContent.MouseEnter += new MouseEventHandler(Hyperlink_MouseEnter);
        hyperlinkContent.MouseLeave += new MouseEventHandler(Hyperlink_MouseLeave);

        TextBlock outerTextBlock = new TextBlock(hyperlinkContent)
        {
            Foreground = ForegroundBrush,
            TextAlignment = TextAlignment.Left,
            TextWrapping = TextWrapping.Wrap,
            FontSize = 17.0,
            Margin = new Thickness(5.0),
        };
        SetColumn(outerTextBlock, 1);
        this.Children.Add(outerTextBlock);

        this._downloadButton = new Button{
            Style = ActionButtonStyle("Download")
        };
        this._downloadButton.Click += new RoutedEventHandler(DownloadButton_Click);

        this._cancelButton = new Button{
            Style = ActionButtonStyle("Cancel"),
        };
        this._cancelButton.Click += new RoutedEventHandler(CancelButton_Click);

        this._openButton = new Button{
            Style = ActionButtonStyle("Open"),
        };
        this._openButton.Click += new RoutedEventHandler(OpenButton_Click);

        this._openFolderButton = new Button{
            Style = ActionButtonStyle("Open Folder"),
        };
        this._openFolderButton.Click += new RoutedEventHandler(OpenFolderButton_Click);

        this._buttonStack.Children.Add(this._downloadButton);
    }

    private void RequestNavigate(object sender, RequestNavigateEventArgs e)
    {
        try {
            Process.Start( new ProcessStartInfo( e.Uri.AbsoluteUri ) );
            e.Handled = true;
        } catch { }
    }

    private void Hyperlink_MouseEnter( object sender, MouseEventArgs e )
    {
        try {
            ((Hyperlink)sender).TextDecorations.Add(TextDecorations.Underline);
        } catch { }
    }

    private void Hyperlink_MouseLeave( object sender, MouseEventArgs e )
    {
        try {
            ((Hyperlink)sender).TextDecorations.Clear();
        } catch { }
    }

    protected override void CopyButton_Click (object sender, RoutedEventArgs e)
    {
        try {
            DataObject dataObj = new DataObject();
            dataObj.SetText(this._urlString);
            Clipboard.SetDataObject(dataObj);
            this.Dispose();

        } catch { }
    }

    protected void DownloadButton_Click(object sender, RoutedEventArgs e)
    {
        var dialog = new SaveFileDialog();
        dialog.InitialDirectory = AppSettings.DownloadFolder;
        dialog.Filter = "All file (*.*)|*.*";

        if (null != this._urlString) {
            var uriObj = new Uri(this._urlString);
            var uriPath = uriObj.GetLeftPart(UriPartial.Path);
            dialog.FileName = Path.Combine(dialog.InitialDirectory , Path.GetFileName(Uri.UnescapeDataString(uriPath)));
            var ext = Path.GetExtension(uriPath);
            dialog.Filter = String.Format("{0} (*{1})|*{1}|{2}", ext.Trim('.').ToUpper(), ext, dialog.Filter);
        }

        var result = dialog.ShowDialog(this.GetWindowObject());
        
        if (true != result)
            return;

        _webClnt = new WebClient();

        this._buttonStack.Children.Remove(this._downloadButton);
        this._buttonStack.Children.Add(this._cancelButton);
        try {
            this._webClnt.DownloadProgressChanged += new DownloadProgressChangedEventHandler(
                DownloadProgressChangedCallback);
            this._webClnt.DownloadFileCompleted += new AsyncCompletedEventHandler(DownloadFileCallback);
            this._webClnt.DownloadFileAsync(new Uri(this._urlString), dialog.FileName, dialog.FileName);
        } catch {
            this._buttonStack.Children.Remove(this._cancelButton);
            this._buttonStack.Children.Add(this._downloadButton);
        }
    }

    protected void CancelButton_Click(object sender, RoutedEventArgs e)
    {
        this._webClnt.CancelAsync();
    }

    protected void OpenButton_Click(object sender, RoutedEventArgs e)
    {
        if (null == this._savedFilePath)
            return;

        Process.Start(this._savedFilePath);
    }

    protected void OpenFolderButton_Click(object sender, RoutedEventArgs e)
    {
        if (null == this._savedFilePath)
            return;

        Process.Start("explorer.exe", String.Format("/select,\"{0}\"", this._savedFilePath));
    }

    protected void DownloadFileCallback(object sender, AsyncCompletedEventArgs e)
    {
        Console.WriteLine(e.UserState);

        if (e.Cancelled || null != e.Error) {
            Console.WriteLine("Download Cancelled");
            this._buttonStack.Children.Remove(this._cancelButton);
            this._buttonStack.Children.Add(this._downloadButton);
        } else {
            Console.WriteLine("Download Completed");
            this._savedFilePath = (string)e.UserState;
            this._buttonStack.Children.Remove(this._cancelButton);
            this._buttonStack.Children.Add(this._openButton);
            this._buttonStack.Children.Add(this._openFolderButton);
            var fi = new FileInfo(this._savedFilePath);
            if (fi.Exists)
                this._sourceTextBegin.Text = String.Format("{0} - ", fi.Name);
                this._sourceTextEnd.Text = String.Format("{0}KB", (fi.Length / 1024));
        }

        this._webClnt.Dispose();
    }

    protected void DownloadProgressChangedCallback(object sender, DownloadProgressChangedEventArgs e)
    {
        Console.WriteLine(e.ProgressPercentage);
    }
}

class ImagePanel : CustomPanel
{
    private BitmapSource _bmpSource;
    private string _sourceText;

    public ImagePanel (BitmapSource bmpSource, string sourceText)
    {
        this._bmpSource = bmpSource;
        InitializeComponent();
        this._sourceText = sourceText;
        this._sourceTextBegin.Text = sourceText;
    }

    public ImagePanel (BitmapSource bmpSource, Uri sourceUri)
    {
        this._bmpSource = bmpSource;
        InitializeComponent();
        this._sourceText = sourceUri.OriginalString;
        this._sourceTextBegin.Text = Path.GetDirectoryName(this._sourceText).Replace('\\', '/');
        this._sourceTextEnd.Text = '/' + Path.GetFileName(this._sourceText);
    }

    private void InitializeComponent()
    {
        this.IconText = "\uEB9F";
        InitializeChildren();

        Image imageContent = new Image{
            Source = this._bmpSource,
            Margin = new Thickness(5.0),
            StretchDirection = StretchDirection.DownOnly,
            HorizontalAlignment = HorizontalAlignment.Left
        };
        SetColumn(imageContent, 1);
        this.Children.Add(imageContent);

        Button saveButton = new Button{
            Style = ActionButtonStyle("Save")
        };
        saveButton.Click += new RoutedEventHandler(SaveButton_Click);
        this._buttonStack.Children.Add(saveButton);
    }

    protected override void CopyButton_Click (object sender, RoutedEventArgs e)
    {
        try {
            DataObject dataObj = new DataObject();
            dataObj.SetImage(this._bmpSource);
            Clipboard.SetDataObject(dataObj);
            this.Dispose();
        } catch { }
    }

    protected void SaveButton_Click (object sender, RoutedEventArgs e)
    {
        var dialog = new SaveFileDialog();
        dialog.Filter = "PNG (*.png)|*.png|JPG (*.jpg)|*.jpg|BMP (*.bmp)|*.bmp|All file (*.*)|*.*";
        dialog.InitialDirectory = AppSettings.SaveImageFolder;

        if (null != this._sourceText)
            dialog.FileName = Path.Combine(dialog.InitialDirectory , Path.GetFileNameWithoutExtension(this._sourceText));

        var result = dialog.ShowDialog(this.GetWindowObject());
        
        if (true != result)
            return;
        
        using (var fileStream = new FileStream(dialog.FileName, FileMode.Create))
        {
            string extention = Path.GetExtension(dialog.FileName).ToLower();
            BitmapEncoder encoder;
            if (".jpg" == extention || ".jpeg" == extention) {
                encoder = new JpegBitmapEncoder();
            } else if (".png" == extention) {
                encoder = new PngBitmapEncoder();
            } else {
                encoder = new BmpBitmapEncoder();
            }
            encoder.Frames.Add(BitmapFrame.Create(this._bmpSource));
            encoder.Save(fileStream);
        }
    }
}

public class AppSettings
{
    [DllImport("shell32.dll", CharSet=CharSet.Auto)]
    private static extern int SHGetKnownFolderPath([MarshalAs(UnmanagedType.LPStruct)] Guid rfid, uint dwFlags, IntPtr hToken, out string pszPath);
    
    private static readonly Guid Downloads = new Guid("374DE290-123F-4565-9164-39C4925E467B");
    public static string SaveImageFolder = ConfigurationManager.AppSettings["SaveImageFolder"] ?? Environment.GetFolderPath(Environment.SpecialFolder.MyPictures);
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
'@ -ReferencedAssemblies WindowsBase, System.Xaml, PresentationFramework, PresentationCore, System.Configuration -ErrorAction Stop
}
#endregion

#region ClipBoardWatcher
Try {
    [void][ClipBoardWatcher]
} Catch {
Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Drawing;
using System.Windows.Forms;
using System.Runtime.InteropServices;

public class ClipBoardWatcher : System.Windows.Forms.Form
{
    [DllImport("user32.dll")]
    private static extern bool AddClipboardFormatListener(IntPtr hWnd);

    [DllImport("user32.dll")]
    private static extern bool RemoveClipboardFormatListener(IntPtr hWnd);

    [DllImport("user32.dll")]
    private static extern IntPtr GetClipboardOwner();

    private const int WM_DRAWCLIPBOARD = 0x031D;
    private bool listenState = false;
    public NotifyIcon _notifyIcon;
    public NotifyIcon NotifyIcon{
        get { return _notifyIcon; }
    }

    public delegate void ClipboardChangedEventHandler(object sender, ClipboardChangedEventArgs e);
    public event ClipboardChangedEventHandler ClipboardChanged = (sender, e) => { };

    public ClipBoardWatcher()
    {
        this._notifyIcon = new NotifyIcon()
        {
            Visible = true,
            Icon = SystemIcons.Application,
            Text = "ClipboardWatcher"
        };

        this._notifyIcon.ContextMenuStrip = InitializeMenuStrip();
    }

    new public void Close ()
    {
        if (null != _notifyIcon) {
            _notifyIcon.Visible = false;
            _notifyIcon.Dispose();
            _notifyIcon = null;
        }
        base.Close();
    }

    private ContextMenuStrip InitializeMenuStrip()
    {
        var menuStrip  = new ContextMenuStrip();
        //menu.Items.Add("各種設定", null, (s, e) => { ShowMainWindow(); });
        menuStrip.Items.Add("Exit", null, (s, e) => { System.Windows.Forms.Application.ExitThread(); });
        return menuStrip;
    }

    protected override void WndProc(ref Message m)
    {
        if (m.Msg == WM_DRAWCLIPBOARD) {
            IntPtr hWnd = GetClipboardOwner();
            this.OnClipboardChanged(hWnd);
        }
        base.WndProc(ref m);
    }

    public void OnClipboardChanged(IntPtr hWnd)
    {
        var e = new ClipboardChangedEventArgs(hWnd);
        ClipboardChanged.Invoke(this, e);
    }

    public void Start()
    {
        if (false == this.listenState)
            this.listenState = AddClipboardFormatListener(this.Handle);
    }

    public void Stop()
    {
        if (true == this.listenState)
            this.listenState = RemoveClipboardFormatListener(this.Handle) ? false : true;
    }
}

public class ClipboardChangedEventArgs : EventArgs
{
    [DllImport("user32.dll")]
    private static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

    private IntPtr _hWnd;
    public IntPtr Handle { get {return _hWnd; } }
    
    public ClipboardChangedEventArgs(IntPtr hWnd)
    {
        this._hWnd = hWnd;
    }

    public uint GetSourceProcessId()
    {
        if (null == this._hWnd)
            return 0;
        
        uint processId = 0;
        try {
            uint threadId = GetWindowThreadProcessId(this._hWnd, out processId);
        } catch { }
        return processId;
    }
}
'@ -ReferencedAssemblies System.Windows.Forms, System.Drawing -ErrorAction Stop
}

#endregion

if ($UserDebug) {
    $DebugPreference = 'Continue'
}

$global:UrlRegExStr = @'
^http(s)?://[-_.!~*'()a-zA-Z0-9;/?:@&=+$,%#]+$
'@

# ============================================================================ #
# region Program
function Program
{
    Param(
        [Parameter()]
        [bool] $Disable = $false
    )

    $UrlRegEx = New-Object RegEx $global:UrlRegExStr
    $appContext = New-Object Windows.Forms.ApplicationContext
    $ClipBoardWatcher = New-Object ClipboardWatcher
    $MainWindow = New-Object MainWindow
    $MainWindow.Show()

    if ($false -eq $Disable)
    {
        $ClipBoardWatcher.Start()
    }

    $ClipBoardWatcher.add_ClipboardChanged(
    {
        Param($s, $e)

        $sProcess = Get-Process -Id $e.GetSourceProcessId()

        Write-Debug ("ClipboardChanged : {0}" -f $sProcess.MainModule.ModuleName)

        $dataObj = [Clipboard]::GetDataObject()

        if ($null -eq $dataObj) {
            return
        }
        Write-Debug ($dataObj.GetFormats() -join ' ')

        $sourceText = '{0} - {1}' -f $sProcess.MainModule.ModuleName, [DateTime]::Now.ToString("HH:mm:ss")

        if ($dataObj.ContainsText())
        {
            $text = $dataObj.GetText()
            if ($UrlRegEx.IsMatch($text)) {
                $MainWindow.AddHyperlinkPanel($text, $sourceText)
            }
            elseif ($text -notmatch "^\s*$")
            {
                $MainWindow.AddTextPanel($text, $sourceText)
            }
        }
        elseif ($dataObj.ContainsImage())
        {
            $memoryStream = [System.IO.MemoryStream]$dataObj.GetData('UniformResourceLocatorW')
            if ($null -ne $memoryStream) {
                $buffer = new-object byte[] $memoryStream.Length
                $count = $memoryStream.Read($buffer, $memoryStream.Position, $memoryStream.Length)
                $converted = [Encoding]::Convert([Encoding]::Unicode, [Encoding]::UTF8, $buffer)
                $urlString = [Encoding]::UTF8.GetString($converted).Trim("`0")
                Write-Debug ("Source URL : $urlString")
                if ($UrlRegEx.IsMatch($urlString)) {
                    $MainWindow.AddImagePanel($dataObj.GetImage(), (New-Object System.Uri $urlString))
                    return
                }
            }

            $MainWindow.AddImagePanel($dataObj.GetImage(), $sourceText)
        }
    })

    $ClipBoardWatcher.NotifyIcon.add_MouseDoubleClick(
    {
        if ($MainWindow.Visibility -eq 'Visible')
        {
            $MainWindow.Visibility = 'Hidden'
        }
        else
        {
            $MainWindow.Visibility = 'Visible'
        }
    })

    [Windows.Forms.Application]::Run($appContext)
    $ClipBoardWatcher.Stop()
    $MainWindow.Close()
    $ClipBoardWatcher.Close()
}
# endregion

$mutexObj = New-Object Threading.Mutex($false, ('Global\{0}' -f $MyInvocation.MyCommand.Name))

if ($mutexObj.WaitOne(0, $false)) {
    Program -Disable $Disable
    $mutexObj.ReleaseMutex()
}

$mutexObj.Close()

