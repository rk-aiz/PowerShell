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
using System.Windows.Media.Animation;
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

    public static Color GrayBorderColor = new Color{A =255, R =75, G = 75, B = 75};
    public static Brush GrayBorderBrush = new SolidColorBrush(GrayBorderColor);

    public static Color TextBoxBackgroundColor = new Color{A =255, R = 30, G = 30, B = 30};
    public static Brush TextBoxBackgroundBrush = new SolidColorBrush(TextBoxBackgroundColor);

    public static Color TextBoxBorderColor = new Color{A =255, R = 80, G = 80, B = 80};
    public static Brush TextBoxBorderBrush = new SolidColorBrush(TextBoxBorderColor);

    public static Color ScrollBarBackgroundColor = new Color{A =255, R =40, G = 40, B =40};
    public static Brush ScrollBarBackgroundBrush = new SolidColorBrush(ScrollBarBackgroundColor);

    public static Color MouseOverBackgroundColor = new Color {A = 255, R = 50, G = 50, B = 50};
    public static Brush MouseOverBackgroundBrush = new SolidColorBrush(MouseOverBackgroundColor);

    public static Color MouseOverForegroundColor = new Color {A = 255, R = 60, G = 210, B = 255};
    public static Brush MouseOverForegroundBrush = new SolidColorBrush(MouseOverForegroundColor);

    public static Color ButtonBackgroundColor = new Color {A = 255, R = 55, G = 55, B = 55};
    public static Brush ButtonBackgroundBrush = new SolidColorBrush(ButtonBackgroundColor);

    public static Color ButtonMouseOverBackgroundColor = new Color {A = 255, R = 85, G = 85, B = 85};
    public static Brush ButtonMouseOverBackgroundBrush = new SolidColorBrush(ButtonMouseOverBackgroundColor);

    public static Color OperationButtonColor = new Color {A = 255, R = 0, G = 120, B = 220};
    public static Brush OperationButtonBrush = new SolidColorBrush(OperationButtonColor);

    public static Color OperationButtonMouseOverBackgroundColor = new Color {A = 255, R = 10, G = 140, B = 240};
    public static Brush OperationButtonMouseOverBackgroundBrush = new SolidColorBrush(OperationButtonMouseOverBackgroundColor);

    public static Color ToggleButtonBackgroundColor = new Color {A = 255, R = 80, G = 80, B = 80};
    public static Brush ToggleButtonBackgroundBrush = new SolidColorBrush(ToggleButtonBackgroundColor);

    public static Color ToggleButtonMouseOverBackgroundColor = new Color {A = 255, R = 90, G = 90, B = 90};
    public static Brush ToggleButtonMouseOverBackgroundBrush = new SolidColorBrush(ToggleButtonMouseOverBackgroundColor);

    public static Color ToggleButtonEnabledBackgroundColor = new Color {A = 255, R = 0, G = 120, B = 220};
    public static Brush ToggleButtonEnabledBackgroundBrush = new SolidColorBrush(ToggleButtonEnabledBackgroundColor);

    public static Color ToggleButtonEnabledMouseOverBackgroundColor = new Color {A = 255, R = 10, G = 140, B = 240};
    public static Brush ToggleButtonEnabledMouseOverBackgroundBrush = new SolidColorBrush(ToggleButtonEnabledMouseOverBackgroundColor);

    public static FontFamily IconFontFamily = new FontFamily("Segoe MDL2 Assets");
    public static FontFamily textFontFamily = new FontFamily("Meiryo");

    public static DoubleAnimation ToggleOnXAnimation = new DoubleAnimation{
        From = 0.0,
        To = 20.0,
        Duration = new Duration(TimeSpan.FromMilliseconds(200.0))
    };

    public static DoubleAnimation ToggleOffXAnimation = new DoubleAnimation{
        From = 20.0,
        To = 0.0,
        Duration = new Duration(TimeSpan.FromMilliseconds(200.0))
    };
    
    static Paint()
    {
        Storyboard.SetTargetName(ToggleOnXAnimation, "ToggleSwitchTransform");
        Storyboard.SetTargetProperty(ToggleOnXAnimation, new PropertyPath(TranslateTransform.XProperty));

        Storyboard.SetTargetName(ToggleOffXAnimation, "ToggleSwitchTransform");
        Storyboard.SetTargetProperty(ToggleOffXAnimation, new PropertyPath(TranslateTransform.XProperty));
    }

}
#endregion

