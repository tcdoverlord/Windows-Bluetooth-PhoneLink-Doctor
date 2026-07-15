# PhoneLink-Bluetooth-Doctor
# Created by TCDOVERLORD
# Consent-first diagnostics and safe repair for Windows Phone Link Bluetooth audio.

[CmdletBinding()]
param(
    [switch]$DiagnoseOnly,
    [switch]$NonInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:RepoRoot = Split-Path -Parent $PSScriptRoot
$script:LogsRoot = Join-Path $script:RepoRoot 'logs'
$script:RunStamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
$script:RunRoot = Join-Path $script:LogsRoot $script:RunStamp
$script:SummaryLog = Join-Path $script:RunRoot '00-Diagnostic-Summary.txt'
$script:KnownLog = Join-Path $script:RunRoot '01-Known-Devices.txt'
$script:UnknownLog = Join-Path $script:RunRoot '02-Unknown-and-Error-Devices.txt'
$script:SpeakerLog = Join-Path $script:RunRoot '03-Speakers.txt'
$script:MicLog = Join-Path $script:RunRoot '04-Microphones.txt'
$script:BluetoothLog = Join-Path $script:RunRoot '05-Bluetooth-Devices.txt'
$script:ServicesLog = Join-Path $script:RunRoot '06-Services.txt'
$script:DriversLog = Join-Path $script:RunRoot '07-Drivers.txt'
$script:EventsLog = Join-Path $script:RunRoot '08-Recent-Events.txt'
$script:RepairLog = Join-Path $script:RunRoot '09-Repair-Actions.txt'
$script:CrossRefLog = Join-Path $script:RunRoot '10-Audio-Cross-Reference.txt'
$script:JsonLog = Join-Path $script:RunRoot '11-Diagnostic-Data.json'
$script:SelectionLog = Join-Path $script:RunRoot '12-Selected-Devices.txt'
$script:ConfigRoot = Join-Path $script:RepoRoot 'config'
$script:SelectionFile = Join-Path $script:ConfigRoot 'device-selection.json'
$script:PendingRestartFile = Join-Path $script:ConfigRoot 'pending-post-restart.json'
$script:RestartRecommended = $false

$script:ProgressScript = Join-Path $PSScriptRoot 'PhoneLink-Progress.ps1'
if (-not (Test-Path -LiteralPath $script:ProgressScript)) {
    throw "Required progress component is missing: $script:ProgressScript"
}
. $script:ProgressScript
Reset-DoctorProgress -Activity 'Phone Link Bluetooth Doctor' -Phase 'Ready'

New-Item -ItemType Directory -Path $script:RunRoot -Force | Out-Null
New-Item -ItemType Directory -Path $script:ConfigRoot -Force | Out-Null

function Write-Section {
    param([string]$Title)
    Write-Host "`n=== $Title ===" -ForegroundColor Cyan
}

function Write-LogLine {
    param(
        [string]$Path,
        [string]$Message
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "[$timestamp] $Message" | Out-File -FilePath $Path -Append -Encoding utf8 -Width 500
}

function Export-TextReport {
    param(
        [Parameter(Mandatory)]$InputObject,
        [Parameter(Mandatory)][string]$Path,
        [string[]]$Properties
    )

    if ($Properties) {
        $InputObject | Select-Object $Properties | Format-Table -AutoSize -Wrap | Out-String -Width 500 |
            Out-File -FilePath $Path -Encoding utf8 -Width 500
    }
    else {
        $InputObject | Format-List * | Out-String -Width 500 |
            Out-File -FilePath $Path -Encoding utf8 -Width 500
    }
}

function Get-SafePnpDevices {
    try { @(Get-PnpDevice -ErrorAction Stop) }
    catch {
        Write-LogLine -Path $script:SummaryLog -Message "Get-PnpDevice failed: $($_.Exception.Message)"
        @()
    }
}


function Get-DeviceSelection {
    if (-not (Test-Path $script:SelectionFile)) { return $null }
    try {
        return Get-Content -LiteralPath $script:SelectionFile -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-LogLine -Path $script:SummaryLog -Message "Could not read device selection: $($_.Exception.Message)"
        return $null
    }
}

function Show-NumberedChoice {
    param(
        [Parameter(Mandatory)][array]$Items,
        [Parameter(Mandatory)][string]$Title,
        [Parameter(Mandatory)][scriptblock]$Label
    )

    Write-Section $Title
    for ($i = 0; $i -lt $Items.Count; $i++) {
        $text = & $Label $Items[$i]
        Write-Host ("[{0}] {1}" -f ($i + 1), $text)
    }

    while ($true) {
        $answer = Read-Host "Choose 1-$($Items.Count), or Q to cancel"
        if ($answer -match '^(?i)q$') { return $null }
        $number = 0
        if ([int]::TryParse($answer, [ref]$number) -and $number -ge 1 -and $number -le $Items.Count) {
            return $Items[$number - 1]
        }
        Write-Host 'Invalid selection.' -ForegroundColor Red
    }
}

function Set-DeviceSelection {
    $all = Get-SafePnpDevices
    $audio = @($all | Where-Object Class -eq 'AudioEndpoint')
    $speakers = @($audio | Where-Object FriendlyName -match '(?i)speaker|headphone|headset|output' | Sort-Object FriendlyName)
    $mics = @($audio | Where-Object FriendlyName -match '(?i)microphone|mic|input' | Sort-Object FriendlyName)
    $phones = @($all | Where-Object {
        $_.Class -eq 'Bluetooth' -and $_.FriendlyName -and
        $_.FriendlyName -notmatch '(?i)enumerator|adapter|transport|service|profile|protocol|attribute|access'
    } | Sort-Object FriendlyName -Unique)

    if ($speakers.Count -eq 0 -or $mics.Count -eq 0 -or $phones.Count -eq 0) {
        Write-Host 'One or more required device lists are empty. Run diagnostics and review the logs.' -ForegroundColor Red
        return $false
    }

    $speaker = Show-NumberedChoice -Items $speakers -Title 'Choose the PC speaker/headphone device to cross-reference' -Label {
        param($d) "$($d.Status) | $($d.FriendlyName)"
    }
    if (-not $speaker) { return $false }

    $mic = Show-NumberedChoice -Items $mics -Title 'Choose the PC microphone device to cross-reference' -Label {
        param($d) "$($d.Status) | $($d.FriendlyName)"
    }
    if (-not $mic) { return $false }

    while ($true) {
        Write-Section 'Choose the Bluetooth phone/device used by Phone Link'
        Write-Host 'Select the actual phone connected to Microsoft Phone Link.' -ForegroundColor White
        Write-Host ''
        Write-Host 'What to look for:' -ForegroundColor Yellow
        Write-Host '  - Choose your phone name or phone model.'
        Write-Host '  - Do not choose earbuds, headphones, controllers, or other accessories.'
        Write-Host '  - Phone examples: Nokia G300, iPhone, Samsung Galaxy, Motorola, or Pixel.'
        Write-Host '  - Check the Phone Link app if you are unsure which phone is connected.'
        Write-Host '  - You can change this selection later from main-menu option 2.'
        Write-Host ''
        Write-Host 'This choice is used only for diagnosis and repair targeting.' -ForegroundColor Green
        Write-Host 'It does not pair, unpair, remove, rename, or uninstall the device.' -ForegroundColor Green
        Write-Host ''

        for ($i = 0; $i -lt $phones.Count; $i++) {
            $device = $phones[$i]
            Write-Host ("[{0}] {1} | {2}" -f ($i + 1), $device.Status, $device.FriendlyName)
        }

        Write-Host ''
        $answer = Read-Host "Choose 1-$($phones.Count), or Q to cancel"
        if ($answer -match '^(?i)q$') { return $false }

        $number = 0
        if (-not [int]::TryParse($answer, [ref]$number) -or $number -lt 1 -or $number -gt $phones.Count) {
            Write-Host 'Invalid selection. Please choose one of the listed numbers.' -ForegroundColor Red
            continue
        }

        $phone = $phones[$number - 1]
        $looksLikePhone = $phone.FriendlyName -match '(?i)phone|iphone|nokia|samsung|galaxy|motorola|moto|pixel|android|oneplus|lg|huawei'

        Write-Host ''
        Write-Host 'You selected:' -ForegroundColor Cyan
        Write-Host "  $($phone.FriendlyName)" -ForegroundColor Yellow

        if ($looksLikePhone) {
            Write-Host 'This appears to be a phone selection.' -ForegroundColor Green
        }
        else {
            Write-Host 'This device does not appear to be a phone.' -ForegroundColor DarkYellow
            Write-Host 'That may be intentional, but Phone Link normally requires the actual mobile phone.' -ForegroundColor DarkYellow
        }

        Write-Host ''
        Write-Host '[1] Keep this selection'
        Write-Host '[2] Choose a different device'
        Write-Host '[Q] Cancel'
        $confirmPhone = Read-Host 'Choose 1, 2, or Q'

        if ($confirmPhone -eq '1') { break }
        if ($confirmPhone -eq '2') { continue }
        if ($confirmPhone -match '^(?i)q$') { return $false }

        Write-Host 'Invalid choice. Returning to the Bluetooth device list.' -ForegroundColor Red
    }

    Write-Section 'Review selected devices'
    Write-Host "Speaker:  $($speaker.FriendlyName)" -ForegroundColor Yellow
    Write-Host "Microphone: $($mic.FriendlyName)" -ForegroundColor Yellow
    Write-Host "Bluetooth: $($phone.FriendlyName)" -ForegroundColor Yellow
    Write-Host ''
    Write-Host 'This saves targets for diagnosis and repair. It does not change the Windows default speaker or microphone.' -ForegroundColor Green
    $accept = Read-Host 'Type ACCEPT exactly to save these choices'
    if ($accept -cne 'ACCEPT') {
        Write-Host 'Choices were not saved. No changes were made.' -ForegroundColor Yellow
        return $false
    }

    $selection = [ordered]@{
        SavedAt = (Get-Date).ToString('o')
        SpeakerName = $speaker.FriendlyName
        SpeakerInstanceId = $speaker.InstanceId
        MicrophoneName = $mic.FriendlyName
        MicrophoneInstanceId = $mic.InstanceId
        BluetoothName = $phone.FriendlyName
        BluetoothInstanceId = $phone.InstanceId
    }
    $selection | ConvertTo-Json -Depth 4 | Out-File -LiteralPath $script:SelectionFile -Encoding utf8
    Write-Host "Saved selection to: $script:SelectionFile" -ForegroundColor Green
    return $true
}

function Write-SelectionReport {
    param($Selection)
    if (-not $Selection) {
        'No saved device selection.' | Out-File -FilePath $script:SelectionLog -Encoding utf8
        return
    }
    @(
        "SavedAt: $($Selection.SavedAt)",
        "SpeakerName: $($Selection.SpeakerName)",
        "SpeakerInstanceId: $($Selection.SpeakerInstanceId)",
        "MicrophoneName: $($Selection.MicrophoneName)",
        "MicrophoneInstanceId: $($Selection.MicrophoneInstanceId)",
        "BluetoothName: $($Selection.BluetoothName)",
        "BluetoothInstanceId: $($Selection.BluetoothInstanceId)"
    ) | Out-File -FilePath $script:SelectionLog -Encoding utf8
}

function Get-PhoneLinkProcesses {
    $names = 'PhoneExperienceHost','YourPhone','CrossDeviceService','CrossDeviceResume'
    @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -in $names })
}

