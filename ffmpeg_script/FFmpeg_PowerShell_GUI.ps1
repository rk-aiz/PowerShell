##
# FFMPEG GUI Script
#
<#
    .SYNOPSIS
    Scripts to make ffmpeg easier to use
#>

using namespace System.Text.RegularExpressions;

param(
    [Parameter()]
    [Alias("input")] [string] $path,
    [Parameter()]
    [switch] $StartPaused,
    [Parameter()]
    [switch] $ForceCompileAssembly = $false
)

Set-Location -LiteralPath $PSScriptRoot

# ------------------------------------
# Internal parameter variables
# ------------------------------------
$global:path = $path.trim("`'")

$OUTPUT_DIRECTORY = "Encode"
$OUTPUT_EXTENSION = ".mp4"

$FFMPEG_PARAMETERS = @'
//-hide_banner
-loglevel repeat+verbose
-ignore_unknown
-dn
-y
-i [INPUT]
-analyzeduration 30M -probesize 30M
-c:v libx264
-maxrate 30M
-bufsize 30M
-preset medium
-crf 23
-pix_fmt yuv420p
-c:a aac -ab 256000 -af "channelmap=channel_layout=stereo,aresample=48000:resampler=soxr"
[OUTPUT]
'@

# TODO  detect "Conversion failed!" "Error"

$INPUT_PATTERN = "\[INPUT\]"
$OUTPUT_PATTERN = "\[OUTPUT\]"
$REGEX_OPT = [Text.RegularExpressions.RegexOptions]::IgnoreCase

$TASK_NAME = "$([System.IO.Path]::GetFileName($global:path)) - $($myInvocation.MyCommand.name)"
$AUTO_CLOSE_GUI_WINDOW = $false
$AUTO_PLAY_ENCODED = $false
$OPEN_FOLDER_ENCODED = $false
$PREVENT_SLEEP = $true
$PREVENT_SLEEP_STATE = [UInt32]0x00000002 # $ES_SYSTEM_REQUIRED = [UInt32]0x00000002 : , $ES_DISPLAY_REQUIRED = [UInt32]0x00000002,
$SHOW_CONSOLE_PROGRESSBAR = $false
$ENABLE_ACTIVE_ANIMATION = $true
$FFMPEG_FILE = "ffmpeg.exe"
$FFPROBE_FILE = "ffprobe.exe"

$NO_REDIRECT = $false

$OpenFileScript = {
    param([string]$filePath)
    if ((Test-Path -LiteralPath $filePath)) {
        Invoke-Item -LiteralPath $filePath
    }
}

$OpenExplorerScript = {
    param([string]$filePath)
    if ((Test-Path -LiteralPath $filePath)) {
        Start-Process "explorer.exe" ('/select,"{0}"' -f ($filePath))
    }
}

$CS_SOURCE = "helper.cs"
$CS_ASSEMBLY = "helper.dll"

# ------------------------------------
# Helper functions
# ------------------------------------

# Resolve output file path
function ResolveOutputPath {
    param([string]$path, [string]$extension, [string]$folder)

    ### 拡張子が異なる場吁E
    if ([System.IO.Path]::GetExtension($path) -ne $extension) {
        return ([System.IO.Path]::ChangeExtension($path, $extension))
    }

    ### 拡張子が同じ場吁E
    [System.IO.DirectoryInfo]$di = $(if ([System.IO.Path]::IsPathRooted($folder)) {
        New-Object System.IO.DirectoryInfo($folder)
    } else {
        New-Object System.IO.DirectoryInfo((Join-Path ([System.IO.Path]::GetDirectoryName($path)) $folder))
    })

    if (-not ($di.Exists)) { $di.Create() }

    $result = Join-Path $di.FullName ([System.IO.Path]::GetFileName($path))
    return $result
}