#region MainWindow
public class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
        Data.OnCurrentDirectoryChanged();
    }

    private void InitializeComponent()
    {
        this.Title = "Zone.Identifier Checker";
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
}
#endregion

#region MainGrid
class MainGrid : Grid
{
    private OperationPanel _opPanel;
    public MainGrid()
    {
        this.RowDefinitions.Add(new RowDefinition{Height = new GridLength(60.0)});
        this.RowDefinitions.Add(new RowDefinition{Height = new GridLength(50.0)});
        this.RowDefinitions.Add(new RowDefinition{MinHeight = 20.0});
        this.RowDefinitions.Add(new RowDefinition{Height = new GridLength(25.0)});

        var naviPanel = new NavigatePanel();
        SetRow(naviPanel, 0);
        var filerPanel = new FilerPanel();
        SetRow(filerPanel, 2);
        this._opPanel = new OperationPanel(filerPanel);
        SetRow(this._opPanel, 1);
        var statusBar = new CustomStatusBar();
        SetRow(statusBar, 3);

        this.Children.Add(naviPanel);
        this.Children.Add(this._opPanel);
        this.Children.Add(filerPanel);
        this.Children.Add(statusBar);

        filerPanel.SelectionChanged += new SelectionChangedEventHandler(FilerPanel_SelectionChanged);
    }

    private void FilerPanel_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        //Console.WriteLine("FilerPanel_SelectionChanged");
        try {
            FilerPanel filerPanel = (FilerPanel)sender;
            if (0 == filerPanel.SelectedItems.Count)
            {
                this._opPanel.SetSelectedItemText(String.Empty, String.Empty);
            }
            else if (1 == filerPanel.SelectedItems.Count)
            {
                string nameText = ((FileSystemInfoEntry)filerPanel.SelectedItem).Name;
                this._opPanel.SetSelectedItemText(nameText, String.Empty);
            }
            else
            {
                string nameText = String.Format("{0} ...", ((FileSystemInfoEntry)filerPanel.SelectedItem).Name);
                string countText = String.Format(" Total {0} items", (filerPanel.SelectedItems.Count));
                this._opPanel.SetSelectedItemText(nameText, countText);
            }
        } catch (Exception exc) {
            Console.WriteLine(exc.Message);
        }
    }
}
#endregion MainGrid

#region OperationPanel
class OperationPanel : Grid
{
    private TextBlock _selectedItemNameTextBlock;
    private TextBlock  _selectedItemsCountTextBlock;
    private FilerPanel _filer;
    private bool _recurseMode = false;

    public OperationPanel(FilerPanel filer)
    {
        this._filer = filer;
        this.Margin = new Thickness{Left = 10.0, Right = 10.0, Top = 5.0, Bottom = 5.0};
        this.ColumnDefinitions.Add(new ColumnDefinition{Width = GridLength.Auto});
        this.ColumnDefinitions.Add(new ColumnDefinition{Width = new GridLength(1.0, GridUnitType.Star)});
        this.ColumnDefinitions.Add(new ColumnDefinition{Width = GridLength.Auto});
        this.ColumnDefinitions.Add(new ColumnDefinition{Width = GridLength.Auto});

        var label = new Label{
            Content = "Selected items :",
            FontSize = 17.0,
            Foreground = Paint.ForegroundBrush,
            Margin = new Thickness{Left = 10.0, Right = 10.0},
            VerticalAlignment = VerticalAlignment.Center
        };
        SetColumn(label, 0);

        this._selectedItemsCountTextBlock = new TextBlock{
            FontSize = 17.0,
            Foreground = Paint.ForegroundBrush,
            VerticalAlignment = VerticalAlignment.Center,
        };
        DockPanel.SetDock(this._selectedItemsCountTextBlock, Dock.Right);

        this._selectedItemNameTextBlock = new TextBlock{
            FontSize = 17.0,
            Foreground = Paint.ForegroundBrush,
            VerticalAlignment = VerticalAlignment.Center,
            TextTrimming = TextTrimming.CharacterEllipsis,
        };
        DockPanel.SetDock(this._selectedItemNameTextBlock, Dock.Left);

        var dockPanel = new DockPanel{
            HorizontalAlignment = HorizontalAlignment.Left,
            LastChildFill = false
        };

        dockPanel.Children.Add(this._selectedItemsCountTextBlock);
        dockPanel.Children.Add(this._selectedItemNameTextBlock);

        var border = new Border{
            Margin = new Thickness{Left = 10.0, Right = 10.0},
            BorderThickness = new Thickness{Bottom = 1.0},
            BorderBrush = Paint.ForegroundBrush,
            Child = dockPanel,
        };
        SetColumn(border, 1);

        var removeZoneIdButton = new CustomButton("Unblock"){
            Margin = new Thickness{Left = 10.0, Right = 10.0, Top = 2.0, Bottom = 2.0}
        };
        SetColumn(removeZoneIdButton, 2);
        removeZoneIdButton.Click += new RoutedEventHandler(RemoveZoneIdButton_Click);

        var recurseToggleButton = new CustomToggleButton("Recurse"){
            Padding = new Thickness{Left = 10.0, Right = 10.0},
            Margin = new Thickness{Left = 10.0, Right = 10.0}
        };
        this._recurseMode = recurseToggleButton.ToggleState;
        SetColumn(recurseToggleButton, 3);
        recurseToggleButton.Click += new RoutedEventHandler(RecurseToggleButton_Click);

        this.Children.Add(label);
        this.Children.Add(border);
        this.Children.Add(removeZoneIdButton);
        this.Children.Add(recurseToggleButton);
    }