function Get-Diagnostics {
    Reset-DoctorProgress -Activity 'Phone Link Bluetooth Doctor' -Phase 'Collecting diagnostics'
    Write-Section 'Collecting diagnostics'
    Write-ProgressLine -State Info -Message 'The diagnostic can take a minute. The window is still working.'
    Write-ProgressLine -Message 'Reading all Windows Plug and Play devices...'

    $allDevices = Get-SafePnpDevices
    Write-ProgressLine -State Success -Message ("Device inventory complete: {0} devices found." -f @($allDevices).Count)

    Write-ProgressLine -Message 'Loading saved speaker, microphone, and Bluetooth selections...'
    $selection = Get-DeviceSelection
    Write-SelectionReport -Selection $selection
    Write-ProgressLine -State Success -Message 'Saved selection check complete.'

    Write-ProgressLine -Message 'Separating speakers, microphones, Bluetooth devices, and device errors...'
    $audioEndpoints = @($allDevices | Where-Object Class -eq 'AudioEndpoint')
    $microphones = @($audioEndpoints | Where-Object FriendlyName -match '(?i)microphone|mic|input')
    $speakers = @($audioEndpoints | Where-Object FriendlyName -match '(?i)speaker|headphone|headset|output|audio')
    $bluetooth = @($allDevices | Where-Object {
        $_.Class -eq 'Bluetooth' -or $_.FriendlyName -match '(?i)bluetooth|hands-free|handsfree|a2dp|avrcp|phonebook|nokia|iphone|android|phone'
    })
    $known = @($allDevices | Where-Object Status -eq 'OK')
    $unknown = @($allDevices | Where-Object Status -ne 'OK')

    Write-ProgressLine -Message 'Checking Windows Audio, Bluetooth, Phone Link, and device services...'
    $servicePatterns = @('bthserv','BTAGService','DeviceAssociationService','DevicesFlowUserSvc*','CDPUserSvc*','PhoneSvc','AudioSrv','AudioEndpointBuilder')
    $services = @(
        Get-Service -ErrorAction SilentlyContinue |
        Where-Object {
            $n = $_.Name
            @($servicePatterns | Where-Object { $n -like $_ }).Count -gt 0
        } |
        Sort-Object Name
    )

    Write-ProgressLine -State Success -Message ("Service scan complete: {0} related services found." -f @($services).Count)
    Write-ProgressLine -Message 'Reading Bluetooth and audio driver information...'

    $drivers = @(Get-CimInstance Win32_PnPSignedDriver -ErrorAction SilentlyContinue | Where-Object {
        $_.DeviceClass -in @('BLUETOOTH','MEDIA') -or $_.DeviceName -match '(?i)bluetooth|hands-free|realtek|audio'
    } | Sort-Object DeviceName)

    Write-ProgressLine -State Success -Message ("Driver scan complete: {0} related drivers found." -f @($drivers).Count)
    Write-ProgressLine -Message 'Reviewing recent Windows event logs for Bluetooth and audio warnings...'

    $events = @()
    try {
        $events = @(Get-WinEvent -FilterHashtable @{ LogName='System'; StartTime=(Get-Date).AddDays(-3) } -ErrorAction Stop |
            Where-Object {
                $_.LevelDisplayName -in @('Error','Warning') -and $_.Message -match '(?i)bluetooth|bth|audio|phone link|cross device|hands-free'
            } | Select-Object -First 100 TimeCreated, Id, LevelDisplayName, ProviderName, Message)
    } catch {
        Write-ProgressLine -State Warning -Message 'Some Windows event logs were unavailable. The diagnostic will continue.'
    }

    Write-ProgressLine -State Success -Message ("Event review complete: {0} relevant events collected." -f @($events).Count)
    Write-ProgressLine -Message 'Cross-referencing phone, speaker, microphone, and hands-free audio endpoints...'

    $crossRef = foreach ($endpoint in $audioEndpoints) {
        $related = @($allDevices | Where-Object {
            $_.InstanceId -and $endpoint.InstanceId -and (
                $_.FriendlyName -eq $endpoint.FriendlyName -or
                ($endpoint.FriendlyName -match '(?i)nokia|phone|hands-free|handsfree' -and $_.FriendlyName -match '(?i)nokia|phone|hands-free|handsfree')
            )
        })

        [pscustomobject]@{
            EndpointStatus = $endpoint.Status
            EndpointName = $endpoint.FriendlyName
            EndpointInstanceId = $endpoint.InstanceId
            RelatedDeviceCount = $related.Count
            RelatedStatuses = (($related | ForEach-Object { "$($_.Status):$($_.Class):$($_.FriendlyName)" }) -join ' | ')
            SuggestedAction = switch ($endpoint.Status) {
                'OK' { 'No repair required' }
                'Unknown' { 'Rescan devices, restart audio/Bluetooth services, re-enable endpoint if disabled' }
                'Error' { 'Restart audio services, rescan devices, inspect driver and event logs' }
                default { 'Review device state and run safe repair' }
            }
        }
    }

    Write-ProgressLine -State Success -Message ("Cross-reference complete: {0} audio endpoints reviewed." -f @($crossRef).Count)
    Write-ProgressLine -Message 'Writing detailed diagnostic reports to the logs folder...'

    Export-TextReport -InputObject $known -Path $script:KnownLog -Properties @('Status','Class','FriendlyName','InstanceId')
    Export-TextReport -InputObject $unknown -Path $script:UnknownLog -Properties @('Status','Problem','Class','FriendlyName','InstanceId')
    Export-TextReport -InputObject $speakers -Path $script:SpeakerLog -Properties @('Status','Class','FriendlyName','InstanceId')
    Export-TextReport -InputObject $microphones -Path $script:MicLog -Properties @('Status','Class','FriendlyName','InstanceId')
    Export-TextReport -InputObject $bluetooth -Path $script:BluetoothLog -Properties @('Status','Problem','Class','FriendlyName','InstanceId')
    Export-TextReport -InputObject $services -Path $script:ServicesLog -Properties @('Status','StartType','Name','DisplayName')
    Export-TextReport -InputObject $drivers -Path $script:DriversLog -Properties @('DeviceName','Manufacturer','DriverProviderName','DriverVersion','DriverDate','InfName')
    Export-TextReport -InputObject $events -Path $script:EventsLog
    Export-TextReport -InputObject $crossRef -Path $script:CrossRefLog -Properties @('EndpointStatus','EndpointName','RelatedDeviceCount','RelatedStatuses','SuggestedAction')

    $phonePattern = '(?i)phone|nokia|hands-free|handsfree'
    if ($selection -and $selection.BluetoothName) {
        $escapedPhoneName = [regex]::Escape([string]$selection.BluetoothName)
        $phonePattern = "(?i)$escapedPhoneName|hands-free|handsfree"
    }
    $phoneLikeEndpoints = @($audioEndpoints | Where-Object FriendlyName -match $phonePattern)
    $brokenPhoneEndpoints = @($phoneLikeEndpoints | Where-Object Status -ne 'OK')

    $summary = [ordered]@{
        Timestamp = (Get-Date).ToString('o')
        ComputerName = $env:COMPUTERNAME
        UserName = $env:USERNAME
        Windows = (Get-CimInstance Win32_OperatingSystem).Caption
        RepoRoot = $script:RepoRoot
        RunLogFolder = $script:RunRoot
        TotalDevices = $allDevices.Count
        KnownDevices = $known.Count
        UnknownOrErrorDevices = $unknown.Count
        AudioEndpoints = $audioEndpoints.Count
        Speakers = $speakers.Count
        Microphones = $microphones.Count
        BluetoothRelatedDevices = $bluetooth.Count
        SelectedSpeaker = if ($selection) { $selection.SpeakerName } else { 'Not configured' }
        SelectedMicrophone = if ($selection) { $selection.MicrophoneName } else { 'Not configured' }
        SelectedBluetooth = if ($selection) { $selection.BluetoothName } else { 'Not configured' }
        PhoneAudioEndpoints = $phoneLikeEndpoints.Count
        BrokenPhoneAudioEndpoints = $brokenPhoneEndpoints.Count
        PhoneLinkProcesses = (Get-PhoneLinkProcesses | Select-Object -ExpandProperty ProcessName -Unique) -join ', '
        SuggestedRepair = if ($brokenPhoneEndpoints.Count -gt 0) {
            'Run the safe Phone Link repair: enable disabled phone endpoints, restart services, rescan devices, and restart Phone Link processes.'
        } else {
            'No broken Phone Link endpoint was detected. Review logs before changing anything.'
        }
    }

    $summary.GetEnumerator() | ForEach-Object { "{0}: {1}" -f $_.Key, $_.Value } |
        Out-File -FilePath $script:SummaryLog -Encoding utf8 -Width 500

    [pscustomobject]@{
        Summary = $summary
        AllDevices = $allDevices
        AudioEndpoints = $audioEndpoints
        Microphones = $microphones
        Speakers = $speakers
        Bluetooth = $bluetooth
        Services = $services
        Drivers = $drivers
        Events = $events
        CrossReference = $crossRef
        Selection = $selection
        BrokenPhoneEndpoints = $brokenPhoneEndpoints
    } | ConvertTo-Json -Depth 6 | Out-File -FilePath $script:JsonLog -Encoding utf8 -Width 1000

    Write-ProgressLine -State Success -Message 'All diagnostic reports were created successfully.' -Percent 100
    Complete-DoctorProgress -Message 'Diagnostics completed.'
    Write-Host "Diagnostic logs saved to:`n$script:RunRoot" -ForegroundColor Green
    Write-Host "Broken Phone Link audio endpoints detected: $($brokenPhoneEndpoints.Count)" -ForegroundColor Yellow

    return [pscustomobject]@{
        AllDevices = $allDevices
        AudioEndpoints = $audioEndpoints
        BrokenPhoneEndpoints = $brokenPhoneEndpoints
        Summary = $summary
    }
}


