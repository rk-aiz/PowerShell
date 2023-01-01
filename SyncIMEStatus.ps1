<#
    IMEの有効/無効をウィンドウ間で同期する
    変換/無変換をIME ON/OFFに置き換える
    MS-IMEの場合 [IME 入力モード切り替えの通知]を OFFにする事を推奨
    -> Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\IME\15.0\IMEJP\MSIME -Name ShowImeModeNotification -Value 0
#>
Param(
    [Parameter()]
    [switch] $Disable,
    [Parameter()]
    [switch] $IgnoreZenHan,
    [Parameter()]
    [switch] $ShowConsole
)

$WinEventTypeDef = @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class WinEvent {

    // IME ON/OFFを切り替えるキー
    // { [(int)キーコード], [0:IME OFF, 1:IME ON, 2:IME MODE切り替え], [0:KEYDOWNを通す, 1:KEYDOWNを破棄, 2:KEYDOWN/KEYUPを破棄] }
    private static int[,] IMEStateKeyCode = {
        {(int)Keys.IMENonconvert, 0, 1},
        {(int)Keys.IMEConvert, 1, 1},
        {243, 2, 1},
        {244, 2, 1}
    };

    private static string[] IMEStateMsg = { "IME OFF", "IME ON" };

    [DllImport("user32.dll")]
    private static extern IntPtr SetWinEventHook(uint eventMin, uint eventMax, IntPtr hmodWinEventProc, WinEventDelegate lpfnWinEventProc, uint idProcess, uint idThread, uint dwFlags);

    [DllImport("user32.dll")]
    private static extern IntPtr SetWindowsHookEx(int idHook, HookProc lpfn, IntPtr hMod, uint dwThreadId);

    [DllImport("user32.dll")]
    private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("user32.dll")]
    private static extern bool UnhookWinEvent(IntPtr hWinEventHook);

    [DllImport("user32.dll")]
    private static extern bool UnhookWindowsHookEx(IntPtr hhk);

    [DllImport("user32.dll")]
    private static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll")]
    private static extern int SendMessage(IntPtr hWnd, uint Msg, int wParam, int lParam);

    [DllImport("kernel32.dll")]
    private static extern IntPtr GetModuleHandle(string lpModuleName);

    [DllImport("imm32.dll")]
    private static extern IntPtr ImmGetDefaultIMEWnd(IntPtr hWnd);

    private const uint WINEVENT_OUTOFCONTEXT = 0x0000;
    private const uint EVENT_SYSTEM_FOREGROUND = 0x0003;
    private const uint EVENT_MAX = 0x7FFFFFFF;
    private const int WH_KEYBOARD_LL = 0x000D;
    private const int WM_KEYUP = 0x0101;
    private const int WM_KEYDOWN = 0x0100;
    private const int WM_IME_CONTROL = 0x0283;
    private const int IMC_GETOPENSTATUS = 0x0005;
    private const int IMC_SETOPENSTATUS = 0x0006;

    private static IntPtr winEventHookId = IntPtr.Zero;
    private static IntPtr keyEventHookId = IntPtr.Zero;
    private static int stateIme;

    private delegate IntPtr HookProc(int nCode, IntPtr wParam, IntPtr lParam);
    private static HookProc keyEventHookProc = KeyEventCallback;
    
    private delegate void WinEventDelegate(IntPtr hWinEventHook, uint eventType,IntPtr hwnd, int idObject, int idChild, uint dwEventThread, uint dwmsEventTime);
    private static WinEventDelegate winEventHookProc = WinEventCallback;

    public static bool BeginHook()
    {
        if ((IntPtr.Zero == keyEventHookId) && (IntPtr.Zero == winEventHookId)) {

            stateIme = SendMessage(ImmGetDefaultIMEWnd(GetForegroundWindow()), WM_IME_CONTROL, IMC_GETOPENSTATUS, 0);

            keyEventHookId = SetWindowsHookEx(WH_KEYBOARD_LL, keyEventHookProc, GetModuleHandle(Process.GetCurrentProcess().MainModule.ModuleName), 0);
            if (IntPtr.Zero == keyEventHookId) {
                return false;
            }

            winEventHookId = SetWinEventHook(EVENT_SYSTEM_FOREGROUND, EVENT_MAX, IntPtr.Zero, winEventHookProc, 0, 0, WINEVENT_OUTOFCONTEXT);
            if (IntPtr.Zero == winEventHookId) {
                return false;
            }
            return true;
        } else {
            return false;
        }
    }

    public static bool EndHook()
    {
        if (IntPtr.Zero != winEventHookId) {
            if (UnhookWinEvent(winEventHookId)) {
                winEventHookId = IntPtr.Zero;
            }
        }
        if (IntPtr.Zero != keyEventHookId) {
            if (UnhookWindowsHookEx(keyEventHookId)) {
                keyEventHookId = IntPtr.Zero;
            }
        }
        return (IntPtr.Zero == winEventHookId && IntPtr.Zero == keyEventHookId) ? false : true;
    }

    private static void WinEventCallback(IntPtr hWinEventHook, uint eventType, IntPtr hWnd, int idObject, int idChild, uint dwEventThread, uint dwmsEventTime)
    {
        if (eventType == EVENT_SYSTEM_FOREGROUND || 0x70000000 < eventType) {
            IntPtr imeHwnd = ImmGetDefaultIMEWnd(hWnd);
            //Console.WriteLine(eventType.ToString("X"));
            if (SendMessage(imeHwnd, WM_IME_CONTROL, IMC_GETOPENSTATUS, 0) != stateIme) {
                SendMessage(imeHwnd, WM_IME_CONTROL, IMC_SETOPENSTATUS, stateIme);
            }
        }
    }

    private static IntPtr KeyEventCallback(int nCode, IntPtr wParam, IntPtr lParam)
    {
        if (nCode >= 0 && (wParam == (IntPtr)WM_KEYUP || wParam == (IntPtr)WM_KEYDOWN)) {
            int keyCode = Marshal.ReadInt32(lParam);
            //Console.WriteLine(keyCode);
            for (int i = 0; i < IMEStateKeyCode.GetLength(0); i++) {
                if (IMEStateKeyCode[i, 0] == keyCode) {
                    IntPtr hWnd = GetForegroundWindow();
                    IntPtr imeHwnd = ImmGetDefaultIMEWnd(hWnd);
                    if (IMEStateKeyCode[i, 2] == 2) {
                        return (IntPtr)1;
                    }
                    if (IMEStateKeyCode[i, 2] == 1 && wParam == (IntPtr)WM_KEYDOWN) {
                        stateIme = SendMessage(imeHwnd, WM_IME_CONTROL, IMC_GETOPENSTATUS, 0);
                        return (IntPtr)1;
                    }
                    if (IMEStateKeyCode[i, 1] == 2) {
                        stateIme = (0 == SendMessage(imeHwnd, WM_IME_CONTROL, IMC_GETOPENSTATUS, 0)) ? 1 : 0;
                        SendMessage(imeHwnd, WM_IME_CONTROL, IMC_SETOPENSTATUS, stateIme);
                    } else if (IMEStateKeyCode[i, 1] != stateIme) {
                        stateIme = IMEStateKeyCode[i, 1];
                        SendMessage(imeHwnd, WM_IME_CONTROL, IMC_SETOPENSTATUS, stateIme);
                    }
                    Console.WriteLine(IMEStateMsg[stateIme]);
                    break;
                }
            }
        }
        return CallNextHookEx(keyEventHookId, nCode, wParam, lParam);
    }

    public static int ChageImeOpenStatus()
    {
        int stateIme_ = (0 == stateIme) ? 1 : 0;
        IntPtr hWnd = GetForegroundWindow();
        IntPtr imeHwnd = ImmGetDefaultIMEWnd(hWnd);
        int result = SendMessage(imeHwnd, WM_IME_CONTROL, IMC_SETOPENSTATUS, stateIme_);
        if (0 == result) {
            stateIme = stateIme_;
            Console.WriteLine(IMEStateMsg[stateIme]);
        }
        return stateIme;
    }

    public static void SetIMEStateKeyCode(int keyCode, int? changeMode, int? ignoreMode)
    {
        for (int i = 0; i < IMEStateKeyCode.GetLength(0); i++) {
            if (IMEStateKeyCode[i, 0] == keyCode) {
                if (null != changeMode) {
                    IMEStateKeyCode[i, 1] = changeMode ?? IMEStateKeyCode[i, 1];
                }
                if (null != ignoreMode) {
                    IMEStateKeyCode[i, 2] = ignoreMode ?? IMEStateKeyCode[i, 2];
                }
            }
        }
    }
}
'@