    private void RemoveZoneIdButton_Click(object sender, RoutedEventArgs e)
    {
        Data.OnRequestRemoveZoneId(this._filer, this._recurseMode);
    }

    private void RecurseToggleButton_Click(object sender, RoutedEventArgs e)
    {
        try
        {
            this._recurseMode = ((CustomToggleButton)sender).Toggle();
        }
        catch (Exception excp)
        {
            Console.WriteLine(excp.Message);
        }
    }

    public void SetSelectedItemText(string nameText, string countText)
    {
        this._selectedItemsCountTextBlock.Text = countText;
        this._selectedItemNameTextBlock.Text = nameText;
    }
}
#endregion OperationPanel

#region CustomButton
public class CustomButton : ButtonBase
{
    public CustomButton(string caption)
    {
        this.Template = CreateControlTemplate(caption);
        this.Cursor = Cursors.Hand;
    }

    private static ControlTemplate CreateControlTemplate(string caption)
    {
        var textBlock = new FrameworkElementFactory(typeof(TextBlock));
        textBlock.SetValue(TextBlock.VerticalAlignmentProperty, VerticalAlignment.Center);
        textBlock.SetValue(TextBlock.FontSizeProperty, 17.0);
        textBlock.SetValue(TextBlock.TextAlignmentProperty, TextAlignment.Center);
        textBlock.SetValue(TextBlock.ForegroundProperty, Paint.ForegroundBrush);
        textBlock.SetValue(TextBlock.TextProperty, caption);
        
        var border = new FrameworkElementFactory(typeof(Border), "border");
        border.SetValue(Border.PaddingProperty, new Thickness(35.0, 0.0, 35.0, 0.0));
        border.SetValue(Border.CornerRadiusProperty, new CornerRadius(4.0));
        border.SetValue(Border.BackgroundProperty, Paint.OperationButtonBrush);

        border.AppendChild(textBlock);

        var template = new ControlTemplate{
            VisualTree = border
        };

        var mouseOverTrigger = new MultiTrigger();
        mouseOverTrigger.Conditions.Add(new Condition(CustomButton.IsMouseOverProperty, true));
        mouseOverTrigger.Conditions.Add(new Condition(CustomButton.IsMouseCapturedProperty, false));
        mouseOverTrigger.Setters.Add(new Setter(Border.BackgroundProperty, Paint.OperationButtonMouseOverBackgroundBrush, "border"));
        template.Triggers.Add(mouseOverTrigger);

        return template;
    }
}
#endregion CustomButton

#region CustomToggleButton
public class CustomToggleButton : ButtonBase
{
    private bool _toggleSwitch = false;
    public bool ToggleState{ get { return this._toggleSwitch; }}
    private Border _border;
    private TranslateTransform _toggleSwitchTransform = new TranslateTransform();
    private Storyboard _toggleOnAnimationStoryboard = new Storyboard();
    private Storyboard _toggleOffAnimationStoryboard = new Storyboard();