function Get-ServiceStateText {
    param([Parameter(Mandatory)][string]$Name)

    $output = (& sc.exe queryex $Name 2>&1 | Out-String)
    if ($output -match 'STATE\s+:\s+\d+\s+(\S+)') {
        return $matches[1]
    }
    return 'UNKNOWN'
}

function Enable-RequiredPhoneService {
    $svc = Get-Service -Name 'PhoneSvc' -ErrorAction SilentlyContinue
    if (-not $svc) {
        Write-LogLine -Path $script:RepairLog -Message 'PhoneSvc is not present on this Windows installation.'
        return
    }

    if ($svc.StartType -eq 'Disabled') {
        Write-ProgressLine -Message 'Phone Service is disabled. Changing it to Manual startup...'
        try {
            Set-Service -Name 'PhoneSvc' -StartupType Manual -ErrorAction Stop
            Write-LogLine -Path $script:RepairLog -Message 'Changed PhoneSvc startup type from Disabled to Manual.'
            $script:RestartRecommended = $true
        }
        catch {
            Write-LogLine -Path $script:RepairLog -Message "Could not change PhoneSvc startup type: $($_.Exception.Message)"
            Write-ProgressLine -State Warning -Message 'Phone Service could not be enabled automatically.'
            return
        }
    }

    $svc.Refresh()
    if ($svc.Status -ne 'Running') {
        try {
            Start-Service -Name 'PhoneSvc' -ErrorAction Stop
            Write-LogLine -Path $script:RepairLog -Message 'Started PhoneSvc.'
        }
        catch {
            Write-LogLine -Path $script:RepairLog -Message "Could not start PhoneSvc: $($_.Exception.Message)"
            Write-ProgressLine -State Warning -Message 'Phone Service could not be started.'
        }
    }
}