# Show file drop window
# Return whether the window was manually closed
function showDropWindow {
    param([string]$caption, $FFMPEG_PARAMETERS)

    $DropWindowViewModel = New-Object DropWindow.DropWindowViewModel
    $DropWindowViewModel.Title = $caption

    $dropFilesCommand = New-Object DelegateCommand
    $dropFilesCommand.ExecuteHandler = {
        param($param)
        
        $fileList = $param.Data.GetFileDropList()

        switch ($fileList.Count){
            0 { break }
            1
            {
                $global:path = $fileList[0]
                $FileDropWindow.DialogResult = $true
                break
            }
            Default
            {   
                $global:ProcessManagerMode = $true
                $ProcessList = New-Object System.Collections.Generic.List[System.Diagnostics.Process]
                foreach ($f in $fileList) {
                    $proc = Start-Process powershell.exe -PassThru -ArgumentList "-ExecutionPolicy RemoteSigned -File `"$($MyInvocation.ScriptName)`" -path `"$f`" -StartPaused"
                    Start-Sleep -Milliseconds 100
                    $ProcessList.Add($proc)
                }
                $FileDropWindow.DialogResult = $true
                break
            }
        }
    }
    $DropWindowViewModel.DropFilesCommand = $dropFilesCommand

    $FileDropWindow = New-Object DropWindow.MainWindow($DropWindowViewModel)
    return $FileDropWindow.ShowDialog()
}

# Check [$path] parameter
# Return true if the file exists
function checkFilePath {
    param([string]$filePath)

    if ([String]::IsNullOrEmpty($filePath)) { return $false }

    if (-not(Test-Path -LiteralPath $filePath)){
        Write-Host "`"$filePath`" file does not exist." -ForegroundColor Yellow
        return $false
    }

    if ((Get-Item -LiteralPath $filePath).PSIsContainer) {
        Write-Host "`"$filePath`" is a directory." -ForegroundColor Yellow
        return $false
    }

    return $true
}

# ------------------------------------
# Main execution
# ------------------------------------
# Clear the error
$Error.Clear()

[Console]::Write("Start time: ")
[DateTime]::Now

# ------------------------------------
# Check required external files
# for the execution
# check C# .NET Framework source code, ffmpeg.exe exists
# ffprobe.exe is option
# ------------------------------------

# if [$CS_SOURCE] is newer than [$CS_ASSEMBLY], rebuild assembly.
if ((Test-Path $CS_SOURCE) -and (Test-Path $CS_ASSEMBLY)) {
    if ((Get-ItemProperty $CS_SOURCE).LastWriteTime -gt (Get-ItemProperty $CS_ASSEMBLY).LastWriteTime) {
        Write-Host ("Since [$CS_SOURCE] has been updated, recompilation is required.")
        $ForceCompileAssembly = $true
    }
}
# Compile [$CS_SOURCE] if needed.
Try {
    if ($ForceCompileAssembly) {
        throw [System.Management.Automation.RuntimeException] "Request compile assembly."
    }
    
    if (Test-Path $CS_ASSEMBLY) {
        [void][Reflection.Assembly]::LoadFile((Resolve-Path $CS_ASSEMBLY))
        [void][DropWindow.MainWindow]
    } else {
        throw [System.Management.Automation.RuntimeException] "Request compile assembly."
    }
} Catch [System.Management.Automation.RuntimeException] {
    $Error.Clear()
    $null = Add-Type -Path $CS_SOURCE -OutputAssembly $CS_ASSEMBLY -ReferencedAssemblies PresentationFramework, PresentationCore, WindowsBase, System.Xaml -ErrorAction Stop -PassThru
}

######     From here, use [ConsoleHelper] instead of [Write-Host].     ######

# check ffmpeg.exe
[ConsoleHelper]::WriteLine("######    FFmpeg version    ######", 1, 1)
$checkFfmpegProc = $null
try {
    $checkFfmpegProc = Start-Process $FFMPEG_FILE ('-version') -NoNewWindow -PassThru
} catch {
    [ConsoleHelper]::Error("Error : ffmpeg.exe was not found.", 1, 5)
    exit 2
}

# Get console window and set window title
$uniqueWindowTitle = New-Guid
$Host.UI.RawUI.WindowTitle = $uniqueWindowTitle
$ConsoleWindow = New-Object HelperClasses.WindowHelper($uniqueWindowTitle)
$Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.name