    public CustomToggleButton(string caption)
    {
        InitializeComponent(caption);
        this.Cursor = Cursors.Hand;

        NameScope.SetNameScope(this, new NameScope());
        this.RegisterName("ToggleSwitchTransform", this._toggleSwitchTransform);

        this._toggleOnAnimationStoryboard.Children.Add(Paint.ToggleOnXAnimation);
        this._toggleOffAnimationStoryboard.Children.Add(Paint.ToggleOffXAnimation);

        this.MouseEnter += new MouseEventHandler(CustomToggleButton_MouseEnter);
        this.MouseLeave += new MouseEventHandler(CustomToggleButton_MouseLeave);
    }

    private void InitializeComponent(string caption)
    {
        var toggle = new Border{
            Height = 16.0,
            Width = 16.0,
            VerticalAlignment = VerticalAlignment.Center,
            HorizontalAlignment = HorizontalAlignment.Left,
            Margin = new Thickness{Top = 1.0, Left = 2.0, Right = 2.0},
            CornerRadius = new CornerRadius(8.5),
            Background = Paint.ForegroundBrush,
            RenderTransform = this._toggleSwitchTransform,
        };
        
        this._border = new Border{
            Height = 20.0,
            Width = 40.0,
            CornerRadius = new CornerRadius(10.0),
            Background = Paint.ToggleButtonBackgroundBrush,
        };
        this._border.Child = toggle;

        var textBlock = new TextBlock{
            Padding = new Thickness(15.0, 10.0, 15.0, 10.0),
            VerticalAlignment = VerticalAlignment.Center,
            FontSize = 16.0,
            TextAlignment = TextAlignment.Center,
            Foreground = Paint.ForegroundBrush,
            Text = caption,
        };

        var stackPanel = new StackPanel{
            Orientation = Orientation.Horizontal
        };

        stackPanel.Children.Add(textBlock);
        stackPanel.Children.Add(this._border);

        this.Content = stackPanel;
    }

    private void CustomToggleButton_MouseEnter(object sender, MouseEventArgs e)
    {
        if (this._toggleSwitch) {
            this._border.Background = Paint.ToggleButtonEnabledMouseOverBackgroundBrush;
        } else {
            this._border.Background = Paint.ToggleButtonMouseOverBackgroundBrush;
        }
    }

    private void CustomToggleButton_MouseLeave(object sender, MouseEventArgs e)
    {
        if (this._toggleSwitch) {
            this._border.Background = Paint.ToggleButtonEnabledBackgroundBrush;
        } else {
            this._border.Background = Paint.ToggleButtonBackgroundBrush;
        }
    }


    public bool Toggle()
    {
        if (this._toggleSwitch)
        {
            //Console.WriteLine("Off");
            this._toggleSwitch = false;
            this._toggleOffAnimationStoryboard.Begin(this);
            if (this.IsMouseOver)
                this._border.Background = Paint.ToggleButtonMouseOverBackgroundBrush;
            else
                this._border.Background = Paint.ToggleButtonBackgroundBrush;
        } else {
            //Console.WriteLine("On");
            this._toggleSwitch = true;
            this._toggleOnAnimationStoryboard.Begin(this);
            if (this.IsMouseOver)
                this._border.Background = Paint.ToggleButtonEnabledMouseOverBackgroundBrush;
            else
                this._border.Background = Paint.ToggleButtonEnabledBackgroundBrush;
        }
        return this._toggleSwitch;
    }
}
#endregion CustomToggleButton

#region NavigatePanel
class NavigatePanel : DockPanel, INotifyPropertyChanged
{
    public event PropertyChangedEventHandler PropertyChanged = (sender, e) => { };
    private BindingExpression _textBoxBindingExpression;

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

    private Visibility loadButtonVisibility = Visibility.Collapsed;
    public Visibility LoadButtonVisibility
    {
        get { return this.loadButtonVisibility; }
        set
        {
            this.loadButtonVisibility = value;
            PropertyChanged.Invoke(this, new PropertyChangedEventArgs("LoadButtonVisibility"));
        }
    }

    private Visibility reloadButtonVisibility = Visibility.Visible;
    public Visibility ReloadButtonVisibility
    {
        get { return this.reloadButtonVisibility; }
        set
        {
            this.reloadButtonVisibility = value;
            PropertyChanged.Invoke(this, new PropertyChangedEventArgs("ReloadButtonVisibility"));
        }
    }

    private void OnCurrentDirectoryChanging()
    {
        if (Directory.Exists(this._strCurrentDirectory)) {
            Data.CurrentDirectory = new DirectoryInfo(this._strCurrentDirectory);
        }
    }