function Show-WindowsCallAudioSetup {
    $selection = Get-DeviceSelection
    if (-not $selection) {
        Write-Host 'No saved device choices exist yet.' -ForegroundColor Yellow
        if (-not (Set-DeviceSelection)) { return }
        $selection = Get-DeviceSelection
    }

    Write-Section 'Configure Windows call audio'
    Write-Host 'The Doctor can save your choices, but Phone Link uses the Windows default communications devices.' -ForegroundColor Yellow
    Write-Host ''
    Write-Host "Chosen speaker:   $($selection.SpeakerName)" -ForegroundColor Cyan
    Write-Host "Chosen microphone: $($selection.MicrophoneName)" -ForegroundColor Cyan
    Write-Host ''
    Write-Host 'You will set each chosen device as both:' -ForegroundColor White
    Write-Host '  - Default Device'
    Write-Host '  - Default Communication Device'
    Write-Host ''
    Write-Host 'Step 1: Playback devices will open.' -ForegroundColor Green
    Write-Host 'Right-click your chosen speaker, set it as Default Device, then as Default Communication Device.'
    Read-Host 'Press ENTER to open Playback devices'
    Start-Process control.exe -ArgumentList 'mmsys.cpl,,0'
    Read-Host 'Finish the Playback changes, then press ENTER here'

    Write-Host ''
    Write-Host 'Step 2: Recording devices will open.' -ForegroundColor Green
    Write-Host 'Right-click your chosen microphone, set it as Default Device, then as Default Communication Device.'
    Write-Host 'Speak into it and confirm the green level meter moves.'
    Read-Host 'Press ENTER to open Recording devices'
    Start-Process control.exe -ArgumentList 'mmsys.cpl,,1'
    Read-Host 'Finish the Recording changes, then press ENTER here'

    Write-Host ''
    Write-Host 'Windows call-audio setup guidance is complete.' -ForegroundColor Green
    Write-Host 'Close and reopen Phone Link before testing another call.' -ForegroundColor Yellow
    Write-LogLine -Path $script:RepairLog -Message "User completed Windows audio setup guidance for speaker '$($selection.SpeakerName)' and microphone '$($selection.MicrophoneName)'."
}

