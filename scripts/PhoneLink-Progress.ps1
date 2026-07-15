# PhoneLink-Progress.ps1
# Created by TCDOVERLORD
# Separate visual progress component for PhoneLink Bluetooth Doctor.

Set-StrictMode -Version Latest

$script:DoctorProgressPercent = 0
$script:DoctorProgressActivity = 'Phone Link Bluetooth Doctor'
$script:DoctorProgressPhase = 'Starting'

function Reset-DoctorProgress {
    param(
        [string]$Activity = 'Phone Link Bluetooth Doctor',
        [string]$Phase = 'Starting'
    )

    $script:DoctorProgressPercent = 0
    $script:DoctorProgressActivity = $Activity
    $script:DoctorProgressPhase = $Phase

    Write-Progress `
        -Id 1 `
        -Activity $script:DoctorProgressActivity `
        -Status $script:DoctorProgressPhase `
        -PercentComplete 0
}

function Write-ProgressLine {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('Info','Working','Success','Warning','Error')]
        [string]$State = 'Working',
        [int]$Percent = -1
    )

    # A new working phase after 100% starts a fresh progress cycle.
    if ($script:DoctorProgressPercent -ge 100 -and $State -eq 'Working') {
        $script:DoctorProgressPercent = 0
    }

    if ($Percent -ge 0) {
        $script:DoctorProgressPercent = [Math]::Max(0, [Math]::Min(100, $Percent))
    }
    else {
        $increment = switch ($State) {
            'Info'    { 2 }
            'Working' { 7 }
            'Success' { 5 }
            'Warning' { 3 }
            'Error'   { 0 }
        }

        $script:DoctorProgressPercent = [Math]::Min(
            95,
            $script:DoctorProgressPercent + $increment
        )
    }

    if ($Message -match '(?i)all diagnostic reports were created|safe repair completed') {
        $script:DoctorProgressPercent = 100
    }

    $prefix = switch ($State) {
        'Info'    { '[INFO]' }
        'Working' { '[PLEASE WAIT]' }
        'Success' { '[DONE]' }
        'Warning' { '[WARNING]' }
        'Error'   { '[ERROR]' }
    }

    $color = switch ($State) {
        'Info'    { 'Cyan' }
        'Working' { 'Yellow' }
        'Success' { 'Green' }
        'Warning' { 'DarkYellow' }
        'Error'   { 'Red' }
    }

    $script:DoctorProgressPhase = $Message

    Write-Progress `
        -Id 1 `
        -Activity $script:DoctorProgressActivity `
        -Status $Message `
        -CurrentOperation ("{0}% complete" -f $script:DoctorProgressPercent) `
        -PercentComplete $script:DoctorProgressPercent

    Write-Host (
        "{0} [{1,3}%] {2}" -f
        $prefix,
        $script:DoctorProgressPercent,
        $Message
    ) -ForegroundColor $color
}

function Complete-DoctorProgress {
    param([string]$Message = 'Operation completed.')

    $script:DoctorProgressPercent = 100

    Write-Progress `
        -Id 1 `
        -Activity $script:DoctorProgressActivity `
        -Status $Message `
        -PercentComplete 100 `
        -Completed

    Write-Host ("[DONE] [100%] {0}" -f $Message) -ForegroundColor Green
}