    public NavigatePanel()
    {
        InitializeComponent();
        this.Margin = new Thickness{Left = 5.0, Right = 15.0};

        Data.CurrentDirectoryChanged += new PropertyChangedEventHandler(Data_CurrentDirectoryChanged);
    }

    private void NavigatePanel_GotKeyboardFocus(object sender, KeyboardFocusChangedEventArgs e)
    {
        this.LoadButtonVisibility = Visibility.Visible;
        this.ReloadButtonVisibility = Visibility.Collapsed;
    }

    private void NavigatePanel_LostKeyboardFocus(object sender, KeyboardFocusChangedEventArgs e)
    {
        this.LoadButtonVisibility = Visibility.Collapsed;
        this.ReloadButtonVisibility = Visibility.Visible;
    }

    private void Data_CurrentDirectoryChanged(object sender, PropertyChangedEventArgs e)
    {
        PropertyChanged.Invoke(this, new PropertyChangedEventArgs("StrCurrentDirectory"));
    }

    private void InitializeComponent()
    {
        var textBox = new TextBox{
            Template = CreateTextBoxTemplate(),
            Margin = new Thickness{Left = 10.0},
            CaretBrush = Paint.ForegroundBrush,
            Foreground = Paint.ForegroundBrush,
            FontSize = 16.0,
        };
        SetDock(textBox, Dock.Left);
        var textBoxBinding = new Binding("StrCurrentDirectory"){
            Source = this,
            Mode = BindingMode.TwoWay,
            UpdateSourceTrigger = UpdateSourceTrigger.Explicit,
        };
        textBox.SetBinding(TextBox.TextProperty, textBoxBinding);
        this._textBoxBindingExpression = BindingOperations.GetBindingExpression(textBox, TextBox.TextProperty);
        textBox.KeyDown += new KeyEventHandler(TextBox_KeyDown);
        textBox.GotKeyboardFocus += new KeyboardFocusChangedEventHandler(NavigatePanel_GotKeyboardFocus);
        textBox.LostKeyboardFocus += new KeyboardFocusChangedEventHandler(NavigatePanel_LostKeyboardFocus);

        var reloadButton = new TileButton{
            Content = "\uE149",
            Margin = new Thickness{Left = 0.0, Right = 2.0},
        };
        SetDock(reloadButton, Dock.Right);
        var reloadButtonVisibilityBinding = new Binding("ReloadButtonVisibility"){
            Source = this
        };
        reloadButton.SetBinding(ButtonBase.VisibilityProperty, reloadButtonVisibilityBinding);
        reloadButton.Click += new RoutedEventHandler(ReloadButton_Click);

        var inlinePanel = new DockPanel();
        inlinePanel.Children.Add(reloadButton);
        inlinePanel.Children.Add(textBox);

        var border = new Border{
            BorderThickness = new Thickness(1.0),
            BorderBrush = Paint.TextBoxBorderBrush,
            Height = 38.0,
            CornerRadius = new CornerRadius(19.0)
        };
        border.Child = inlinePanel;

        var leftArrowButton = new TileButton{
            Content = "\uF0B0",
            Margin = new Thickness{Left = 10.0, Right = 5.0},
        };
        leftArrowButton.Click += new RoutedEventHandler(LeftArrowButton_Click);

        var rightArrowButton = new TileButton{
            Content = "\uF0AF",
            Margin = new Thickness{Left = 5.0, Right = 5.0},
        };
        rightArrowButton.Click += new RoutedEventHandler(RightArrowButton_Click);

        var upArrowButton = new TileButton{
            Content = "\uF0AD",
            Margin = new Thickness{Left = 5.0, Right = 10.0},
        };
        upArrowButton.Click += new RoutedEventHandler(UpArrowButton_Click);

        var stackPanel = new StackPanel{
            Orientation = Orientation.Horizontal,
        };
        stackPanel.Children.Add(leftArrowButton);
        stackPanel.Children.Add(rightArrowButton);
        stackPanel.Children.Add(upArrowButton);
        SetDock(stackPanel, Dock.Left);

        this.Children.Add(stackPanel);
        this.Children.Add(border);
    }