function Reset-DoctorSelections {
    Write-Section 'Reset Doctor selections'
    Write-Host 'This resets only the choices saved by Phone Link Bluetooth Doctor.' -ForegroundColor Yellow
    Write-Host 'It does not remove devices, unpair Bluetooth, delete drivers, or reset Windows audio.' -ForegroundColor Green
    $answer = Read-Host 'Type RESET exactly to clear saved selections and begin setup again'
    if ($answer -cne 'RESET') {
        Write-Host 'Reset cancelled. No changes were made.' -ForegroundColor Yellow
        return
    }

    if (Test-Path -LiteralPath $script:SelectionFile) {
        Remove-Item -LiteralPath $script:SelectionFile -Force
    }
    if (Test-Path -LiteralPath $script:PendingRestartFile) {
        Remove-Item -LiteralPath $script:PendingRestartFile -Force
    }

    Write-Host 'Saved Doctor selections were cleared.' -ForegroundColor Green
    [void](Set-DeviceSelection)
}

function Save-PendingRestart {
    param([string]$Reason)

    [ordered]@{
        CreatedAt = (Get-Date).ToString('o')
        Reason = $Reason
        LogFolder = $script:RunRoot
    } | ConvertTo-Json | Out-File -LiteralPath $script:PendingRestartFile -Encoding utf8
}