function Program {
    Param(
        [Parameter(Mandatory = $true)]
        [string] $WinEventTypeDef,
        [Parameter(Mandatory = $true)]
        [string] $MyCommandName,
        [Parameter()]
        [bool] $Disable = $false,
        [Parameter()]
        [bool] $IgnoreZenHan = $false
    )

    Try {
        [void][WinEvent]
    } Catch {
        Add-Type -TypeDefinition $WinEventTypeDef -ReferencedAssemblies System.Windows.Forms
    }

    $appContext = New-Object Windows.Forms.ApplicationContext

    $taskTrayIcon = New-Object Windows.Forms.NotifyIcon
    $taskTrayIcon.Icon = [Drawing.Icon]::ExtractAssociatedIcon((PS -Id $pid).Path)
    $taskTrayIcon.Text = $MyCommandName
    $taskTrayIcon.Visible = $True

    $menuItemEnable = New-Object Windows.Forms.ToolStripMenuItem('有効')
    $menuItemIgnoreZenHan = New-Object Windows.Forms.ToolStripMenuItem('全角/半角 無効')
    $menuItemExit = New-Object Windows.Forms.ToolStripMenuItem('Exit')

    $taskTrayIcon.ContextMenuStrip = New-Object Windows.Forms.ContextMenuStrip
    $taskTrayIcon.ContextMenuStrip.Items.AddRange(($menuItemEnable, $menuItemIgnoreZenHan, $menuItemExit))

    $taskTrayIcon.add_Click({
        if ('Left' -eq $_.Button ) {
            $null = [WinEvent]::ChageImeOpenStatus()
        }
    })

    $menuItemExit.add_Click({
        [Windows.Forms.Application]::ExitThread()
    })

    $menuItemEnable.add_Click({
        if ($Args[0].Checked) {
            $Args[0].Checked = [WinEvent]::EndHook()
        } else {
            $Args[0].Checked = [WinEvent]::BeginHook()
        }
    })

    $menuItemIgnoreZenHan.add_Click({
        if ($Args[0].Checked) {
            [WinEvent]::SetIMEStateKeyCode(243, $null, 1)
            [WinEvent]::SetIMEStateKeyCode(244, $null, 1)
            $Args[0].Checked = $false
        } else {
            [WinEvent]::SetIMEStateKeyCode(243, $null, 2)
            [WinEvent]::SetIMEStateKeyCode(244, $null, 2)
            $Args[0].Checked = $true
        }
    })

    if ($false -eq $Disable) {
        $menuItemEnable.Checked = [WinEvent]::BeginHook()
    }

    if ($true -eq $IgnoreZenHan) {
        [WinEvent]::SetIMEStateKeyCode(243, $null, 2)
        [WinEvent]::SetIMEStateKeyCode(244, $null, 2)
        $menuItemIgnoreZenHan.Checked = $true
    }

    [Windows.Forms.Application]::Run($appContext)

    $null = [WinEvent]::EndHook()

    $taskTrayIcon.Visible = $false
}

