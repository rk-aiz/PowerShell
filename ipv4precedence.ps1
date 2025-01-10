<#
.SYNOPSIS
	IPv6プレフィックスポリシーの優先順位変更スクリプト
.DESCRIPTION
    このPowerShellスクリプトは、指定されたIPv6プレフィックスの優先順位を変更するために使用されます。主な機能は以下の通りです：

    ・現在設定されているIPv6プレフィックスポリシーの取得
    ・特定のプレフィックスの優先順位の変更
        (特定のプレフィックスとは[::ffff:0:0/96(IPv4-Mapped IPv6 Address)]の事で、スクリプト内で設定されています。
            
            $TARGET_PREFIX = "::ffff:0:0/96"
        
        この部分を変更すれば他のプレフィックスも変更できます。)

    プレフィックスの優先順位を変更することで、ネットワーク通信のルーティングポリシーを調整します。
    特に[::ffff:0:0/96(IPv4-Mapped IPv6 Address)]の優先順位を適切に設定することで、ネットワークのパフォーマンスを最適化します。
.EXAMPLE
	PS> ./ipv4precedence.ps1 -NewPrecedence 100

.LINK
	https://github.com/rk-aiz/PowerShell
.NOTES
	Author: rk-aiz | License: CC0

    This script was written with the help of Microsoft Copilot.
    https://privacy.microsoft.com/en-us/privacystatement
#>

param (
    [string]$NewPrecedence = ""
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8


# 優先順位を変更するプレフィックス対象
$TARGET_PREFIX = "::ffff:0:0/96"


# 管理者権限を確認する関数
function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$currentUser
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}



# プレフィックスに補足情報を追加する関数
function Add-PrefixInfo {
    param (
        [string]$prefix
    )

    return "$prefix $(switch ($prefix) {
        "::/0" { "(IPv6通信全般)" }
        "::/96" { "(IPv4互換)" }
        "::ffff:0:0/96" { "(IPv4マッピングされたIPv6アドレス)" }
        "::1/128" { "(ループバックアドレス)" }
        "2000::/3" { "(グローバルユニキャストアドレス)" }
        "2001::/32" { "(Teredoトンネリング)" }
        "2002::/16" { "(6to4トンネリング)" }
        "fc00::/7" { "(ユニークローカルアドレス)" }
        "fe80::/10" { "(リンクローカルアドレス)" }
        "ff00::/8" { "(マルチキャストアドレス)" }
        default { }
    })"
}



# 現在設定されているプレフィックスポリシーを取得
function Get-PrefixPolicies {

    $policies = @()
    (netsh interface ipv6 show prefixpolicies) | ForEach-Object {

        $line = $_
        if ($line -match '^\s*\d+\s+\S+') {  # 数字で始まる行を抽出
            $parts = $line -split '\s+'
            $policy = [PSCustomObject]@{
                "Precedence" = $parts[1] # 優先順位
                "Label" = $parts[2] # ラベル
                "Prefix" = $parts[3] # プレフィックス
            }
            $policies += $policy
        }
    }
    return ,$policies
}

$prefixPolicies = Get-PrefixPolicies

# 設定対象のプレフィックスが含まれているか確認
$targetPrefixExists = $false
foreach ($pp in $prefixPolicies) {
    if ($pp.Prefix -eq $TARGET_PREFIX) {
        $targetPrefixExists = $true
        break
    }
}
if ($false -eq $targetPrefixExists) {
    Write-Output "$TARGET_PREFIX が見つからないため中断しました。スクリプトを確認してください。"
}



# 優先順位の入力を確認
if ("" -eq $NewPrecedence) {

    # 現在設定されている優先順位を表示
    Write-Output "現在のプレフィックスポリシー:"
    $prefixPolicies | Format-Table -AutoSize -Property `
        @{Name="優先順位"; Expression={$_.Precedence}} ,`
        @{Name="ラベル"; Expression={$_.Label}}, `
        @{Name="プレフィックス"; Expression={(Add-PrefixInfo $_.Prefix)}}

    do {
        $NewPrecedence = Read-Host "プレフィックス[$TARGET_PREFIX]の新しい優先順位を入力してください (例: 100)"
        if ("" -eq $NewPrecedence) {
            Write-Output "入力がキャンセルされました。スクリプトを終了します。"
            exit
        }
        if (-not ([int]::TryParse($NewPrecedence, [ref]$null))) {
            Write-Host "優先順位は整数値である必要があります。再入力してください。" -ForegroundColor DarkYellow
        }
    } while (-not ([int]::TryParse($NewPrecedence, [ref]$null)))
} else {
    # パラメータとして受け取った場合も整数チェックを行う
    if (-not ([int]::TryParse($NewPrecedence, [ref]$null))) {
        Write-Host "優先順位は整数値である必要があります。スクリプトを終了します。" -ForegroundColor DarkYellow
        exit
    }
}

# 管理者権限を確認してnetshコマンドを実行
if (-not (Test-Admin)) {
    Write-Host "管理者権限がありません。管理者権限を取得して実行します。" -ForegroundColor DarkYellow
    $arguments = "-File `"$($MyInvocation.MyCommand.Path)`" -NewPrecedence $NewPrecedence"
    Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Verb RunAs
    exit
} else {
    foreach ($pp in $prefixPolicies) {
        if ($pp.Prefix -eq $TARGET_PREFIX) {
            Write-Output "netsh interface ipv6 set prefixpolicy $($pp.Prefix) $NewPrecedence $($pp.Label)"
            netsh interface ipv6 set prefixpolicy $pp.Prefix $NewPrecedence $pp.Label
        } else {
            Write-Output "netsh interface ipv6 set prefixpolicy $($pp.Prefix) $($pp.Precedence) $($pp.Label)"
            netsh interface ipv6 set prefixpolicy $pp.Prefix $pp.Precedence $pp.Label
        }
    }
    Write-Output "プレフィックス[$TARGET_PREFIX]の優先順位を変更しました: (優先順位: $NewPrecedence)"
    Write-Output "現在のプレフィックスポリシー:"
    Get-PrefixPolicies | Format-Table -AutoSize -Property `
        @{Name="優先順位"; Expression={$_.Precedence}} ,`
        @{Name="ラベル"; Expression={$_.Label}}, `
        @{Name="プレフィックス"; Expression={(Add-PrefixInfo $_.Prefix)}}
}

pause