function Show-RestartPrompt {
    if (-not $script:RestartRecommended) { return }

    Save-PendingRestart -Reason 'Windows must finish rebuilding the Phone Link Bluetooth hands-free audio stack.'

    Clear-Host
    Write-Host ''
    Write-Host '######################################################################' -ForegroundColor Yellow
    Write-Host '#                                                                    #' -ForegroundColor Yellow
    Write-Host '#                  RESTART THE COMPUTER NOW!                         #' -ForegroundColor Red
    Write-Host '#                                                                    #' -ForegroundColor Yellow
    Write-Host '######################################################################' -ForegroundColor Yellow
    Write-Host ''
    Write-Host 'The Phone Link Bluetooth Doctor repair is complete.' -ForegroundColor Green
    Write-Host 'Windows must restart before you test Phone Link again.' -ForegroundColor Yellow
    Write-Host 'Save your work, close this Doctor, and restart the computer.' -ForegroundColor White
    Write-Host ''

    do {
        $closeChoice = Read-Host 'Type EXIT to close Phone Link Bluetooth Doctor'
        if ($closeChoice -ine 'EXIT') {
            Write-Host 'Please type EXIT exactly to close.' -ForegroundColor Yellow
        }
    } until ($closeChoice -ieq 'EXIT')

    exit 0
}

function Invoke-PostRestartCheck {
    if (-not (Test-Path -LiteralPath $script:PendingRestartFile)) { return }

    Write-Section 'Post-restart verification available'
    Write-Host 'The Doctor detected a repair that requested a Windows restart.' -ForegroundColor Green
    $answer = Read-Host 'Run a fresh verification now? Type YES to continue'
    if ($answer -ceq 'YES') {
        Get-Diagnostics | Out-Null
        Remove-Item -LiteralPath $script:PendingRestartFile -Force -ErrorAction SilentlyContinue
        Write-Host 'Post-restart verification completed.' -ForegroundColor Green
    }
}