    private ControlTemplate CreateTextBoxTemplate()
    {
        var contentHost = new FrameworkElementFactory(typeof(ScrollViewer), "PART_ContentHost");
        contentHost.SetValue(ScrollViewer.VerticalAlignmentProperty, VerticalAlignment.Center);
        contentHost.SetValue(ScrollViewer.MarginProperty, new Thickness(0.0));
        contentHost.SetValue(ScrollViewer.VerticalContentAlignmentProperty, VerticalAlignment.Center);
        contentHost.SetValue(DockPanel.DockProperty, Dock.Left);

        var loadButton = new FrameworkElementFactory(typeof(TileButton));
        loadButton.SetValue(ButtonBase.ContentProperty, "\uF0AF");
        loadButton.SetValue(ButtonBase.MarginProperty,new Thickness{Left = 0.0, Right = 2.0});
        loadButton.SetValue(DockPanel.DockProperty, Dock.Right);

        var loadButtonVisibilityBinding = new Binding("LoadButtonVisibility"){
            Source = this
        };
        loadButton.SetBinding(ButtonBase.VisibilityProperty, loadButtonVisibilityBinding);
        loadButton.AddHandler(ButtonBase.ClickEvent, new RoutedEventHandler(LoadButton_Click));

        var dockPanel = new FrameworkElementFactory(typeof(DockPanel));
        dockPanel.AppendChild(loadButton);
        dockPanel.AppendChild(contentHost);

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

    private void ReloadButton_Click(object sender, RoutedEventArgs e)
    {
        try {
            Data.OnCurrentDirectoryChanged();
        } catch { }
    }

    private void LoadButton_Click(object sender, RoutedEventArgs e)
    {
        RequestLoad();
    }

    private void TextBox_KeyDown(object sender, KeyEventArgs e)
    {
        if (e.Key == Key.Enter)
        {
            RequestLoad();
        }
    }

    private void RequestLoad()
    {
        try {
            this._textBoxBindingExpression.UpdateSource();
            Keyboard.ClearFocus();
        } catch { }
    }
}
#endregion NavigatePanel

#region TileButton
class TileButton : ButtonBase, INotifyPropertyChanged
{
    public Brush _backgroundBrush = Brushes.Transparent;
    public Brush BackgroundBrush
    {
        get { return this._backgroundBrush; }
        set { this._backgroundBrush = value; OnPropertyChanged("BackgroundBrush"); }
    }

    static TileButton()
    {
        DependencyProperty.Register("VisibilityConverter", typeof(bool), typeof(TileButton));
    }

    public TileButton()
    {
        this.Template = CreateTileButtonTemplate();
        this.VerticalAlignment = VerticalAlignment.Center;
        this.Foreground = Paint.ForegroundBrush;
        this.FontFamily = Paint.IconFontFamily;
        //this.FontWeight = FontWeights.Medium;
        this.FontSize = 17.0;
        this.Cursor = Cursors.Hand;
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

    private void TileButton_MouseEnter(object sender, MouseEventArgs e)
    {
        this.BackgroundBrush = Paint.MouseOverBackgroundBrush;
        this.Foreground = Paint.MouseOverForegroundBrush;
    }

    private void TileButton_MouseLeave(object sender, MouseEventArgs e)
    {
        this.BackgroundBrush = Brushes.Transparent;
        this.Foreground = Paint.ForegroundBrush;
    }

    public event PropertyChangedEventHandler PropertyChanged = (sender, e) => { };

    private void OnPropertyChanged(string info)
    {
        PropertyChanged.Invoke(this, new PropertyChangedEventArgs(info));
    }
}
#endregion TileButton

#region FilerPanel
public class FilerPanel : DataGrid
{
    private object _lockObject = new object();
    public FilerPanel()
    {
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
            Source = Data.FileInfoCollectionView
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
            CanUserSort = true,
            SortMemberPath = "Name"
        });

