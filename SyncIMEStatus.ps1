Param(
    [Parameter()]
    [Switch] $Disable,

    [Parameter()]
    [Switch] $ShowConsole
)

$WinEventTypeDef = @'
using System;
using System.Text;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class WinEvent {

    //IME ON/OFFを切り替えるキーのコード
    // { [(int)キーコード], [0:IME OFF, 1:IME ON] }
    private static int[,] IMEStateKeyCode = { {(int)Keys.IMENonconvert, 0}, {(int)Keys.IMEConvert, 1} };
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
            UnhookWinEvent(winEventHookId);
            winEventHookId = IntPtr.Zero;
        }
        if (IntPtr.Zero != keyEventHookId) {
            UnhookWindowsHookEx(keyEventHookId);
            keyEventHookId = IntPtr.Zero;
        }
        return (IntPtr.Zero == keyEventHookId && IntPtr.Zero == winEventHookId) ? false : true;
    }

    private static void WinEventCallback(IntPtr hWinEventHook, uint eventType, IntPtr hWnd, int idObject, int idChild, uint dwEventThread, uint dwmsEventTime)
    {
        if (eventType == EVENT_SYSTEM_FOREGROUND || 0x70000000 < eventType) {
            IntPtr imeHwnd = ImmGetDefaultIMEWnd(hWnd);
            if (SendMessage(imeHwnd, WM_IME_CONTROL, IMC_GETOPENSTATUS, 0) != stateIme) {
                SendMessage(imeHwnd, WM_IME_CONTROL, IMC_SETOPENSTATUS, stateIme);
            }
        }
    }

    private static IntPtr KeyEventCallback(int nCode, IntPtr wParam, IntPtr lParam)
    {
        IntPtr lResult = CallNextHookEx(keyEventHookId, nCode, wParam, lParam);
        if (nCode >= 0 && wParam == (IntPtr)WM_KEYUP) {
            int keyCode = Marshal.ReadInt32(lParam);
            for (int i = 0; i < IMEStateKeyCode.GetLength(0); i++) {
                if (IMEStateKeyCode[i, 0] == keyCode) {
                    if (IMEStateKeyCode[i, 1] != stateIme) {
                        stateIme = IMEStateKeyCode[i, 1];
                        Console.WriteLine(IMEStateMsg[stateIme]);
                        IntPtr hWnd = GetForegroundWindow();
                        IntPtr imeHwnd = ImmGetDefaultIMEWnd(hWnd);
                        SendMessage(imeHwnd, WM_IME_CONTROL, IMC_SETOPENSTATUS, stateIme);
                    }
                    break;
                }
            }
        }
        return lResult;
    }

    public static int ChageImeOpenStatus()
    {
        int stateIme_ = (stateIme == 0)? 1: 0;
        IntPtr hWnd = GetForegroundWindow();
        IntPtr imeHwnd = ImmGetDefaultIMEWnd(hWnd);
        int result = SendMessage(imeHwnd, WM_IME_CONTROL, IMC_SETOPENSTATUS, stateIme_);
        if (0 == result) {
            stateIme = stateIme_;
            Console.WriteLine(IMEStateMsg[stateIme]);
        }
        return stateIme;
    }
}
'@

$Script = {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName PresentationCore

    Try {
        [void][WinEvent]
    } Catch {
        Add-Type -TypeDefinition $Args[0] -ReferencedAssemblies System.Windows.Forms, System.Runtime
    }

    $appContext = New-Object Windows.Forms.ApplicationContext

    $taskTrayIcon = New-Object Windows.Forms.NotifyIcon
    $taskTrayIcon.Icon = [Drawing.Icon]::ExtractAssociatedIcon((PS -Id $pid).Path)
    $taskTrayIcon.Tag = 0
    $taskTrayIcon.Text = $Args[1].Name
    $taskTrayIcon.Visible = $True

    $menuItemExit = New-Object Windows.Forms.MenuItem
    $menuItemExit.Text = 'Exit'

    $menuItemEnable = New-Object Windows.Forms.MenuItem
    $menuItemEnable.Text = '有効'
    $menuItemEnable.Checked = $true

    $taskTrayIcon.ContextMenu = New-Object Windows.Forms.ContextMenu
    $taskTrayIcon.ContextMenu.MenuItems.AddRange(($menuItemEnable, $menuItemExit))

    $taskTrayIcon.add_Click({
        $null = [WinEvent]::ChageImeOpenStatus()
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

    $menuItemEnable.Checked = [WinEvent]::BeginHook()

    [Windows.Forms.Application]::Run($appContext)

    $null = [WinEvent]::EndHook()

    $taskTrayIcon.Visible = $false
}

if ($ShowConsole) {
    #コンソールありで実行
    $mutexObj = New-Object Threading.Mutex($false, ('Global\{0}' -f $MyInvocation.MyCommand.Name))
    if ($mutexObj.WaitOne(0, $false)) {
        $Script.Invoke($WinEventTypeDef, $MyInvocation.MyCommand, $Disable)
        $mutexObj.ReleaseMutex()
    }
    $mutexObj.Close()

} else {
    #コンソールなしで実行
    #(実際には自身のps1をウィンドウ無しで再実行する)
    $StartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $StartInfo.UseShellExecute = $false
    $StartInfo.CreateNoWindow = $true
    $StartInfo.FileName = "powershell.exe"
    $StartInfo.Arguments = '-ExecutionPolicy Unrestricted -File "{0}" -ShowConsole' -f $MyInvocation.MyCommand.Path
    $Process = New-Object System.Diagnostics.Process
    $Process.StartInfo = $StartInfo
    $null = $Process.Start()
}