function Confirm-Action {
    param([string]$Message)
    if ($NonInteractive) { return $false }
    $answer = Read-Host "$Message Type YES to continue"
    return $answer -ceq 'YES'
}

function Enable-PhoneAudioEndpoints {
    param([array]$Endpoints)

    foreach ($endpoint in $Endpoints) {
        Write-LogLine -Path $script:RepairLog -Message "Reviewing endpoint: $($endpoint.Status) | $($endpoint.FriendlyName) | $($endpoint.InstanceId)"
        try {
            Enable-PnpDevice -InstanceId $endpoint.InstanceId -Confirm:$false -ErrorAction Stop
            Write-LogLine -Path $script:RepairLog -Message "Enable requested successfully: $($endpoint.FriendlyName)"
        } catch {
            Write-LogLine -Path $script:RepairLog -Message "Enable skipped/failed for $($endpoint.FriendlyName): $($_.Exception.Message)"
        }
    }
}

function Restart-SafeServices {
    Enable-RequiredPhoneService

    $safeRestartTargets = @('AudioEndpointBuilder','Audiosrv','bthserv','DeviceAssociationService')
    foreach ($name in $safeRestartTargets) {
        $svc = Get-Service -Name $name -ErrorAction SilentlyContinue
        if (-not $svc) {
            Write-LogLine -Path $script:RepairLog -Message "Service not present: $name"
            continue
        }

        try {
            Restart-Service -Name $name -Force -ErrorAction Stop
            Write-LogLine -Path $script:RepairLog -Message "Restarted service: $name"
        }
        catch {
            Write-LogLine -Path $script:RepairLog -Message "Service action failed for ${name}: $($_.Exception.Message)"
            Write-ProgressLine -State Warning -Message "Windows could not restart service $name. Continuing safely."
        }
    }

    # BTAGService can hang in STOP_PENDING. Never force-kill its svchost process.
    $btag = Get-Service -Name 'BTAGService' -ErrorAction SilentlyContinue
    if ($btag) {
        $state = Get-ServiceStateText -Name 'BTAGService'
        if ($state -eq 'STOP_PENDING') {
            Write-LogLine -Path $script:RepairLog -Message 'BTAGService is stuck in STOP_PENDING. A Windows restart is required.'
            Write-ProgressLine -State Warning -Message 'Bluetooth Audio Gateway Service is waiting to stop. Windows restart required.'
            $script:RestartRecommended = $true
        }
        elseif ($btag.Status -eq 'Running') {
            Write-LogLine -Path $script:RepairLog -Message 'BTAGService is already running; skipped forced restart to avoid a service hang.'
        }
        else {
            try {
                Start-Service -Name 'BTAGService' -ErrorAction Stop
                Write-LogLine -Path $script:RepairLog -Message 'Started BTAGService.'
            }
            catch {
                Write-LogLine -Path $script:RepairLog -Message "Could not start BTAGService: $($_.Exception.Message)"
                $script:RestartRecommended = $true
            }
        }
    }
}

function Restart-PhoneLinkProcesses {
    $processes = Get-PhoneLinkProcesses
    foreach ($process in $processes) {
        try {
            Stop-Process -Id $process.Id -Force -ErrorAction Stop
            Write-LogLine -Path $script:RepairLog -Message "Stopped Phone Link related process: $($process.ProcessName) PID $($process.Id)"
        } catch {
            Write-LogLine -Path $script:RepairLog -Message "Could not stop process $($process.ProcessName): $($_.Exception.Message)"
        }
    }

    try {
        Start-Process 'ms-phone:' -ErrorAction Stop
        Write-LogLine -Path $script:RepairLog -Message 'Requested Phone Link relaunch using ms-phone URI.'
    } catch {
        Write-LogLine -Path $script:RepairLog -Message "Phone Link relaunch failed: $($_.Exception.Message)"
    }
}

