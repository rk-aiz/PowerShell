Param(
    [Parameter()]
    [Switch] $ShowConsole
)

$WinEventTypeDef = @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class WinEvent {

    //IME ON/OFFを切り替えるキーのコード
    // { [(int)キーコード], [0:IME OFF, 1:IME ON], [0: IME OFF時に未確定文字をクリア, 1:IME OFF時に未確定文字を確定] }
    private static int[,] IMEStateKeyCode = { {(int)Keys.IMENonconvert, 0, 1}, {(int)Keys.IMEConvert, 1, 0} };
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
    private const int WH_KEYBOARD_LL = 13;
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
            winEventHookId = SetWinEventHook(EVENT_SYSTEM_FOREGROUND, EVENT_SYSTEM_FOREGROUND, IntPtr.Zero, winEventHookProc, 0, 0, WINEVENT_OUTOFCONTEXT);
            if (IntPtr.Zero == winEventHookId) {
                return false;
            }
            return true;
        } else {
            return false;
        }
    }

    public static void EndHook()
    {
        if (IntPtr.Zero != winEventHookId) {
            UnhookWinEvent(winEventHookId);
            winEventHookId = IntPtr.Zero;
        }
        if (IntPtr.Zero != keyEventHookId) {
            UnhookWindowsHookEx(keyEventHookId);
            keyEventHookId = IntPtr.Zero;
        }
    }

    private static void WinEventCallback(IntPtr hWinEventHook, uint eventType, IntPtr hWnd, int idObject, int idChild, uint dwEventThread, uint dwmsEventTime)
    {
        IntPtr imeHwnd = ImmGetDefaultIMEWnd(hWnd);

        if (SendMessage(imeHwnd, WM_IME_CONTROL, IMC_GETOPENSTATUS, 0) != stateIme) {
            SendMessage(imeHwnd, WM_IME_CONTROL, IMC_SETOPENSTATUS, stateIme);
        }
    }

    private static IntPtr KeyEventCallback(int nCode, IntPtr wParam, IntPtr lParam)
    {
        if (nCode >= 0 && wParam == (IntPtr)WM_KEYDOWN) {
            int keyCode = Marshal.ReadInt32(lParam);
            for (int i = 0; i < IMEStateKeyCode.GetLength(0); i++) {
                if (IMEStateKeyCode[i, 0] == keyCode) {
                    if (IMEStateKeyCode[i, 1] != stateIme) {
                        stateIme = IMEStateKeyCode[i, 1];
                        //SendMessage(ImmGetDefaultIMEWnd(GetForegroundWindow()), WM_IME_CONTROL, IMC_SETOPENSTATUS, stateIme);
                        Console.WriteLine(IMEStateMsg[stateIme]);
                    }
                    break;
                }
            }
        }
        return CallNextHookEx(keyEventHookId, nCode, wParam, lParam);
    }
}
'@

$Script = {
    Add-Type -AssemblyName System.Windows.Forms

    Try {
        [void][WinEvent]
    } Catch {
        Add-Type -TypeDefinition $Args[0] -ReferencedAssemblies System.Windows.Forms
    }

    $appContext = New-Object Windows.Forms.ApplicationContext

    $taskTrayIcon = New-Object Windows.Forms.NotifyIcon
    $taskTrayIcon.Icon = [Drawing.Icon]::ExtractAssociatedIcon((PS -id $PID).Path)
    $taskTrayIcon.Text = $Args[1].Name
    $taskTrayIcon.Visible = $True

    $menuItemExit = New-Object Windows.Forms.MenuItem
    $menuItemExit.Text = 'Exit'

    $taskTrayIcon.ContextMenu = New-Object Windows.Forms.ContextMenu
    $taskTrayIcon.ContextMenu.MenuItems.Add($menuItemExit)

    $menuItemExit.add_Click({
        [Windows.Forms.Application]::ExitThread()
    })

    if ([WinEvent]::BeginHook()) {
        [Windows.Forms.Application]::Run($appContext)
    }

    [WinEvent]::EndHook()

    $taskTrayIcon.Visible = $false
}

if ($ShowConsole) {
    #コンソールありで実行
    $mutexObj = New-Object Threading.Mutex($false, ('Global\{0}' -f $MyInvocation.MyCommand.Name))
    if ($mutexObj.WaitOne(0, $false)) {
        $Script.Invoke($WinEventTypeDef, $MyInvocation.MyCommand)
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