$global:ProcessManagerMode = $false

# Show file drop dialog.
while ((checkFilePath $global:path) -ne $true) {

    $ConsoleWindow.HideConsole()

    $result = showDropWindow $myInvocation.MyCommand.name

    $ConsoleWindow.ShowConsole()

    if ($result -ne $true) {
        [ConsoleHelper]::Error("Script execution has been aborted.", 1)
        Start-Sleep 2
        exit 0
    }
    
    if ($global:ProcessManagerMode -eq $true) {
        [ConsoleHelper]::Log("Multiple file mode", 1)
        exit 0
    }
}

if ($null -ne $checkFfmpegProc) {
    $checkFfmpegProc.WaitForExit(1000)
}

# Resolve path for the output file
if ([String]::IsNullOrEmpty($global:output)) {
    $global:output = ResolveOutputPath $global:path $OUTPUT_EXTENSION $OUTPUT_DIRECTORY
}

[ConsoleHelper]::Log("Input file  : $global:path", 2)
[ConsoleHelper]::Log("Output file : $global:output", 0, 1)


# check ffmpeg parameters

$replacedParams = New-Object HelperClasses.CommentOutText($FFMPEG_PARAMETERS)
$replacedParams.Replace($INPUT_PATTERN, "`"$($global:path)`"", $REGEX_OPT)
$replacedParams.Replace($OUTPUT_PATTERN, "`"$($global:output)`"", $REGEX_OPT)

[ConsoleHelper]::Info("######    Encode parameters    ######", 1)
[ConsoleHelper]::Info($replacedParams.GetText("`n"), 1, 3)

# check [$Error]
if ($Error.Count -gt 0) {
    $Error
    exit 1
}

#$FFMPEG_PARAMETERS = GetFFmpegParams $global:path $global:output
$ffmpegProcess = New-Object HelperClasses.ProcessInfo($FFMPEG_FILE, $replacedParams.GetText(" "), $NO_REDIRECT)

$ffprobeParams = @(
    '-v error',
    '-select_streams v:0',
    '-show_entries',
    'stream=r_frame_rate,duration',
    '-of default=nw=1',
    ('"{0}"' -f $global:path)
)
$ffprobeProcess = New-Object HelperClasses.ProcessInfo($FFPROBE_FILE, ($ffprobeParams -join ' '))
$ffprobeTask = $ffprobeProcess.Start()

$syncData = [HashTable]::Synchronized(@{
    path = $global:path
    output = $global:output
    framerateNum = [Double]0
    framerateDen = [Double]0
    duration = [Double]0
    totalFrames = [Double]0
    exitCode = 1
    openfile = $OpenFileScript
    openExplorer = $OpenExplorerScript
    showConsoleProgress = $SHOW_CONSOLE_PROGRESSBAR
    termination = $false
    previousState = $null
})

# Create ViewModel of progress window.
$viewModel = New-Object ProgressWindow.ProgressViewModel

# Create DelegateCommand for command bindings
$showPromptCommand = New-Object DelegateCommand
$showPromptCommand.ExecuteHandler = {
    param($param)
    if ([bool]$param) {
        $ConsoleWindow.ShowConsole($false)
    }else {
        $ConsoleWindow.HideConsole()
    }
}
$viewModel.ShowPromptCommand = $showPromptCommand

$processControlCommand = New-Object DelegateCommand
$processControlCommand.ExecuteHandler = {
    param($param)

    if ([bool]$param) {
        $viewModel.BusyMessage = "On pause."
        $viewModel.Busy = $true
        $viewModel.ProgressState = [ProgressWindow.ProgressState]::Paused
        $ffmpegProcess.Suspend()
    } else {
        $viewModel.ProgressState = [ProgressWindow.ProgressState]::Normal
        $ffmpegProcess.Resume()
    }
}
$viewModel.ProcessControlCommand = $processControlCommand

$processExitCommand = New-Object DelegateCommand
$processExitCommand.ExecuteHandler = {
    param($param)

    [ConsoleHelper]::Log("The program is currently shutting down.", 1)

    $syncData.termination = $true
    $viewModel.ProgressState = [ProgressWindow.ProgressState]::None
    $viewModel.BusyMessage = "Shutting down."
    $viewModel.Busy = $true
    $progressWindow.DoEvents()

    [System.Diagnostics.Process]$process = $null
    if ($ffmpegProcess.TryGetProcess([ref]$process)) {
        $streamWriter = $process.StandardInput
        if ($streamWriter -ne $null) {
            $streamWriter.WriteLine("q") # Send q as an input to the ffmpeg process window making it stop.

            if ($ffmpegProcess.IsSuspended) {
                $ffmpegProcess.Resume()
            }
            return
        }
    }

    $progressWindow.Close()
}
$viewModel.ProcessExitCommand = $processExitCommand

$openFolderCommand = New-Object DelegateCommand
$openFolderCommand.ExecuteHandler = {
    $OpenExplorerScript.Invoke($syncData.output)
}
$viewModel.OpenFolderCommand = $openFolderCommand

$openFileCommand = New-Object DelegateCommand
$openFileCommand.ExecuteHandler = {
    $OpenFileScript.Invoke($syncData.output)
}
$viewModel.OpenFileCommand = $openFileCommand

$changeExecutionStateCommand = New-Object DelegateCommand
$changeExecutionStateCommand.ExecuteHandler = {
    param($param)

    if ($viewModel.PreventSleep -eq $true) {
        [ThreadHelper]::PreventSleep($PREVENT_SLEEP_STATE)
        [ConsoleHelper]::Log("Prevent sleep mode enabled.")
    } else {
        [ThreadHelper]::AllowSleep()
        [ConsoleHelper]::Log("Prevent sleep mode disabled.")
    }
}
$viewModel.ChangeExecutionStateCommand = $changeExecutionStateCommand

# Some commands are fired at the value setter, so the property is set after the command preparation
$viewModel.CurrentOperation = "Preparing."
$viewModel.ProgressLabel = "-> $([System.IO.Path]::GetFileName($global:output))"
$viewModel.WindowTitle = $TASK_NAME
$viewModel.AutoClose = $AUTO_CLOSE_GUI_WINDOW
$viewModel.AutoPlay = $AUTO_PLAY_ENCODED
$viewModel.OpenExplorer = $OPEN_FOLDER_ENCODED
$viewModel.PreventSleep = $PREVENT_SLEEP
$viewModel.EnableActiveAnimation = $ENABLE_ACTIVE_ANIMATION

# ------------------------------------
# Runspace execution
# ------------------------------------
# Handle stderr output from the ffmpeg process
$runspaceScript = {
    param($PSHost, $taskName, $StartPaused)

    $timePattern = "time=\D*([\d\.:]+)"
    $fpsPattern = "fps=\D*(\d+)"
    $framePattern = "frame=\D*(\d+)"
    $durationPattern = "Duration:\D*([\d\.:]+)"

    [HelperClasses.ReceivedData]$ffprobeOutput = [HelperClasses.ReceivedData]::Empty

    # [ProgressRecord] is for console progress bar
    $progressRecord = New-Object System.Management.Automation.ProgressRecord(1, $taskName, 'Initialize')
    $progressRecord.RecordType = [System.Management.Automation.ProgressRecordType]::Processing
    $currentOperation = $syncData.path
    $progressRecord.CurrentOperation = $currentOperation

    $totalDuration = [TimeSpan]::Zero
    $startTime = Get-Date

    $ffmpegTask = $ffmpegProcess.Start()

    $viewModel.CurrentOperation = $currentOperation

    while (-not $ffmpegTask.Wait(500)) {
        foreach ($receivedData in $ffmpegProcess.ReceivedDataQueue.GetConsumingEnumerable())
        {
            switch ($receivedData.Type)
            {
                ('StdOut') { 
                    [ConsoleHelper]::Log($receivedData.Data)
                    break
                }
                ('StdError') {

                    $data = $receivedData.Data

                    if ($data.Contains("frame=")) {

                        if ($syncData.totalFrames -ne 0) {
                            # Calculate progress from frame.
                            $matchFramePettern = [Regex]::Match($data, $framePattern)
                            $matchFpsPettern = [Regex]::Match($data, $fpsPattern)

                            if ($matchFramePettern.Success -and $matchFpsPettern.Success) {

                                $frame = [Double]::Parse($matchFramePettern.Groups[1].Value)
                                $fps = [Double]::Parse($matchFpsPettern.Groups[1].Value)

                                $percentComplete = ($frame / $syncData.totalFrames) * 100.0

                                # Calculate estimated time remaining.
                                if ($fps -gt 1) { 
                                    $remainingTime = ($syncData.totalFrames - $frame) / $fps
                                } else {
                                    $pps = $percentComplete / (((Get-Date) - $startTime).TotalMilliseconds / 1000.0)
                                    if ($pps -gt 0) {
                                        $remainingTime = (100.0 - $percentComplete) / $pps
                                    }
                                }
                            }

                        } elseif ($totalDuration.Ticks -ne 0) {
                            # Calculate progress from time.
                            $match = [Regex]::Match($data, $timePattern)
                            if ($match.Success) {
                                $time = [TimeSpan]::Parse($match.Groups[1].Value)
                                $percentComplete = ($time.Ticks / $totalDuration.Ticks) * 100.0

                                # Calculate estimated time remaining.
                                $pps = $percentComplete / (((Get-Date) - $startTime).TotalMilliseconds / 1000.0)
                                if ($pps -gt 0) {
                                    $remainingTime = (100.0 - $percentComplete) / $pps
                                }
                            }
                        }

                        # [ProgressRecord] is for displaying a progress bar on the console screen.
                        $progressRecord.StatusDescription = $data
                        $progressRecord.PercentComplete = $percentComplete
                        if ($remainingTime -ne $null) {
                            $progressRecord.SecondsRemaining = $remainingTime
                        }
                        if ($syncData.showConsoleProgress) {
                            $PSHost.UI.WriteProgress($progressRecord.ActivityId, $progressRecord)
                            $PSHost.UI.RawUI.WindowTitle = "$($progressRecord.PercentComplete)% $taskName"
                        }

                        # Set progress values in the ViewModel of the GUI window
                        $viewModel.StatusDescription = $data
                        $viewModel.Progress = $percentComplete
                        $viewModel.ProgressRemaining = [TimeSpan]::FromSeconds($remainingTime)
                        $viewModel.WindowTitle = "$($progressRecord.PercentComplete)% $taskName"

                        if ($StartPaused) {
                            [ConsoleHelper]::Info("The process started in paused state")
                            $StartPaused = $false
                            $viewModel.BusyMessage = "On pause."
                            $viewModel.ProcessControlCommand.Execute($true)
                        } elseif((0 -lt $percentComplete) -and ($syncData.termination -eq $false)) {
                            
                            $viewModel.Busy = $false

                            # If progress is 100%, set [RecordType] to Completed.
                            if (100 -gt $percentComplete) {
                            
                                # Set [ProgressState] according to progress
                                $viewModel.ProgressState = [ProgressWindow.ProgressState]::Normal
                            } else {
                                #$viewModel.ProgressState = [ProgressWindow.ProgressState]::Completed

                                # and [ProgressRecord.RecordType]
                                $progressRecord.RecordType = [System.Management.Automation.ProgressRecordType]::Completed
                                $PSHost.UI.WriteProgress($progressRecord.ActivityId, $progressRecord)
                            }
                        }

                    } elseif ($data.Contains("Duration:")) {

                        $match = [Regex]::Match($data, $durationPattern)
                        if ($match.Success) {
                            $totalDuration = [TimeSpan]::Parse($match.Groups[1].Value)
                        }

                    } else {
                        [Console]::WriteLine($data)
                    }
                    break
                }
            }

            # check ffprobe data
            if (($ffprobeProcess.ReceivedDataQueue.Count -gt 0) -and $ffprobeProcess.ReceivedDataQueue.TryTake([ref]$ffprobeOutput)) {
                if ($ffprobeOutput.Type -eq 'StdOut') {

                    $match = [Regex]::Match($ffprobeOutput.Data, "r_frame_rate=(\d+)(/\d+)?")
                    if ($match.Success) {
                        if ($match.Groups[1].Success) {
                            $syncData.framerateNum = [Double]::Parse($match.Groups[1].Value)
                        }

                        if ($match.Groups[2].Success) {
                            $syncData.framerateDen = [Double]::Parse($match.Groups[2].Value.Trim('/'))
                        }
                    }

                    $match = [Regex]::Match($ffprobeOutput.Data, "duration=([\d\.]+)")
                    if ($match.Success) {
                        $syncData.duration = [Double]::Parse($match.Groups[1].Value)
                    }

                    if (($syncData.duration -ne 0) -and ($syncData.framerateDen -ne 0) -and ($syncData.framerateNum -ne 0)) {

                        [ConsoleHelper]::Log("Duration : $($syncData.duration)")
                        [ConsoleHelper]::Log("Frame Rate : $($syncData.framerateNum) / $($syncData.framerateDen)")
                        $syncData.totalFrames = ($syncData.framerateNum / $syncData.framerateDen) * $syncData.duration
                    }
                }
            }
        }
    }
    $syncData.exitCode = $ffmpegTask.GetAwaiter().GetResult()
    $ffmpegProcess.Dispose()

    if (($syncData.exitCode -eq 0) -and ($syncData.termination -eq $false)) {
        
        # --- たまに99.9%でプロセスが終了してしまうようなので対策 ※要調査
        $viewModel.Progress = 100.0
        # -----------------------------------------------------------------
        
        if ($viewModel.AutoPlay) {
            $syncData.openfile.Invoke($syncData.output)
        }
        if ($viewModel.OpenExplorer) {
            $syncData.openExplorer.Invoke($syncData.output)
        }
    }

    if (($viewModel.AutoClose -eq $true) -or ($syncData.termination -eq $true)) {
        Start-Sleep 1
        $closing = $progressWindow.Close()
        if (-not ($closing.Wait(1000))) {
            [ConsoleHelper]::Log("Lost control of the GUI window.", 1)
            $syncData.exitCode = 1003
        }
    }

    foreach ($e in $Error) {
        [ConsoleHelper]::Error($e, 1)
        $syncData.exitCode = 1
    }
}

try{
    $progressWindow = New-Object ProgressWindow.MainWindow($viewModel)
} catch {
    $Error
    exit 1
}

# Create and setup runspace
$Runspace = [RunSpaceFactory]::CreateRunspace()
$Runspace.ApartmentState = "STA"
$Runspace.Open()
$Runspace.SessionStateProxy.setVariable("ffmpegProcess", $ffmpegProcess)
$Runspace.SessionStateProxy.setVariable("ffprobeProcess", $ffprobeProcess)
$Runspace.SessionStateProxy.setVariable("progressWindow", $progressWindow)
$Runspace.SessionStateProxy.setVariable("syncData", $syncData)
$Runspace.SessionStateProxy.setVariable("viewModel", $viewModel)
$PowerShell = [PowerShell]::Create().AddScript($runspaceScript).AddArgument($Host).AddArgument($TASK_NAME).AddArgument($StartPaused)
$PowerShell.Runspace = $Runspace
$IASyncResult = $PowerShell.BeginInvoke()

# Hide console
$viewModel.ShowPromptCommand.Execute($false)

# Show WPF window
$result = $false
try{
    $result = $progressWindow.ShowDialog();
} catch {
    $Error
}

if (($Error.Count -gt 0) -or ($result -ne $true)) {
    $processExitCommand.Execute($null)
    $viewModel.ShowPromptCommand.Execute($true)
}

if($IASyncResult.AsyncWaitHandle.WaitOne()){
    $PowerShell.EndInvoke($IASyncResult)
    $PowerShell.Dispose()
}

if (($syncData.exitCode -eq 0) -and (Test-Path -LiteralPath ($global:output)) ) {
    Start-Sleep 1
    exit 0
} else {
    $viewModel.ShowPromptCommand.Execute($true)
    exit 1
}