if ($ShowConsole) {
    #コンソールありで実行
    $mutexObj = New-Object Threading.Mutex($false, ('Global\{0}' -f $MyInvocation.MyCommand.Name))
    if ($mutexObj.WaitOne(0, $false)) {
        Program -WinEventTypeDef $WinEventTypeDef -MyCommandName $MyInvocation.MyCommand.Name -Disable $Disable -IgnoreZenHan $IgnoreZenHan
        $mutexObj.ReleaseMutex()
    }
    $mutexObj.Close()

} else {
    #コンソールなしで実行
    #(実際には自身のps1をウィンドウ無しで再実行する)
    $strDisable = $(if ($Disable) {'-Disable '} else {''})
    $strIgnoreZenHan = $(if ($IgnoreZenHan) {'-IgnoreZenHan '} else {''})
    $StartInfo = New-Object Diagnostics.ProcessStartInfo
    $StartInfo.UseShellExecute = $false
    $StartInfo.CreateNoWindow = $true
    $StartInfo.FileName = "powershell.exe"
    $StartInfo.Arguments = '-NoProfile -NonInteractive -ExecutionPolicy Unrestricted -File "{0}" -ShowConsole {1}{2}' -f $MyInvocation.MyCommand.Path, $strDisable, $strIgnoreZenHan
    $Process = New-Object Diagnostics.Process
    $Process.StartInfo = $StartInfo
    $null = $Process.Start()
}