function Invoke-SafeRepair {
    param([array]$BrokenPhoneEndpoints)

    Reset-DoctorProgress -Activity 'Phone Link Bluetooth Doctor' -Phase 'Preparing safe repair'
    Write-Section 'Proposed safe repair'
    Write-Host 'This repair performs ONLY these reversible actions:' -ForegroundColor Yellow
    Write-Host '  1. Request enable on non-OK phone audio endpoints.'
    Write-Host '  2. Restart Windows Audio and Bluetooth services.'
    Write-Host '  3. Ask Windows to rescan Plug and Play devices.'
    Write-Host '  4. Restart Phone Link related processes.'
    Write-Host 'It does NOT remove, uninstall, forget, unpair, or delete any device.' -ForegroundColor Green

    $selection = Get-DeviceSelection
    if (-not $selection) {
        Write-Host 'No saved device selection exists. Choose devices before repair.' -ForegroundColor Yellow
        if (-not (Set-DeviceSelection)) {
            Write-LogLine -Path $script:RepairLog -Message 'Repair cancelled because device selection was not accepted.'
            return
        }
        $selection = Get-DeviceSelection
    }

    Write-Section 'Final device authorization'
    Write-Host "Speaker selected for cross-reference: $($selection.SpeakerName)"
    Write-Host "Microphone selected for cross-reference: $($selection.MicrophoneName)"
    Write-Host "Bluetooth device selected for Phone Link: $($selection.BluetoothName)"
    Write-Host 'No device will be removed, unpaired, forgotten, or uninstalled.' -ForegroundColor Green
    $accept = Read-Host 'Type ACCEPT exactly to authorize work on these selected devices'
    if ($accept -cne 'ACCEPT') {
        Write-LogLine -Path $script:RepairLog -Message 'User did not type ACCEPT at final authorization.'
        Write-Host 'No changes were made.' -ForegroundColor Yellow
        return
    }

    if (-not (Confirm-Action 'Apply the listed safe repair now?')) {
        Write-LogLine -Path $script:RepairLog -Message 'User declined repair at YES confirmation.'
        Write-Host 'No changes were made.' -ForegroundColor Yellow
        return
    }

    Write-LogLine -Path $script:RepairLog -Message "User approved safe repair for Bluetooth device '$($selection.BluetoothName)' with speaker '$($selection.SpeakerName)' and microphone '$($selection.MicrophoneName)'."

    Write-ProgressLine -Message 'Requesting enablement of the selected phone audio endpoints...'
    Enable-PhoneAudioEndpoints -Endpoints $BrokenPhoneEndpoints
    Write-ProgressLine -State Success -Message 'Endpoint enablement stage completed.'

    Write-ProgressLine -Message 'Restarting required Windows Audio and Bluetooth services...'
    Restart-SafeServices
    Write-ProgressLine -State Success -Message 'Service restart stage completed.'

    Write-ProgressLine -Message 'Asking Windows to rescan Plug and Play devices...'
    try {
        $scan = & pnputil.exe /scan-devices 2>&1
        $scan | Out-File -FilePath $script:RepairLog -Append -Encoding utf8 -Width 500
        Write-LogLine -Path $script:RepairLog -Message 'Plug and Play scan completed.'
    } catch {
        Write-LogLine -Path $script:RepairLog -Message "PnP scan failed: $($_.Exception.Message)"
    }

    Write-ProgressLine -State Success -Message 'Plug and Play rescan stage completed.'
    Write-ProgressLine -Message 'Restarting Phone Link related processes...'
    Restart-PhoneLinkProcesses
    Write-ProgressLine -State Success -Message 'Phone Link process restart stage completed.'

    Write-ProgressLine -Message 'Waiting five seconds for Windows to rebuild the connection...'
    Start-Sleep -Seconds 5
    Write-Host 'Safe repair completed. Running a fresh diagnostic...' -ForegroundColor Green
    Get-Diagnostics | Out-Null
    Show-RestartPrompt
}

function Show-Menu {
    while ($true) {
        Write-Host "`nPhone Link Bluetooth Doctor" -ForegroundColor Cyan
        Write-Host '1. Run diagnostics only'
        Write-Host '2. Choose or change speaker, microphone, and Bluetooth phone'
        Write-Host '3. Configure Windows call speaker and microphone'
        Write-Host '4. Run diagnostics, review, then offer safe Phone Link repair'
        Write-Host '5. Reset Doctor selections and run setup again'
        Write-Host '6. Open newest log folder'
        Write-Host '7. Exit'
        $choice = Read-Host 'Choose 1-7'

        switch ($choice) {
            '1' { Get-Diagnostics | Out-Null }
            '2' { [void](Set-DeviceSelection) }
            '3' { Show-WindowsCallAudioSetup }
            '4' {
                $result = Get-Diagnostics
                Invoke-SafeRepair -BrokenPhoneEndpoints $result.BrokenPhoneEndpoints
            }
            '5' { Reset-DoctorSelections }
            '6' { Start-Process explorer.exe -ArgumentList $script:RunRoot }
            '7' { return }
            default { Write-Host 'Invalid choice.' -ForegroundColor Red }
        }
    }
}

try {
    Write-Host 'Phone Link Bluetooth Doctor' -ForegroundColor Cyan
    Write-Host "Repository: $script:RepoRoot"
    Write-Host 'Safety rule: no device removal or unpairing is implemented.' -ForegroundColor Green

    Invoke-PostRestartCheck

    if ($DiagnoseOnly) {
        Get-Diagnostics | Out-Null
    } elseif ($NonInteractive) {
        Get-Diagnostics | Out-Null
    } else {
        Show-Menu
    }
    exit 0
} catch {
    Write-LogLine -Path $script:SummaryLog -Message "Fatal error: $($_.Exception.Message)"
    Write-Host "Fatal error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