        this.Columns.Add(new DataGridTemplateColumn{
            Header = "Zone.Identifier",
            CellTemplate = CreateZoneIdCellTemplate(),
            Width = new DataGridLength(150.0),
            MinWidth = 50.0,
            IsReadOnly = true,
            CanUserSort = true,
            SortMemberPath = "HasZoneId"
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

    private static DataTemplate CreateNameCellTemplate()
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

    private static DataTemplate CreateZoneIdCellTemplate()
    {
        var check = new FrameworkElementFactory(typeof(TextBlock));
        check.SetValue(TextBlock.TextProperty, new Binding("HasZoneIdIcon"));
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

    private static Style CreateColumnHeaderStyle()
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

    private static Style CreateCellStyle()
    {
        var style = new Style();
        style.Setters.Add(new Setter(Control.BorderThicknessProperty, new Thickness(0.0)));
        //style.Setters.Add(new Setter(Control.PaddingProperty, new Thickness{Left = 10.0, Right = 10.0}));
        return style;
    }

    private static Style CreateItemContainerStyle()
    {
        var style = new Style();
        style.Setters.Add(new Setter(Control.BackgroundProperty, Brushes.Transparent));
        style.Setters.Add(new Setter(Control.HeightProperty, 40.0));
        //style.Setters.Add(new Setter(Control.MarginProperty, new Thickness{Top = 1.0, Bottom = 1.0}));
        return style;
    }

    private static Style CreateTextBlockStyle()
    {
        var style = new Style();
        style.Setters.Add(new Setter(TextBlock.MarginProperty, new Thickness{Left = 5.0}));
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

    public event PropertyChangedEventHandler PropertyChanged = (sender, e) => { };

    private void OnPropertyChanged(string info)
    {
        PropertyChanged.Invoke(this, new PropertyChangedEventArgs(info));
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

    public bool HasZoneId
    {
        get { return this._hasZoneId; }
        set
        {
            this._hasZoneId = value;
            OnPropertyChanged("HasZoneIdIcon");
        }
    }

    public string HasZoneIdIcon
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

#region Shell
public static class Shell
{
    private static readonly IntPtr STATUS_BUFFER_OVERFLOW = (IntPtr)0x80000005;
    private static readonly int SIZE_SHFILEINFO = Marshal.SizeOf(typeof(SHFILEINFO));

    [DllImport("ntdll.dll", CharSet=CharSet.Auto)]
    private static extern IntPtr NtQueryInformationFile(SafeFileHandle fileHandle, out IO_STATUS_BLOCK IoStatusBlock, IntPtr pInfoBlock, int length, FILE_INFORMATION_CLASS fileInformation);  

    [DllImport("shell32.dll", CharSet=CharSet.Auto)]
    private static extern IntPtr SHGetFileInfo(string pszPath, FileAttributes dwFileAttributes, out SHFILEINFO psfi, int cbFileInfo, SHGFI uFlags);
    
    [DllImport("shell32.dll", CharSet=CharSet.Auto)]
    private static extern uint ExtractIconEx(string szFileName, int nIconIndex, IntPtr phiconLarge, out IntPtr phiconSmall, int nIcons);
    
    [DllImport("user32.dll", EntryPoint="DestroyIcon")]
    private static extern int DestroyIcon(IntPtr hIcon);

    private struct IO_STATUS_BLOCK {
        internal uint status;
        internal ulong information;
    }

    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
    private struct FILE_STREAM_INFORMATION {
        internal int NextEntryOffset;
        internal int StreamNameLength;
        internal ulong StreamSize;
        internal ulong StreamAllocationSize;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)]
        internal string StreamName;
    }

    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Auto)]
    private struct SHFILEINFO
    {
        internal IntPtr hIcon;
        internal int iIcon;
        internal uint dwAttributes;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst=260)]
        internal string szDisplayName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst=80)]
        internal string szTypeName;
    };

    enum SHGFI : uint
    {
        Icon         = 0x000000100,
        LargeIcon    = 0x000000000,
        SmallIcon    = 0x000000001,
        UseFileAttributes= 0x000000010,  
    }

    enum FILE_INFORMATION_CLASS {
        FileDirectoryInformation = 1,
        FileStreamInformation = 22,
    }

    public static bool CheckZoneId(string path) {
        bool result = false;
        FileStream fs = null;
        try {
            fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Delete);
        } catch {
            return false;
        }

        IntPtr buffer = IntPtr.Zero;
        try {
            IO_STATUS_BLOCK iosb = new IO_STATUS_BLOCK();
            FILE_STREAM_INFORMATION fsi = new FILE_STREAM_INFORMATION();
            for (int i = 1; i < 256; i++)
            {
                //Console.WriteLine(String.Format("Loop {0}", i));
                buffer = Marshal.AllocCoTaskMem(1024 * i);
                IntPtr iprc = NtQueryInformationFile(fs.SafeFileHandle, out iosb, buffer, (1024 * i), FILE_INFORMATION_CLASS.FileStreamInformation);
                if (iprc == STATUS_BUFFER_OVERFLOW)
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
                for (int i = 0; i < 256; i++)
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
#endregion Shell

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

#region RequestRemoveZoneIdEventArgs
public class RequestRemoveZoneIdEventArgs : EventArgs
{
    public List<FileSystemInfoEntry> FileSystemInfoList;
    public bool Recurse;

    public RequestRemoveZoneIdEventArgs(List<FileSystemInfoEntry> fsiList, bool recurse)
    {
        this.FileSystemInfoList = fsiList;
        this.Recurse = recurse;
    }
}
#endregion

#region Data
public static class Data
{
    public static ObservableCollection<FileSystemInfoEntry> FileInfoCollection;
    public static CollectionViewSource FileInfoCollectionView;
    public static object _lockObject;
    public static CancellationTokenSource cTokenSource = null;

    static Data()
    {
        _lockObject = new object();
        FileInfoCollection = new ObservableCollection<FileSystemInfoEntry>();
        FileInfoCollectionView = new CollectionViewSource{
            Source = FileInfoCollection,
            IsLiveSortingRequested = true,
        };
        FileInfoCollectionView.SortDescriptions.Add(new SortDescription(AppSettings.DefaultSortProperty, AppSettings.DefaultSortDirection));
        BindingOperations.EnableCollectionSynchronization(FileInfoCollection, _lockObject);
    }

    public static DirectoryInfo _currentDirectory = new DirectoryInfo(AppSettings.DefaultFolder);
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

    public delegate void RequestRemoveZoneIdEventHandler(object sender, RequestRemoveZoneIdEventArgs e);
    public static event RequestRemoveZoneIdEventHandler RequestRemoveZoneId = (sender, e) => { };

    public static void OnRequestRemoveZoneId(FilerPanel filer, bool recurseMode)
    {
        if (0 == filer.SelectedItems.Count)
        {
            return;
        }
        else if (0 < filer.SelectedItems.Count)
        {
            List<FileSystemInfoEntry> fsiList = new List<FileSystemInfoEntry>();
            foreach (FileSystemInfoEntry entry in filer.SelectedItems) {
                fsiList.Add(entry);
            }
            var ev = new RequestRemoveZoneIdEventArgs(fsiList, recurseMode);
            RequestRemoveZoneId.Invoke(filer, ev);
        }
    }
}
#endregion

#region AppSettings
static public class AppSettings
{
    [DllImport("shell32.dll", CharSet=CharSet.Auto)]
    private static extern int SHGetKnownFolderPath([MarshalAs(UnmanagedType.LPStruct)] Guid rfid, uint dwFlags, IntPtr hToken, out string pszPath);
    private static readonly Guid Downloads = new Guid("374DE290-123F-4565-9164-39C4925E467B");

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

    private static string _defaultSortProperty = ConfigurationManager.AppSettings["DefaultSortProperty"];
    public static string DefaultSortProperty
    {
        get
        {
            if (null == _defaultSortProperty) {
                _defaultSortProperty = "LastWriteTime";
            }
            return _defaultSortProperty;
        }
    }

    private static string _defaultSortDirection = ConfigurationManager.AppSettings["DefaultSortDirection"];
    public static ListSortDirection DefaultSortDirection
    {
        get
        {
            if (null == _defaultSortDirection)
            {
                return ListSortDirection.Descending;
            }
            else if ("Ascending" == _defaultSortDirection.Trim())
            {
                return ListSortDirection.Ascending;
            } else
            {
                return ListSortDirection.Descending;
            }
        }
    }

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

    private static string _defaultFolder = ConfigurationManager.AppSettings["DefaultFolder"];
    public static string DefaultFolder{
        get
        {
            if (null == _defaultFolder) {
                _defaultFolder = DownloadFolder;
            }
            return _defaultFolder;
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
    #$MainWindow.SetCurrentDirectory([AppSettings]::DownloadFolder)

    [Data]::add_RequestRemoveZoneId({
        Param($s, $e)
        foreach ($entry in $e.FileSystemInfoList)
        {
            try
            {
                if ($false -eq $entry.IsDirectory)
                {
                    Unblock-File -LiteralPath $entry.Path -ErrorAction SilentlyContinue
                }
                elseif (($true -eq $e.Recurse) -and $entry.IsDirectory)
                {
                    $Items = Get-ChildItem -LiteralPath $entry.Path -Recurse
                    Unblock-File -LiteralPath $Items.FullName -ErrorAction SilentlyContinue
                }
            }
            catch
            {
                Write-Host $_.Exception.Message -f Red
            }
            finally
            {
                $entry.HasZoneId = [Shell]::CheckZoneId($entry.Path)
            }
        }



        #[Data]::OnCurrentDirectoryChanged()
    })

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

