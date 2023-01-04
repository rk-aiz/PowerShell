# PowerShell
PowerShell Scripts

PowerShell練習用に作ったツール

・SyncIMEStatus.ps1
    - IMEの有効/無効をウィンドウ間で同期する
    
    [変換/無変換]をIME ON/OFFに置き換える
    MS-IMEの場合 [IME 入力モード切り替えの通知]を OFFにする事を推奨
    -> Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\IME\15.0\IMEJP\MSIME -Name ShowImeModeNotification -Value 0
    
    現状EVENT_SYSTEM_FOREGROUND をフックして SendMessageでIME ON/OFF切り替えをするという微妙な実装
    もっといい方法がないものか・・・
