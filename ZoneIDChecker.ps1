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
# C# Section
Try {
    [void][MainWindow]
} Catch {
Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Text;
using System.Drawing;
using System.Windows;
using System.Windows.Shapes;
using System.Windows.Input;
using System.Windows.Data;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Media.Imaging;
using System.Windows.Media.Effects;
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
using System.Collections.Specialized;
using System.Dynamic;
using System.Threading.Tasks;
using System.Linq;

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
        this.Background = Theme.BackgroundBrush;
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
        this.RowDefinitions.Add(new RowDefinition{Height = new GridLength(30.0)});

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
                Data.StatusContent["SelectedItemsCount"].Text = String.Empty;
            }
            else if (1 == filerPanel.SelectedItems.Count)
            {
                string nameText = ((FileSystemInfoEntry)filerPanel.SelectedItem).Name;
                this._opPanel.SetSelectedItemText(nameText, String.Empty);
                Data.StatusContent["SelectedItemsCount"].Text = "1 item selected";
            }
            else
            {
                string nameText = String.Format("{0} ...", ((FileSystemInfoEntry)filerPanel.SelectedItem).Name);
                string countText = String.Format(" Total {0} items", (filerPanel.SelectedItems.Count));
                this._opPanel.SetSelectedItemText(nameText, countText);
                Data.StatusContent["SelectedItemsCount"].Text = String.Format("{0} items selected", (filerPanel.SelectedItems.Count));
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
            Foreground = Theme.ForegroundBrush,
            Margin = new Thickness{Left = 10.0, Right = 10.0},
            VerticalAlignment = VerticalAlignment.Center
        };
        SetColumn(label, 0);

        this._selectedItemsCountTextBlock = new TextBlock{
            FontSize = 17.0,
            Foreground = Theme.ForegroundBrush,
            VerticalAlignment = VerticalAlignment.Center,
        };
        DockPanel.SetDock(this._selectedItemsCountTextBlock, Dock.Right);

        this._selectedItemNameTextBlock = new TextBlock{
            FontSize = 17.0,
            Foreground = Theme.ForegroundBrush,
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
            BorderBrush = Theme.ForegroundBrush,
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

#region RootDirectoryListComboBox
class RootDirectoryListComboBox : ComboBox
{
    public RootDirectoryListComboBox()
    {
        this.ItemsSource = Data.RootDirectoryCollection;
        this.Template = CreateTemplate();
        this.ItemTemplate = CreateItemTemplate();
        this.ItemContainerStyle = CreateItemContainerStyle();
        this.FontSize = 16.0;
        this.SelectionChanged += (sender, e) => {
            try {
                var path = ((FileSystemInfoEntry)this.SelectedItem).Path;
                if (null != path && Directory.Exists(path))
                {
                    Data.CurrentDirectory =  new DirectoryInfo(path);
                }
            } catch { }
            this.SelectedIndex = -1;
        };
        AddHandler(UIElement.PreviewMouseDownEvent, new MouseButtonEventHandler(Popup_PreviewMouseDown));
    }

    private void Popup_PreviewMouseDown(object sender, MouseButtonEventArgs e)
    {
        var mainWindow = Window.GetWindow(this);
        Point relP = Mouse.GetPosition(mainWindow);
        var element = mainWindow.InputHitTest(relP);
        if (null == element) {
            this.IsDropDownOpen = false;
            Point absP = mainWindow.PointToScreen(relP);
            Win32.SendMouseDown((int)absP.X, (int)absP.Y);
        }
    }

    private static Style CreateItemContainerStyle()
    {
        var presenter = new FrameworkElementFactory(typeof(ContentPresenter));

        var border = new FrameworkElementFactory(typeof(Border));
        border.SetValue(Border.BackgroundProperty, new TemplateBindingExtension(ComboBoxItem.BackgroundProperty));
        border.AppendChild(presenter);

        var template = new ControlTemplate(typeof(ComboBoxItem)){
            VisualTree = border,
        };

        var style = new Style(typeof(ComboBoxItem));
        style.Setters.Add(new Setter(ComboBoxItem.TemplateProperty, template));

        var mouseOverTrigger = new Trigger{
            Property = ComboBoxItem.IsMouseOverProperty,
            Value = true,
        };
        mouseOverTrigger.Setters.Add(new Setter(ComboBoxItem.BackgroundProperty, Theme.ComboBoxMouseOverBackgroundBrush));
        style.Triggers.Add(mouseOverTrigger);

        return style;

    }

    private static DataTemplate CreateItemTemplate()
    {
        var icon = new FrameworkElementFactory(typeof(Image));
        icon.SetValue(Image.WidthProperty, 16.0);
        icon.SetValue(Image.HeightProperty, 16.0);
        icon.SetValue(Image.MarginProperty, new Thickness{Left = 5.0, Right = 5.0});
        icon.SetBinding(Image.SourceProperty, new Binding("Icon"));
        icon.SetValue(DockPanel.DockProperty, Dock.Left);

        var name = new FrameworkElementFactory(typeof(TextBlock));
        name.SetValue(TextBlock.MarginProperty, new Thickness{Left = 5.0, Right = 5.0});
        name.SetValue(TextBlock.MinWidthProperty, 150.0);
        name.SetValue(TextBlock.TextTrimmingProperty, TextTrimming.CharacterEllipsis);
        name.SetValue(TextBlock.ForegroundProperty, Theme.ForegroundBrush);
        name.SetValue(TextBlock.VerticalAlignmentProperty, VerticalAlignment.Center);
        name.SetBinding(TextBlock.TextProperty, new Binding("Name"));
        name.SetValue(DockPanel.DockProperty, Dock.Right);
        
        var dockPanel = new FrameworkElementFactory(typeof(DockPanel));
        dockPanel.AppendChild(icon);
        dockPanel.AppendChild(name);

        var template = new DataTemplate{
            VisualTree = dockPanel
        };

        return template;
    }

    private ControlTemplate CreateTemplate()
    {

        var directoryButton = new FrameworkElementFactory(typeof(DirectoryButton));
        var isOpenBinding = new Binding("IsDropDownOpen"){
            RelativeSource = RelativeSource.TemplatedParent,
            Mode = BindingMode.TwoWay,
        };
        directoryButton.SetBinding(DirectoryButton.IsCheckedProperty, isOpenBinding);

        var stackPanel = new FrameworkElementFactory(typeof(StackPanel), "ItemsPresenter");
        stackPanel.SetValue(StackPanel.IsItemsHostProperty, true);

        var scrollViewer = new FrameworkElementFactory(typeof(ScrollViewer));
        scrollViewer.AppendChild(stackPanel);

        var border = new FrameworkElementFactory(typeof(Border), "DropDownBorder");
        border.SetValue(Border.BackgroundProperty, Theme.ComboBoxBackgroundBrush);
        border.SetValue(Border.MarginProperty, new Thickness(15.0));
        border.SetValue(Border.BorderThicknessProperty, new Thickness(1.0));
        border.SetValue(Border.BorderBrushProperty, Theme.GrayBrush);
        /*var dropShadowEffect = new DropShadowEffect
        {
            Color = Colors.Black,
            BlurRadius = 15.0,
            ShadowDepth = 0,
            Opacity = 0.65
        };
        border.SetValue(Popup.EffectProperty, dropShadowEffect);*/
        border.AppendChild(scrollViewer);
        
        var itemsGrid = new FrameworkElementFactory(typeof(Grid), "DropDown");
        itemsGrid.AppendChild(border);

        var popup = new FrameworkElementFactory(typeof(Popup), "PART_Popup");
        popup.SetValue(Popup.PlacementProperty, PlacementMode.Left);
        popup.SetValue(Popup.PlacementRectangleProperty, new Rect(0.0, 0.0, 0.0, 0.0));
        popup.SetValue(Popup.AllowsTransparencyProperty, true);
        var isPopupOpenBinding = new Binding("IsDropDownOpen"){
            RelativeSource = RelativeSource.TemplatedParent,
        };
        popup.SetBinding(Popup.IsOpenProperty, isPopupOpenBinding);
        popup.AppendChild(itemsGrid);

        var grid = new FrameworkElementFactory(typeof(Grid));
        grid.AppendChild(directoryButton);
        grid.AppendChild(popup);

        var ct = new ControlTemplate(typeof(RootDirectoryListComboBox)){
            VisualTree = grid,
        };
        return ct;
    }

}
#endregion

#region DirectoryButton
class DirectoryButton : ToggleButton, INotifyPropertyChanged
{
    public event PropertyChangedEventHandler PropertyChanged = (sender, e) => { };

    private BitmapSource _directoryIcon;
    public BitmapSource DirectoryIcon
    {
        get { return this._directoryIcon; }
        set { this._directoryIcon = value; PropertyChanged.Invoke(this, new PropertyChangedEventArgs("DirectoryIcon"));}
    }

    public DirectoryButton()
    {
        this.Cursor = Cursors.Hand;
        this.DirectoryIcon = Theme.SystemDriveIcon;
        this.Template = CreateTemplate();
        Data.CurrentDirectoryChanged += (sender, e) => {
            this.DirectoryIcon = Win32.GetIconBitmapSource(Data.CurrentDirectory.FullName, Data.CurrentDirectory.Attributes);
        };
    }

    protected override void OnRender(DrawingContext dc)
    {
        this.DirectoryIcon = Win32.GetIconBitmapSource(Data.CurrentDirectory.FullName, Data.CurrentDirectory.Attributes);
    }

    private ControlTemplate CreateTemplate()
    {
        var image = new FrameworkElementFactory(typeof(Image));
        image.SetValue(Image.WidthProperty, 20.0);
        image.SetValue(Image.HeightProperty, 20.0);
        image.SetValue(Image.VerticalAlignmentProperty, VerticalAlignment.Center);
        image.SetValue(Image.HorizontalAlignmentProperty, HorizontalAlignment.Center);

        var imageBinding = new Binding("DirectoryIcon"){
            Source = this
        };
        image.SetBinding(Image.SourceProperty, imageBinding);

        var border = new FrameworkElementFactory(typeof(Border), "border");
        border.SetValue(Border.CornerRadiusProperty, new CornerRadius(15.0));
        border.SetValue(Border.BackgroundProperty, Theme.DirectoryButtonBackgroundBrush);
        border.AppendChild(image);

        var ct = new ControlTemplate(typeof(DirectoryButton)){
            VisualTree = border,
        };

        var mouseOverTrigger = new Trigger{
            Property = DirectoryButton.IsMouseOverProperty,
            Value = true,
        };
        mouseOverTrigger.Setters.Add(new Setter(Border.BackgroundProperty, Theme.DirectoryButtonMouseOverBackgroundBrush, "border"));

        var isCheckedTrigger = new Trigger{
            Property = DirectoryButton.IsCheckedProperty,
            Value = true,
        };
        isCheckedTrigger.Setters.Add(new Setter(Border.BackgroundProperty, Theme.DirectoryButtonIsCheckedBackgroundBrush, "border"));

        ct.Triggers.Add(mouseOverTrigger);
        ct.Triggers.Add(isCheckedTrigger);

        return ct;
    }
}
#endregion

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
        textBlock.SetValue(TextBlock.ForegroundProperty, Theme.ForegroundBrush);
        textBlock.SetValue(TextBlock.TextProperty, caption);
        
        var border = new FrameworkElementFactory(typeof(Border), "border");
        border.SetValue(Border.PaddingProperty, new Thickness(35.0, 0.0, 35.0, 0.0));
        border.SetValue(Border.CornerRadiusProperty, new CornerRadius(4.0));
        border.SetValue(Border.BackgroundProperty, Theme.OperationButtonBrush);

        border.AppendChild(textBlock);

        var template = new ControlTemplate{
            VisualTree = border
        };

        var mouseOverTrigger = new MultiTrigger();
        mouseOverTrigger.Conditions.Add(new Condition(CustomButton.IsMouseOverProperty, true));
        mouseOverTrigger.Conditions.Add(new Condition(CustomButton.IsMouseCapturedProperty, false));
        mouseOverTrigger.Setters.Add(new Setter(Border.BackgroundProperty, Theme.OperationButtonMouseOverBackgroundBrush, "border"));
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

        this._toggleOnAnimationStoryboard.Children.Add(Theme.ToggleOnXAnimation);
        this._toggleOffAnimationStoryboard.Children.Add(Theme.ToggleOffXAnimation);

        this.MouseEnter += new MouseEventHandler(CustomToggleButton_MouseEnter);
        this.MouseLeave += new MouseEventHandler(CustomToggleButton_MouseLeave);
    }

    private void InitializeComponent(string caption)
    {
        var toggle = new Border{
            Height = 15.0,
            Width = 15.0,
            HorizontalAlignment = HorizontalAlignment.Left,
            Margin = new Thickness{Left = 3.0, Top = 1.0},
            CornerRadius = new CornerRadius(7.5),
            Background = Theme.ForegroundBrush,
            RenderTransform = this._toggleSwitchTransform,
        };
        
        this._border = new Border{
            Height = 20.0,
            Width = 40.0,
            CornerRadius = new CornerRadius(10.0),
            Background = Theme.ToggleButtonBackgroundBrush,
        };
        this._border.Child = toggle;

        var textBlock = new TextBlock{
            Padding = new Thickness(15.0, 10.0, 15.0, 10.0),
            VerticalAlignment = VerticalAlignment.Center,
            FontSize = 16.0,
            TextAlignment = TextAlignment.Center,
            Foreground = Theme.ForegroundBrush,
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
            this._border.Background = Theme.ToggleButtonEnabledMouseOverBackgroundBrush;
        } else {
            this._border.Background = Theme.ToggleButtonMouseOverBackgroundBrush;
        }
    }

    private void CustomToggleButton_MouseLeave(object sender, MouseEventArgs e)
    {
        if (this._toggleSwitch) {
            this._border.Background = Theme.ToggleButtonEnabledBackgroundBrush;
        } else {
            this._border.Background = Theme.ToggleButtonBackgroundBrush;
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
                this._border.Background = Theme.ToggleButtonMouseOverBackgroundBrush;
            else
                this._border.Background = Theme.ToggleButtonBackgroundBrush;
        } else {
            //Console.WriteLine("On");
            this._toggleSwitch = true;
            this._toggleOnAnimationStoryboard.Begin(this);
            if (this.IsMouseOver)
                this._border.Background = Theme.ToggleButtonEnabledMouseOverBackgroundBrush;
            else
                this._border.Background = Theme.ToggleButtonEnabledBackgroundBrush;
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
            Margin = new Thickness{Left = 5.0},
            CaretBrush = Theme.ForegroundBrush,
            Foreground = Theme.ForegroundBrush,
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

        var rootComboBox = new RootDirectoryListComboBox{
            Width = 30.0,
            Height = 30.0,
            Margin = new Thickness{Left = 2.0},
            VerticalAlignment = VerticalAlignment.Center,
        };
        SetDock(rootComboBox, Dock.Left);

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
        inlinePanel.Children.Add(rootComboBox);
        inlinePanel.Children.Add(reloadButton);
        inlinePanel.Children.Add(textBox);

        var border = new Border{
            BorderThickness = new Thickness(1.0),
            BorderBrush = Theme.TextBoxBorderBrush,
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

    private void RootButton_Click(object sender, RoutedEventArgs e)
    {
        try {
            Data.PrevDirectory();
        } catch { }
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

    public TileButton()
    {
        this.Template = CreateTileButtonTemplate();
        this.VerticalAlignment = VerticalAlignment.Center;
        this.Foreground = Theme.ForegroundBrush;
        this.FontFamily = Theme.IconFontFamily;
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
        this.BackgroundBrush = Theme.MouseOverBackgroundBrush;
        this.Foreground = Theme.MouseOverForegroundBrush;
    }

    private void TileButton_MouseLeave(object sender, MouseEventArgs e)
    {
        this.BackgroundBrush = Brushes.Transparent;
        this.Foreground = Theme.ForegroundBrush;
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

    private DataGridColumn _nameColumnn = new DataGridTemplateColumn{
        Header = "Name",
        CellTemplate = CreateNameCellTemplate(),
        Width = new DataGridLength(1.0, DataGridLengthUnitType.Star),
        MinWidth = 50.0,
        IsReadOnly = true,
        CanUserSort = true,
        SortMemberPath = "Name"
    };

    private DataGridColumn _hasZoneIdColumn = new DataGridTemplateColumn{
        Header = "Zone.Identifier",
        CellTemplate = CreateZoneIdCellTemplate(),
        Width = new DataGridLength(150.0),
        MinWidth = 50.0,
        IsReadOnly = true,
        CanUserSort = true,
        SortMemberPath = "HasZoneId"
    };

    private DataGridColumn _lastWriteTimeColumn = new DataGridTextColumn{
        Header = "LastWriteTime",
        Binding = new Binding("LastWriteTimeString"),
        Width = new DataGridLength(200.0),
        MinWidth = 50.0,
        ElementStyle = CreateTextBlockStyle(),
        IsReadOnly = true,
        CanUserSort = true,
        SortMemberPath = "LastWriteTime"
    };

    public FilerPanel()
    {
        this.Margin = new Thickness{Left = 5.0, Top = 15.0};
        this.Background = Brushes.Transparent;
        this.Foreground = Theme.ForegroundBrush;
        this.FontSize = 15.0;
        this.FontFamily = Theme.textFontFamily;
        this.BorderThickness = new Thickness(0.0);
        this.AutoGenerateColumns = false;
        this.HeadersVisibility = DataGridHeadersVisibility.Column;
        this.HorizontalScrollBarVisibility = ScrollBarVisibility.Disabled;
        this.VerticalScrollBarVisibility = ScrollBarVisibility.Visible;
        VirtualizingPanel.SetScrollUnit(this, ScrollUnit.Pixel);
        var sourceBinding = new Binding{
            Source = Data.FileInfoCollectionView,
        };
        this.SetBinding(FilerPanel.ItemsSourceProperty, sourceBinding);
        this.ItemContainerStyle = CreateItemContainerStyle();
        this.CellStyle = CreateCellStyle();
        this.ColumnHeaderStyle = CreateColumnHeaderStyle();
        this.GridLinesVisibility = DataGridGridLinesVisibility.Horizontal;
        this.HorizontalGridLinesBrush = Theme.GrayBorderBrush;
        this.ContextMenu = new CustomContextMenu();
        //ContextMenuService.SetPlacement(this, PlacementMode.Mouse);
        //ContextMenuService.SetHorizontalOffset(this, 200.0);

        this.Columns.Add(this._nameColumnn);
        this.Columns.Add(this._hasZoneIdColumn);
        this.Columns.Add(this._lastWriteTimeColumn);

        //this.Columns[2].SortDirection = ListSortDirection.Descending;
        //SortManager.FilerPanel = this;

        this.AddHandler(DataGridRow.PreviewMouseDoubleClickEvent, new MouseButtonEventHandler(DataGridRow_DoubleClick));

        this.Sorting += (sender, e) => {
            SortManager.lastSortedColumn = e.Column;
        };
    }

    protected override void OnRender(DrawingContext dc)
    {
        OnSorting(new DataGridSortingEventArgs(this.Columns[2]));
    }

    private void DataGridRow_DoubleClick(object sender, MouseButtonEventArgs e)
    {
        if (MouseButton.Left == e.ChangedButton)
        {
            try {
                var path = ((FileSystemInfoEntry)((FrameworkElement)e.OriginalSource).DataContext).Path;
                if (null == path)
                    return;
                
                if (Directory.Exists(path))
                {
                    Data.CurrentDirectory =  new DirectoryInfo(path);
                }
                else if (File.Exists(path))
                {
                    Process.Start(new ProcessStartInfo(path));
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
        check.SetValue(TextBlock.FontFamilyProperty, Theme.IconFontFamily);

        var template = new DataTemplate{
            VisualTree = check
        };
        return template;
    }

    private Style CreateColumnHeaderStyle()
    {
        var style = new Style(typeof(DataGridColumnHeader));
        //style.Setters.Add(new Setter(Control.BorderThicknessProperty, new Thickness{Right = 1.0}));
        //style.Setters.Add(new Setter(Control.BorderBrushProperty, Theme.GrayBrush));
        //style.Setters.Add(new Setter(Control.BackgroundProperty, Brushes.Transparent));
        style.Setters.Add(new Setter(Control.FontSizeProperty, 15.0));
        //style.Setters.Add(new Setter(Control.FontWeightProperty, FontWeights.Medium));
        //style.Setters.Add(new Setter(Control.ForegroundProperty, Theme.GrayBrush));
        style.Setters.Add(new Setter(Control.TemplateProperty, CreateColumnHeaderTemplate()));
        return style;
    }

    private ControlTemplate CreateColumnHeaderTemplate()
    {

        var content = new FrameworkElementFactory(typeof(ContentPresenter), "ContentPresenter");
        content.SetValue(ContentPresenter.HorizontalAlignmentProperty, HorizontalAlignment.Left);
        content.SetValue(ContentPresenter.MarginProperty, new Thickness{Left = 20.0, Right = 10.0});

        var contentBorder = new FrameworkElementFactory(typeof(Border), "ContentBorder");
        contentBorder.SetValue(Border.BackgroundProperty, Brushes.Transparent);
        contentBorder.SetValue(Grid.RowProperty, 1);
        contentBorder.AppendChild(content);

        var thumbRect = new FrameworkElementFactory(typeof(Rectangle));
        thumbRect.SetValue(Rectangle.WidthProperty, 2.0);
        thumbRect.SetValue(Rectangle.StrokeProperty, Theme.GrayBrush);
        thumbRect.SetValue(Rectangle.CursorProperty, Cursors.SizeWE);

        var thumbTemplate = new ControlTemplate(typeof(Thumb)){
            VisualTree = thumbRect,
        };

        var thumbLeft = new FrameworkElementFactory(typeof(Thumb), "PART_LeftHeaderGripper");
        thumbLeft.SetValue(Thumb.HorizontalAlignmentProperty, HorizontalAlignment.Left);
        thumbLeft.SetValue(Thumb.TemplateProperty, thumbTemplate);
        thumbLeft.SetValue(Grid.RowProperty, 1);

        var thumbRight = new FrameworkElementFactory(typeof(Thumb), "PART_RightHeaderGripper");
        thumbRight.SetValue(Thumb.HorizontalAlignmentProperty, HorizontalAlignment.Right);
        thumbRight.SetValue(Grid.ColumnProperty, 1);
        thumbRight.SetValue(Thumb.TemplateProperty, thumbTemplate);
        thumbRight.SetValue(Grid.RowProperty, 1);

        var grid = new FrameworkElementFactory(typeof(Grid));
        
        var column1 = new FrameworkElementFactory(typeof(ColumnDefinition));
        column1.SetValue(ColumnDefinition.WidthProperty, new GridLength(1.0, GridUnitType.Star));

        var column2 = new FrameworkElementFactory(typeof(ColumnDefinition));
        column2.SetValue(ColumnDefinition.WidthProperty, GridLength.Auto);

        var row1 = new FrameworkElementFactory(typeof(RowDefinition));
        row1.SetValue(RowDefinition.HeightProperty, new GridLength(20.0));

        var row2 = new FrameworkElementFactory(typeof(RowDefinition));
        row2.SetValue(RowDefinition.HeightProperty, GridLength.Auto);

        var path = new FrameworkElementFactory(typeof(System.Windows.Shapes.Path), "SortIndicator");
        path.SetValue(System.Windows.Shapes.Path.DataProperty, Theme.AscendIcon);
        path.SetValue(System.Windows.Shapes.Path.FillProperty, Theme.ForegroundBrush);
        path.SetValue(System.Windows.Shapes.Path.StrokeProperty, Theme.ForegroundBrush);
        path.SetValue(System.Windows.Shapes.Path.VerticalAlignmentProperty, VerticalAlignment.Center);
        path.SetValue(System.Windows.Shapes.Path.HorizontalAlignmentProperty, HorizontalAlignment.Left);
        path.SetValue(System.Windows.Shapes.Path.MarginProperty, new Thickness{Left = 75.0});
        path.SetValue(System.Windows.Shapes.Path.VisibilityProperty, Visibility.Collapsed);
        path.SetValue(Grid.RowProperty, 0);
        path.SetValue(Grid.ColumnSpanProperty, 1);

        grid.AppendChild(row1);
        grid.AppendChild(row2);
        grid.AppendChild(column1);
        grid.AppendChild(column2);
        grid.AppendChild(contentBorder);
        grid.AppendChild(thumbLeft);
        grid.AppendChild(path);

        var border = new FrameworkElementFactory(typeof(Border), "BackgroundBorder");
        border.SetValue(Border.BackgroundProperty, Brushes.Transparent);
        border.AppendChild(grid);

        var template = new ControlTemplate(typeof(DataGridColumnHeader)){
            VisualTree = border,
        };
        var trigger = new Trigger{
            Property = DataGridColumnHeader.DisplayIndexProperty,
            Value = -1,
        };
        trigger.Setters.Add(new Setter(DataGridColumnHeader.VisibilityProperty, Visibility.Collapsed, "PART_LeftHeaderGripper"));
        template.Triggers.Add(trigger);

        var descendingTrigger = new Trigger{
            Property = DataGridColumnHeader.SortDirectionProperty,
            Value = ListSortDirection.Descending,
        };
        descendingTrigger.Setters.Add(new Setter(System.Windows.Shapes.Path.VisibilityProperty, Visibility.Visible, "SortIndicator"));
        descendingTrigger.Setters.Add(new Setter(System.Windows.Shapes.Path.DataProperty, Theme.DescendIcon, "SortIndicator"));
        template.Triggers.Add(descendingTrigger);

        var ascendingTrigger = new Trigger{
            Property = DataGridColumnHeader.SortDirectionProperty,
            Value = ListSortDirection.Ascending,
        };
        ascendingTrigger.Setters.Add(new Setter(System.Windows.Shapes.Path.VisibilityProperty, Visibility.Visible, "SortIndicator"));
        ascendingTrigger.Setters.Add(new Setter(System.Windows.Shapes.Path.DataProperty, Theme.AscendIcon, "SortIndicator"));
        template.Triggers.Add(ascendingTrigger);

        var mouseOverTrigger = new Trigger{
            Property = DataGridColumnHeader.IsMouseOverProperty,
            Value = true,
        };
        mouseOverTrigger.Setters.Add(new Setter(Control.ForegroundProperty, Theme.DataGridHeaderMouseOverBrush, "ContentPresenter"));
        mouseOverTrigger.Setters.Add(new Setter(System.Windows.Shapes.Path.FillProperty, Theme.DataGridHeaderMouseOverBrush, "SortIndicator"));
        mouseOverTrigger.Setters.Add(new Setter(System.Windows.Shapes.Path.StrokeProperty, Theme.DataGridHeaderMouseOverBrush, "SortIndicator"));
        template.Triggers.Add(mouseOverTrigger);

        return template;
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

#region CustomContextMenu
class CustomContextMenu : ContextMenu
{
    public CustomContextMenu()
    {
        this.Background = Theme.BackgroundBrush;
        this.Foreground = Theme.ForegroundBrush;
        this.Template = CreateTemplate();

        var menu1 = new MenuItem{
            Header = "Open with Explorer",
            Template = CreateItemTemplate(),
        };
        menu1.Click += new RoutedEventHandler(MenuItem1_Click);

        var menu2 = new MenuItem{
            Header = "Properties",
            Template = CreateItemTemplate(),
        };
        menu2.Click += new RoutedEventHandler(MenuItem2_Click);

        this.AddChild(menu1);
        this.AddChild(menu2);
    }

    private ControlTemplate CreateTemplate()
    {
        var stack = new FrameworkElementFactory(typeof(StackPanel));
        stack.SetValue(StackPanel.IsItemsHostProperty, true);
        stack.SetValue(StackPanel.MarginProperty, new Thickness{Top = 5, Bottom = 5});

        var border = new FrameworkElementFactory(typeof(Border));
        border.SetValue(Border.BorderThicknessProperty, new Thickness(1.0));
        border.SetValue(Border.BorderBrushProperty, Theme.GrayBrush);
        border.SetValue(Border.BackgroundProperty, Theme.BackgroundBrush);
        border.SetValue(Border.CornerRadiusProperty, new CornerRadius(5.0));
        border.AppendChild(stack);

        var template = new ControlTemplate{
            VisualTree = border,
        };
        return template;
    }

    private ControlTemplate CreateItemTemplate()
    {
        var text = new FrameworkElementFactory(typeof(TextBlock), "textblock");
        text.SetValue(TextBlock.TextProperty, new Binding("Header"){RelativeSource = RelativeSource.TemplatedParent});
        text.SetValue(TextBlock.PaddingProperty, new Thickness{Left = 10.0, Right = 10.0, Top = 2.0, Bottom = 2.0});
        text.SetValue(TextBlock.VerticalAlignmentProperty, VerticalAlignment.Center);
        text.SetValue(TextBlock.FontSizeProperty, 17.0);

        var mouseOverTrigger = new Trigger{
            Property = MenuItem.IsMouseOverProperty,
            Value = true,
        };
        mouseOverTrigger.Setters.Add(new Setter(TextBlock.BackgroundProperty, Theme.ButtonMouseOverBackgroundBrush, "textblock"));

        var template = new ControlTemplate{
            VisualTree = text
        };
        template.Triggers.Add(mouseOverTrigger);
        
        return template;
    }

    private void MenuItem1_Click(object sender, RoutedEventArgs e)
    {
        try {
            var item = ((DataGrid)((ContextMenu)((MenuItem)sender).Parent).PlacementTarget).SelectedItem;
            var path = ((FileSystemInfoEntry)item).Path;
            if (Directory.Exists(path))
                Process.Start("explorer.exe", String.Format(" \"{0}\"", path));
            else
                Process.Start("explorer.exe", String.Format("/select,\"{0}\"", path));
        } catch { }
    }

    private void MenuItem2_Click(object sender, RoutedEventArgs e)
    {
        try {
            var items = ((DataGrid)((ContextMenu)((MenuItem)sender).Parent).PlacementTarget).SelectedItems;
            foreach (FileSystemInfoEntry f in items) {
                Win32.FileSystemProperties(f.Path);
            }
        } catch { }
    }

}
#endregion ContextMenu

#region CustomStatusBar
public class CustomStatusBar : StatusBar
{
    public CustomStatusBar()
    {
        this.Foreground = Theme.ForegroundBrush;
        this.Background = Brushes.Transparent;
        this.ItemsSource = Data.StatusContent;
        this.VerticalContentAlignment = VerticalAlignment.Center;
        this.Margin = new Thickness{Left = 5.0, Right = 5.0};
        this.FontSize = 16.0;
        this.ItemTemplate = CreateTemplate();
    }

    private static DataTemplate CreateTemplate()
    {
        var text = new FrameworkElementFactory(typeof(TextBlock));
        text.SetValue(TextBlock.MarginProperty, new Thickness{Left = 5.0, Right = 15.0});
        text.SetValue(TextBlock.VerticalAlignmentProperty, VerticalAlignment.Center);
        text.SetBinding(TextBlock.TextProperty, new Binding("Value.Text"));

        var path = new FrameworkElementFactory(typeof(System.Windows.Shapes.Path));
        path.SetValue(System.Windows.Shapes.Path.DataProperty, Theme.Line);
        path.SetValue(System.Windows.Shapes.Path.FillProperty, Theme.ForegroundBrush);
        path.SetValue(System.Windows.Shapes.Path.StrokeProperty, Theme.ForegroundBrush);
        path.SetValue(System.Windows.Shapes.Path.VerticalAlignmentProperty, VerticalAlignment.Center);

        var stackPanel = new FrameworkElementFactory(typeof(StackPanel));
        stackPanel.SetValue(StackPanel.OrientationProperty, Orientation.Horizontal);
        stackPanel.SetBinding(StackPanel.VisibilityProperty, new Binding("Value.Visibility"));
        stackPanel.AppendChild(text);
        stackPanel.AppendChild(path);

        var template = new DataTemplate{
            VisualTree = stackPanel
        };
        return template;
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
    public bool _hasZoneId = false;

    public FileSystemInfoEntry(FileSystemInfo fsi, bool reqIcon)
    {
        this._path = fsi.FullName;
        this._name = fsi.Name;
        this._lastWriteTime = fsi.LastWriteTime;
        this._isDirectory = (bool)((fsi.Attributes & FileAttributes.Directory) == FileAttributes.Directory);
        if (reqIcon)
        {
            this._icon = Win32.GetIconBitmapSource(this._path, fsi.Attributes);
        }
        else if (!this._isDirectory)
        {
            //this._hasZoneId = Win32.CheckZoneId(this._path);
            Data.ZoneIDCheckQueueList.Add(this);
            if(!Data.IconsDictionary.ContainsKey(fsi.Extension))
            {
                Data.IconsDictionary.Add(fsi.Extension, Win32.GetIconBitmapSource(this._path, fsi.Attributes));
            }
            this._icon = Data.IconsDictionary[fsi.Extension];
        }
        else
        {
            this._icon = Theme.DirectoryIcon;
        }
    }

    public FileSystemInfoEntry(FileSystemInfo fsi) : this(fsi, false)
    {
    }

    /*~FileSystemInfoEntry()
    {
        Console.WriteLine(String.Format("FileSystemInfoEntry Destructor : {0}", this.Name));
    }*/

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
        border.SetValue(Border.BackgroundProperty, Theme.ScrollBarBackgroundBrush);
        border.SetValue(Grid.RowProperty, 1);
        border.AppendChild(track);

        var pageUpButton = new FrameworkElementFactory(typeof(CustomRepeatButton));
        pageUpButton.SetValue(RepeatButton.ContentProperty, Theme.LineUpIcon);
        pageUpButton.SetValue(RepeatButton.CommandProperty, ScrollBar.LineUpCommand);
        pageUpButton.SetValue(Grid.RowProperty, 0);

        var pageDownButton = new FrameworkElementFactory(typeof(CustomRepeatButton));
        pageDownButton.SetValue(RepeatButton.ContentProperty, Theme.LineDownIcon);
        pageDownButton.SetValue(RepeatButton.CommandProperty, ScrollBar.LineDownCommand);
        pageDownButton.SetValue(Grid.RowProperty, 2);

        var row1 = new FrameworkElementFactory(typeof(RowDefinition));
        row1.SetValue(RowDefinition.HeightProperty, GridLength.Auto);

        var row2 = new FrameworkElementFactory(typeof(RowDefinition));
        row2.SetValue(RowDefinition.HeightProperty, new GridLength(1.0, GridUnitType.Star));

        var row3 = new FrameworkElementFactory(typeof(RowDefinition));
        row3.SetValue(RowDefinition.HeightProperty, GridLength.Auto);

        var grid = new FrameworkElementFactory(typeof(Grid), "Bg");
        grid.SetValue(Grid.SnapsToDevicePixelsProperty, true);
        grid.AppendChild(row1);
        grid.AppendChild(row2);
        grid.AppendChild(row3);
        grid.AppendChild(pageUpButton);
        grid.AppendChild(border);
        grid.AppendChild(pageDownButton);

        var ct = new ControlTemplate(typeof(ScrollBar)){
            VisualTree = grid,
        };
        return ct;
    }

    private Style CreateCustomScrollBarStyle()
    {
        var style = new Style(typeof(ScrollBar));
        style.Setters.Add(new Setter(ScrollBar.WidthProperty, 15.0));
        style.Setters.Add(new Setter(ScrollBar.MarginProperty, new Thickness{Left = 5.0}));
        style.Setters.Add(new Setter(ScrollBar.TemplateProperty, this["ScrollBarControlTemplate"]));
        var visibilityTrigger = new Trigger{
            Property = ScrollBar.IsEnabledProperty,
            Value = false,
        };
        visibilityTrigger.Setters.Add(new Setter(ScrollBar.VisibilityProperty, Visibility.Hidden));
        style.Triggers.Add(visibilityTrigger);
        return style;
    }
}
#endregion CustomResourceDictionary

#region CustomRepeatButton
class CustomRepeatButton : RepeatButton
{
    private Storyboard MouseEnterAnimationStoryboard = new Storyboard();
    private Storyboard MouseLeaveAnimationStoryboard = new Storyboard();
    private SolidColorBrush BackgroundBrush = new SolidColorBrush(Colors.Gray);

    public CustomRepeatButton()
    {
        this.Template = CreateTemplate();
        this.Margin = new Thickness{Right = 0.5};

        NameScope.SetNameScope(this, new NameScope());
        this.RegisterName("ScrollThumbBackgroundColor", this.BackgroundBrush);

        this.MouseEnterAnimationStoryboard.Children.Add(Theme.ScrollThumbMouseEnterColorAnimation);
        this.MouseLeaveAnimationStoryboard.Children.Add(Theme.ScrollThumbMouseLeaveColorAnimation);

        this.MouseEnter += (sender, e) => {
            this.MouseEnterAnimationStoryboard.Begin(this);
        };
        this.MouseLeave += (sender, e) => {
            this.MouseLeaveAnimationStoryboard.Begin(this);
        };
    }

    private ControlTemplate CreateTemplate()
    {
        var path = new FrameworkElementFactory(typeof(System.Windows.Shapes.Path));
        var geometryBinding = new Binding("Content"){
            Source = this
        };
        path.SetBinding(System.Windows.Shapes.Path.DataProperty, geometryBinding);
        var bindingBackground = new Binding{
            BindsDirectlyToSource = true,
            Source = this.BackgroundBrush,
        };
        path.SetBinding(System.Windows.Shapes.Path.FillProperty, bindingBackground);
        path.SetBinding(System.Windows.Shapes.Path.StrokeProperty, bindingBackground);
        path.SetValue(System.Windows.Shapes.Path.VerticalAlignmentProperty, VerticalAlignment.Center);
        path.SetValue(System.Windows.Shapes.Path.HorizontalAlignmentProperty, HorizontalAlignment.Left);
        
        var border = new FrameworkElementFactory(typeof(Border));
        border.SetValue(Border.HeightProperty, 18.0);
        border.SetValue(Border.WidthProperty, 15.0);
        border.SetValue(Border.BackgroundProperty, Theme.ScrollBarBackgroundBrush);
        border.AppendChild(path);

        var ct = new ControlTemplate(typeof(CustomRepeatButton)){
            VisualTree = border
        };
        return ct;
    }
}
#endregion CustomRepeatButton

#region CustomTrack
class CustomTrack : Track, INotifyPropertyChanged
{
    private Thickness _borderMargin;
    public Thickness BorderMargin
    {
        get { return _borderMargin; }
        set { _borderMargin = value; OnPropertyChanged("BorderMargin"); }
    }

    private Storyboard _thumbMouseEnterAnimationStoryboard = new Storyboard();
    private Storyboard _thumbMouseLeaveAnimationStoryboard = new Storyboard();

    private SolidColorBrush _thumbBackgroundBrush = new SolidColorBrush(Colors.Gray);

    public CustomTrack()
    {
        this.Thumb = new Thumb{
            Template = CreateThumbTemplate(),
        };
        this.Resources.Add(SystemParameters.VerticalScrollBarButtonHeightKey, 100.0);
        this.IsDirectionReversed = true;

        this.IncreaseRepeatButton = new RepeatButton{
            Template = CreateDecreaseRepeatButtonTemplate(),
        };
        this.DecreaseRepeatButton = new RepeatButton{
            Template = CreateIncreaseRepeatButtonTemplate(),
        };

        NameScope.SetNameScope(this, new NameScope());
        this.RegisterName("ScrollThumbBackgroundColor", this._thumbBackgroundBrush);

        this._thumbMouseEnterAnimationStoryboard.Children.Add(Theme.ScrollThumbMouseEnterColorAnimation);
        this._thumbMouseLeaveAnimationStoryboard.Children.Add(Theme.ScrollThumbMouseLeaveColorAnimation);

        this.MouseEnter += (sender, e) => {
            this._thumbMouseEnterAnimationStoryboard.Begin(this);
        };
        this.MouseLeave += (sender, e) => {
            this._thumbMouseLeaveAnimationStoryboard.Begin(this);
        };
    }

    private ControlTemplate CreateThumbTemplate()
    {
        var border = new FrameworkElementFactory(typeof(Border));

        var bindingBackground = new Binding{
            BindsDirectlyToSource = true,
            Source = this._thumbBackgroundBrush,
        };
        border.SetBinding(Border.BackgroundProperty, bindingBackground);
        var bindingBorderMargin = new Binding("BorderMargin"){
            Source = this,
        };
        border.SetBinding(Border.MarginProperty, bindingBorderMargin);
        border.SetValue(Border.CornerRadiusProperty, new CornerRadius(6.0));
        
        var ct = new ControlTemplate(){
            VisualTree = border,
        };
        return ct;
    }

    protected override void OnRender(DrawingContext dc)
    {
        if (Orientation.Horizontal == this.Orientation) {
            this.BorderMargin = new Thickness{Bottom = 5.0};
            this.DecreaseRepeatButton.Command = ScrollBar.PageLeftCommand;
            this.IncreaseRepeatButton.Command = ScrollBar.PageRightCommand;
        } else {
            this.BorderMargin = new Thickness{Right = 5.0};
            this.DecreaseRepeatButton.Command = ScrollBar.PageUpCommand;
            this.IncreaseRepeatButton.Command = ScrollBar.PageDownCommand;
        }
    }

    private static ControlTemplate CreateIncreaseRepeatButtonTemplate()
    {
        var border = new FrameworkElementFactory(typeof(Border));
        border.SetValue(Border.BackgroundProperty, Brushes.Transparent);
        var ct = new ControlTemplate(){
            VisualTree = border,
        };
        return ct;
    }

    private static ControlTemplate CreateDecreaseRepeatButtonTemplate()
    {
        var border = new FrameworkElementFactory(typeof(Border));
        border.SetValue(Border.BackgroundProperty, Brushes.Transparent);
        var ct = new ControlTemplate(){
            VisualTree = border,
        };
        return ct;
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

public class StatusContentEntry : INotifyPropertyChanged
{
    public event PropertyChangedEventHandler PropertyChanged = (sender, e) => { };

    private string _text;
    public string Text
    {
        get { return this._text; }
        set {
            this._text = value;
            PropertyChanged.Invoke(this, new PropertyChangedEventArgs("Text"));
            PropertyChanged.Invoke(this, new PropertyChangedEventArgs("Visibility"));
        }
    }

    public Visibility Visibility
    {
        get { return (this._text == String.Empty ? Visibility.Collapsed : Visibility.Visible); }
    }

    public StatusContentEntry(string value)
    {
        this.Text = value;
    }
}

#region SortManager
public static class SortManager
{
    public static DataGridColumn lastSortedColumn;
    public static string lastSortMemberPath;
    public static Nullable<ListSortDirection> lastSortDirection;

    static SortManager()
    {
        lastSortMemberPath = AppSettings.DefaultSortProperty;
        lastSortDirection = AppSettings.DefaultSortDirection;
    }

    public static void TestSortDescription()
    {
        if (null == lastSortedColumn)
            return;
        
        Data.FileInfoCollectionView.SortDescriptions.Clear();
        
        try {
            if (null != lastSortedColumn.SortDirection)
            {
                //Console.WriteLine(String.Format("SortDescription : {0} : {1}", lastSortedColumn.SortMemberPath, (ListSortDirection)lastSortedColumn.SortDirection));
                lastSortMemberPath = lastSortedColumn.SortMemberPath;
                lastSortDirection = lastSortedColumn.SortDirection;
                Data.FileInfoCollectionView.SortDescriptions.Add(new SortDescription(lastSortedColumn.SortMemberPath, (ListSortDirection)lastSortedColumn.SortDirection));
                lastSortedColumn = null;
            }
        } catch { }
    }

    public static IEnumerable<FileSystemInfo> EnumerateSortedFileSystemInfos(DirectoryInfo di)
    {
        try
        {
            if (ListSortDirection.Ascending == lastSortDirection)
            {
                if ("Name" == lastSortMemberPath)
                    return di.EnumerateFileSystemInfos().OrderBy<FileSystemInfo, String>(FileSystemInfo => FileSystemInfo.Name);
                else if ("LastWriteTime" == lastSortMemberPath)
                    return di.EnumerateFileSystemInfos().OrderBy<FileSystemInfo, DateTime>(FileSystemInfo => FileSystemInfo.LastWriteTime);
                else
                    return di.EnumerateFileSystemInfos().OrderBy<FileSystemInfo, FileAttributes>(FileSystemInfo => FileSystemInfo.Attributes);
            }
            else if (ListSortDirection.Descending == lastSortDirection)
            {
                if ("Name" == lastSortMemberPath)
                    return di.EnumerateFileSystemInfos().OrderByDescending<FileSystemInfo, String>(FileSystemInfo => FileSystemInfo.Name);
                else if ("LastWriteTime" == lastSortMemberPath)
                    return di.EnumerateFileSystemInfos().OrderByDescending<FileSystemInfo, DateTime>(FileSystemInfo => FileSystemInfo.LastWriteTime);
                else
                    return di.EnumerateFileSystemInfos().OrderByDescending<FileSystemInfo, FileAttributes>(FileSystemInfo => FileSystemInfo.Attributes);
            }
            else
                return di.EnumerateFileSystemInfos();
        }
        catch
        {
            return di.EnumerateFileSystemInfos();
        }
    }
}
#endregion SortManager

#region Data
public static class Data
{
    public static ObservableCollection<FileSystemInfoEntry> FileInfoCollection = new ObservableCollection<FileSystemInfoEntry>();
    public static List<FileSystemInfoEntry> ZoneIDCheckQueueList = new List<FileSystemInfoEntry>();
    public static CollectionViewSource FileInfoCollectionView;
    public static object _lockObject = new object();
    public static CancellationTokenSource cTokenSource = null;

    public static Dictionary<string, StatusContentEntry> StatusContent { get; set; }

    public static Dictionary<string, BitmapSource> IconsDictionary = new Dictionary<string, BitmapSource>();

    public static ObservableCollection<FileSystemInfoEntry> RootDirectoryCollection = new ObservableCollection<FileSystemInfoEntry>();

    static Data()
    {
        FileInfoCollectionView = new CollectionViewSource{
            Source = FileInfoCollection,
            IsLiveSortingRequested = true,
        };
        FileInfoCollectionView.SortDescriptions.Add(new SortDescription(AppSettings.DefaultSortProperty, AppSettings.DefaultSortDirection));
        BindingOperations.EnableCollectionSynchronization(FileInfoCollection, _lockObject);

        StatusContent = new Dictionary<string, StatusContentEntry>()
        {
            { "ItemsCount", new StatusContentEntry(String.Empty) },
            { "SelectedItemsCount", new StatusContentEntry(String.Empty) },
        };

        FileInfoCollection.CollectionChanged += (sender, e) => {
            if (2 <= FileInfoCollection.Count)
                Data.StatusContent["ItemsCount"].Text = String.Format("{0} items", FileInfoCollection.Count);
            else
                Data.StatusContent["ItemsCount"].Text = String.Format("{0} item", FileInfoCollection.Count);
        };
        CreateRootDirectoryItems();
    }

    private static void CreateRootDirectoryItems()
    {
        DriveInfo[] allDrives = DriveInfo.GetDrives();

        foreach (DriveInfo d in allDrives)
        {
            try {
                Data.RootDirectoryCollection.Add(new FileSystemInfoEntry(d.RootDirectory, true));
            } catch { }
        }

        foreach (Environment.SpecialFolder f in Enum.GetValues(typeof(AppSettings.UserFolders)))
        {
            try {
                var path = Environment.GetFolderPath(f);
                if (String.Empty != path)
                {
                    var di = new DirectoryInfo(path);
                    Data.RootDirectoryCollection.Add(new FileSystemInfoEntry(di, true));
                }
            } catch { }
        }
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
            if (null == value || false == value.Exists) {
                return;
            }

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

        if (IconsDictionary.Count > 512)
        {
            IconsDictionary.Clear();
        }

        SortManager.TestSortDescription();

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

        //Console.WriteLine(String.Format("ZoneIDCheckQueueList.Count : {0}", ZoneIDCheckQueueList.Count));
        //Console.WriteLine(String.Format("IconsDictionary.Count : {0}", IconsDictionary.Count));
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
            foreach (var info in SortManager.EnumerateSortedFileSystemInfos(CurrentDirectory))
            {
                if (token.IsCancellationRequested)
                {
                    //token.ThrowIfCancellationRequested();
                    return;
                }
                FileInfoCollection.Add(new FileSystemInfoEntry(info));
            }
            foreach (FileSystemInfoEntry entry in ZoneIDCheckQueueList)
            {
                if (token.IsCancellationRequested)
                {
                    //token.ThrowIfCancellationRequested();
                    break;
                }
                entry.HasZoneId = Win32.CheckZoneId(entry.Path);
            }
            ZoneIDCheckQueueList.Clear();
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
#endregion Data

#region Win32
public static class Win32
{
    private static readonly IntPtr STATUS_BUFFER_OVERFLOW = (IntPtr)0x80000005;
    private static readonly int SIZE_SHFILEINFO = Marshal.SizeOf(typeof(SHFILEINFO));
    public const string Shell32 = "shell32.dll";
    public const string ImageRes = "ImageRes.dll";
    private const uint SHOP_FILEPATH = 0x2;

    [DllImport("ntdll.dll", CharSet=CharSet.Auto)]
    private static extern IntPtr NtQueryInformationFile(SafeFileHandle fileHandle, out IO_STATUS_BLOCK IoStatusBlock, IntPtr pInfoBlock, int length, FILE_INFORMATION_CLASS fileInformation);  

    [DllImport("shell32.dll", CharSet=CharSet.Auto)]
    private static extern IntPtr SHGetFileInfo(string pszPath, FileAttributes dwFileAttributes, out SHFILEINFO psfi, int cbFileInfo, SHGFI uFlags);
    
    [DllImport("shell32.dll", CharSet=CharSet.Auto)]
    private static extern uint ExtractIconEx(string szFileName, int nIconIndex, IntPtr phiconLarge, out IntPtr phiconSmall, int nIcons);
    
    [DllImport("user32.dll", EntryPoint="DestroyIcon")]
    private static extern int DestroyIcon(IntPtr hIcon);

    [DllImport("shell32.dll")]
    private static extern bool SHObjectProperties(IntPtr hwnd,
                                    uint shopObjectType,
                                    [MarshalAs(UnmanagedType.LPWStr)] string pszObjectName,
                                    [MarshalAs(UnmanagedType.LPWStr)] string pszPropertyPage);

    public static void FileSystemProperties(string path)
    {
        SHObjectProperties(IntPtr.Zero, SHOP_FILEPATH, path, String.Empty);
    }

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

    [DllImport("user32.dll")]
    private extern static uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);

    [StructLayout(LayoutKind.Sequential)]
    struct INPUT
    {
        internal int type;
        internal MOUSEINPUT mi;
    }

    [StructLayout(LayoutKind.Sequential)]
    struct MOUSEINPUT
    {
        internal int dx;
        internal int dy;
        internal int mouseData;
        internal int dwFlags;
        internal int time;
        internal IntPtr dwExtraInfo;
    }

    public static void SendMouseDown(int dx, int dy){
        INPUT[] input = new INPUT[1];
        input[0].mi.dx = dx;
        input[0].mi.dy = dy;
        input[0].mi.dwFlags = 0x0002;
        SendInput(1, input, Marshal.SizeOf(input[0]));
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
            if(IntPtr.Zero != buffer) { Marshal.FreeCoTaskMem(buffer); }
        }
        return result;
    }

    public static BitmapSource GetSystemIcon(int nIconIndex, string res)
    {
        try
        {
            //IntPtr hLIcon = IntPtr.Zero;
            IntPtr hSIcon = IntPtr.Zero;
            ExtractIconEx(res, nIconIndex, IntPtr.Zero, out hSIcon, 1);
            var bms = Imaging.CreateBitmapSourceFromHIcon(hSIcon, Int32Rect.Empty, BitmapSizeOptions.FromEmptyOptions());

            //DestroyIcon(hLIcon);
            DestroyIcon(hSIcon);

            bms.Freeze();
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
            return GetSystemIcon(0, Shell32);
        }

        if (IntPtr.Zero == info.hIcon || null == info.hIcon)
            return GetSystemIcon(0, Shell32);

        BitmapSource bms = Imaging.CreateBitmapSourceFromHIcon(info.hIcon, Int32Rect.Empty, BitmapSizeOptions.FromEmptyOptions());

        if (null != bms)
        {
            DestroyIcon(info.hIcon);
            bms.Freeze();
            return bms;
        }
        else
            return GetSystemIcon(0, Shell32);
    }
}
#endregion Win32

#region Theme
public class Theme
{
    public static Color BackgroundColor = new Color{A =255, R = 40, G = 40, B = 40};
    public static Brush BackgroundBrush = new SolidColorBrush(BackgroundColor);

    public static Brush ForegroundBrush = new SolidColorBrush(Colors.WhiteSmoke);

    public static Brush BlueBrush = new SolidColorBrush(Colors.Aqua);
    public static Brush GrayBrush = new SolidColorBrush(Colors.Gray);

    public static Color GrayBorderColor = new Color{A =255, R =75, G = 75, B = 75};
    public static Brush GrayBorderBrush = new SolidColorBrush(GrayBorderColor);

    public static Color DataGridHeaderMouseOverColor = new Color{A = 255, R = 50, G = 170, B = 230};
    public static Brush DataGridHeaderMouseOverBrush = new SolidColorBrush(DataGridHeaderMouseOverColor);

    public static Color TextBoxBackgroundColor = new Color{A =255, R = 30, G = 30, B = 30};
    public static Brush TextBoxBackgroundBrush = new SolidColorBrush(TextBoxBackgroundColor);

    public static Color TextBoxBorderColor = new Color{A =255, R = 80, G = 80, B = 80};
    public static Brush TextBoxBorderBrush = new SolidColorBrush(TextBoxBorderColor);

    public static Color ScrollBarBackgroundColor = new Color{A =255, R =40, G = 40, B =40};
    public static Brush ScrollBarBackgroundBrush = new SolidColorBrush(ScrollBarBackgroundColor);

    public static Color MouseOverBackgroundColor = new Color {A = 255, R = 60, G = 60, B = 60};
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

    public static Color DirectoryButtonBackgroundColor = new Color {A = 255, R = 40, G = 40, B = 40};
    public static Brush DirectoryButtonBackgroundBrush = new SolidColorBrush(DirectoryButtonBackgroundColor);

    public static Color DirectoryButtonMouseOverBackgroundColor = new Color {A = 255, R = 70, G = 70, B = 70};
    public static Brush DirectoryButtonMouseOverBackgroundBrush = new SolidColorBrush(DirectoryButtonMouseOverBackgroundColor);

    public static Color DirectoryButtonIsCheckedBackgroundColor = new Color {A = 255, R = 60, G = 60, B = 60};
    public static Brush DirectoryButtonIsCheckedBackgroundBrush = new SolidColorBrush(DirectoryButtonIsCheckedBackgroundColor);

    public static Color ComboBoxBackgroundColor = new Color {A = 255, R = 45, G = 45, B = 45};
    public static Brush ComboBoxBackgroundBrush = new SolidColorBrush(ComboBoxBackgroundColor);

    public static Color ComboBoxMouseOverBackgroundColor = new Color {A = 255, R = 90, G = 90, B = 90};
    public static Brush ComboBoxMouseOverBackgroundBrush = new SolidColorBrush(ComboBoxMouseOverBackgroundColor);
    
    public static FontFamily IconFontFamily = new FontFamily("Segoe MDL2 Assets");
    public static FontFamily textFontFamily = new FontFamily("Meiryo");

    public static Geometry Line = Geometry.Parse("M 0,2 L 0,15 L 1,15 L 1,2 Z");

    public static Geometry AscendIcon = Geometry.Parse("M 0,4 L 0,5 L 5,1 L 10,5 L 10,4 L 5,0 Z");
    public static Geometry DescendIcon = Geometry.Parse("M 0,4 L 0,5 L 5,10 L 10,5 L 10,4 L 5,9 Z");

    public static Geometry LineUpIcon = Geometry.Parse("M 0,4 L 0,6 L 5,2 L 10,6 L 10,4 L 5,0 Z");
    public static Geometry LineDownIcon = Geometry.Parse("M 0,0 L 0,2 L 5,6 L 10,2 L 10,0 L 5,4 Z");

    public static BitmapSource DirectoryIcon;
    public static BitmapSource SystemDriveIcon;

    public static DoubleAnimation ToggleOnXAnimation = new DoubleAnimation{
        From = 0.0,
        To = 19.0,
        Duration = new Duration(TimeSpan.FromMilliseconds(200.0))
    };

    public static DoubleAnimation ToggleOffXAnimation = new DoubleAnimation{
        From = 19.0,
        To = 0.0,
        Duration = new Duration(TimeSpan.FromMilliseconds(200.0))
    };

    public static ColorAnimation ScrollThumbMouseEnterColorAnimation = new ColorAnimation{
        From = Colors.Gray,
        To = new Color {A = 255, R = 200, G = 200, B = 200},
        Duration = new Duration(TimeSpan.FromMilliseconds(100.0))
    };

    public static ColorAnimation ScrollThumbMouseLeaveColorAnimation = new ColorAnimation{
        From = new Color {A = 255, R = 200, G = 200, B = 200},
        To = Colors.Gray,
        Duration = new Duration(TimeSpan.FromMilliseconds(100.0))
    };

    static Theme()
    {
        DirectoryIcon = Win32.GetSystemIcon(3, Win32.Shell32);
        SystemDriveIcon = Win32.GetSystemIcon(31, Win32.ImageRes);

        Storyboard.SetTargetName(ToggleOnXAnimation, "ToggleSwitchTransform");
        Storyboard.SetTargetProperty(ToggleOnXAnimation, new PropertyPath(TranslateTransform.XProperty));

        Storyboard.SetTargetName(ToggleOffXAnimation, "ToggleSwitchTransform");
        Storyboard.SetTargetProperty(ToggleOffXAnimation, new PropertyPath(TranslateTransform.XProperty));

        Storyboard.SetTargetName(ScrollThumbMouseEnterColorAnimation, "ScrollThumbBackgroundColor");
        Storyboard.SetTargetProperty(ScrollThumbMouseEnterColorAnimation, new PropertyPath(SolidColorBrush.ColorProperty));

        Storyboard.SetTargetName(ScrollThumbMouseLeaveColorAnimation, "ScrollThumbBackgroundColor");
        Storyboard.SetTargetProperty(ScrollThumbMouseLeaveColorAnimation, new PropertyPath(SolidColorBrush.ColorProperty));
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

    public enum UserFolders
    {
        Desktop = Environment.SpecialFolder.Desktop,
        User = Environment.SpecialFolder.UserProfile,
        Music = Environment.SpecialFolder.MyMusic,
        Pictures = Environment.SpecialFolder.MyPictures,
        Videos = Environment.SpecialFolder.MyVideos,
        Documents = Environment.SpecialFolder.MyDocuments,
    }
}
#endregion AppSettings
'@ -ReferencedAssemblies Microsoft.CSharp, WindowsBase, System.Linq, System.Threading, System.Xaml, PresentationFramework, PresentationCore, System.Configuration -ErrorAction Stop
}

if ($UserDebug) {
    $DebugPreference = 'Continue'
}

# ============================================================================ #
# PowerShell Section
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
                $entry.HasZoneId = [Win32]::CheckZoneId($entry.Path)
            }
        }
        #[Data]::OnCurrentDirectoryChanged()
    })

    $null = $MainWindow.ShowDialog()
    #$MainWindow.Close()
}

$mutexObj = New-Object Threading.Mutex($false, ('Global\{0}' -f $MyInvocation.MyCommand.Name))

if ($mutexObj.WaitOne(0, $false)) {
    Program
    $mutexObj.ReleaseMutex()
}

$mutexObj.Close()