# PowerShell
PowerShell Scripts

PowerShell練習用に作ったツール

・SyncIMEStatus.ps1
    - IMEの有効/無効をウィンドウ間で同期する
    
    タスクトレイ常駐
    [変換/無変換]をIME ON/OFFに置き換える。
    MS-IMEの場合 [IME 入力モード切り替えの通知]を OFFにする事を推奨。
    -> Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\IME\15.0\IMEJP\MSIME -Name ShowImeModeNotification -Value 0
    
    現状EVENT_SYSTEM_FOREGROUND をフックして SendMessageでIME ON/OFF切り替えをするという微妙な実装。
    もっといい方法がないものか・・・

・ClipboardWatcher.ps1
    - クリップボードに変更があった場合にスクリプトを実行するサンプル
    
    タスクトレイ常駐
    クリップボードの内容が以下の場合WPFでクリップボードの内容をパネル上に表示していく。
    ・テキスト (ContainsTrext)
        -> URLの場合ハイパーリンクとして扱う
    ・イメージ (ContainsImage)
    ・ファイル (ContainsFileDropList)

    PowerShellを通してでFormとWPFを連携するという変な実装。

・ZoneIDChecker.ps1
    - Zone.Identifier を確認するためのGUIツール

    Zone.Identifierストリームを確認して有無を一覧表示する。
    
    Zone.Identifier➝ネットワークから取得したファイルに自動的に付与されるセキュリティ(このファイルは他のコンピューターから取得したものです云々)

    ファイルを選択して[Unblock]でPowerShell上でUnblock-Fileを実行する。

    [Recurse]有効でサブフォルダ配下のアイテムも全てUnblock-Fileを実行する

    (PowerShellでやってることは実質Unblock-Fileのみであと全部C#・・・)
