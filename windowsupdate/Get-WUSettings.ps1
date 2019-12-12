# https://p0w3rsh3ll.wordpress.com/2013/01/09/get-windows-update-client-configuration/
#
# blah blah header

Function Get-WUSettings {
[cmdletbinding()]
Param(
[switch]$viaRegistry=$false
)
Begin {
    # Get the Operating system
    $OSVersion = [environment]::OSVersion.Version

    # Initialize object
    $WshShell = New-Object -ComObject Wscript.Shell

    $polkey = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
    $stdkey = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update'
}
Process {
    if ($viaRegistry) {
        try {
            $AUEnabled = $WshShell.RegRead("$polkey\NoAutoUpdate")
        } catch {
            # if this value is absent, it means it's turned on
            $AUEnabled = 0
        }
        Switch ($AUEnabled) {
            1 {$AUEnabled = $false}
            0 {$AUEnabled = $true }
        }
        try {
            $AUOptions = $WshShell.RegRead("$polkey\AUOptions")
        } catch {
            try {
                $AUOptions = $WshShell.RegRead("$stdkey\AUOptions")
            } catch {
                $AUOptions = 0
            }
        }
        Switch ($AUOptions) {
            0 {$AUNotificationLevel = 'Not Configured'}
            1 {$AUNotificationLevel = 'Never check for updates'}
            2 {$AUNotificationLevel = 'Notify Before Download'}
            3 {$AUNotificationLevel = 'Notify Before Installation'}
            4 {$AUNotificationLevel = 'Install updates automatically'}
        }
        try {
            $IncludeRecommendedUpdates = $WshShell.RegRead("$polkey\IncludeRecommendedUpdates")
        } catch {
            # if the value is absent we get it from
            $IncludeRecommendedUpdates = $WshShell.RegRead("$stdkey\IncludeRecommendedUpdates")
        }
        Switch ($IncludeRecommendedUpdates) {
            0 {$GetRecommendedUpdates = $false}
            1 {$GetRecommendedUpdates = $true}
        }
       try {
            $UseWUServerVal = $WshShell.RegRead("$polkey\UseWUServer")
        } catch {
            # if the value doesn't exist, it means that we don't use a WSUS server
            $UseWUServerVal = 0
        }
        Switch ($UseWUServerVal) {
            1 {$UseWUServer = $true}
            0 {$UseWUServer = $false }
        }
        # Create a default object with a subset of properties
        $obj = New-Object -TypeName psobject -Property @{
            'Is Automatic Update Enabled' = $AUEnabled
            'Use a WSUS Server' = $UseWUServer
            'Automatic Updates Notification' = $AUNotificationLevel;
            'Receive recommended udpates' = $GetRecommendedUpdates;
        }
        if ($OSVersion -lt [version]'6.2') {
            try {
                $ScheduledInstallDay  = $WshShell.RegRead("$polkey\ScheduledInstallDay")
                $ScheduledInstallTime = $WshShell.RegRead("$polkey\ScheduledInstallTime")
            } catch {
                try {
                    $ScheduledInstallDay  = $WshShell.RegRead("$stdkey\ScheduledInstallDay")
                    $ScheduledInstallTime = $WshShell.RegRead("$stdkey\ScheduledInstallTime")
                } catch {
                    # Absent = Every Day @3 AM but I prefer to leave it blank in the returned object
                }
            }
            Switch ($ScheduledInstallDay) {
                0 {$InstallDay = 'Every Day'}
                1 {$InstallDay = 'Every Sunday'}
                2 {$InstallDay = 'Every Monday'}
                3 {$InstallDay = 'Every Tuesday'}
                4 {$InstallDay = 'Every Wednesday'}
                5 {$InstallDay = 'Every Thursday'}
                6 {$InstallDay = 'Every Friday'}
                7 {$InstallDay = 'Every Saturday'}
            }
            if ($ScheduledInstallTime) {
                $InstallTime = New-TimeSpan -Hours $ScheduledInstallTime
            }
            $obj | Add-Member -MemberType NoteProperty -Name 'Install Frequency' -Value $InstallDay
            $obj | Add-Member -MemberType NoteProperty -Name 'Install Time' -Value $InstallTime
        } else {
            # These properties don't exist anymore on Windows 8
        }
        # Add extra properties
        if ($UseWUServer) {
            try {
                $WUServer = $WshShell.RegRead('HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\WUServer')
                $WUStatusServer =  $WshShell.RegRead('HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\WUStatusServer')
            } catch {
                # we silently fail
            }
            $obj | Add-Member -MemberType NoteProperty -Name 'WSUS Server' -Value $WUServer
            $obj | Add-Member -MemberType NoteProperty -Name 'WSUS Status URL' -Value $WUStatusServer
        }
        try {
            $OptinGUID = $WshShell.RegRead('HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Services\DefaultService')
        } catch {
            # Fail silently
        }
        if ($OptinGUID -eq '7971f918-a847-4430-9279-4a52d1efe18d') {
            $obj | Add-Member -MemberType NoteProperty -Name "Opted-in Microsoft Update" -Value $true
        } else {
            $obj | Add-Member -MemberType NoteProperty -Name "Opted-in Microsoft Update" -Value $false
        }
        # Return our object
        $obj

    } else {
        # We use Com Object
        $COMWUSettings = (New-Object -ComObject Microsoft.Update.AutoUpdate).Settings
        # Settings might be controlled by GPO
        if ($COMWUSettings.ReadOnly) {
            # Use the registry
            Get-WUSettings -viaRegistry:$true
            break
        } else {
            $UseWUServer = $false
        }
        Switch ($COMWUSettings.NotificationLevel) {
            0 {$AUNotificationLevel = 'Not Configured'}
            1 {$AUNotificationLevel = 'Never check for updates'}
            2 {$AUNotificationLevel = 'Notify Before Download'}
            3 {$AUNotificationLevel = 'Notify Before Installation'}
            4 {$AUNotificationLevel = 'Install updates automatically'}
        }
        $isAUenabled = (New-Object -ComObject Microsoft.Update.AutoUpdate).serviceEnabled
        $obj = New-Object -TypeName psobject -Property @{
            'Is Automatic Update Enabled' = $isAUenabled
            'Automatic Updates Notification' = $AUNotificationLevel;
            'Use a WSUS Server' = $UseWUServer
            'Receive recommended udpates' = $COMWUSettings.IncludeRecommendedUpdates;
        }
        if ($OSVersion -lt [version]'6.2') {
            Switch ($COMWUSettings.ScheduledInstallationDay) {
                0 {$InstallDay = 'Every Day'}
                1 {$InstallDay = 'Every Sunday'}
                2 {$InstallDay = 'Every Monday'}
                3 {$InstallDay = 'Every Tuesday'}
                4 {$InstallDay = 'Every Wednesday'}
                5 {$InstallDay = 'Every Thursday'}
                6 {$InstallDay = 'Every Friday'}
                7 {$InstallDay = 'Every Saturday'}
            }
            if ($COMWUSettings.ScheduledInstallationTime) {
                $InstallTime = New-TimeSpan -Hours $COMWUSettings.ScheduledInstallationTime
            }
            $obj | Add-Member -MemberType NoteProperty -Name 'Install Frequency' -Value $InstallDay
            $obj | Add-Member -MemberType NoteProperty -Name 'Install Time' -Value $InstallTime

        } else {
            # not available on W8
        }
        (New-Object -ComObject Microsoft.Update.ServiceManager).services | ForEach-Object {
            if ($_.IsDefaultAUService) {
                $OptinGUID = $_.ServiceID
            }
        }
        if ($OptinGUID -eq '7971f918-a847-4430-9279-4a52d1efe18d') {
            $obj | Add-Member -MemberType NoteProperty -Name "Opted-in Microsoft Update" -Value $true
        } else {
            $obj | Add-Member -MemberType NoteProperty -Name "Opted-in Microsoft Update" -Value $false
        }
        # return
        $obj
    }
}
End {}
}

## Actually get update status. Really ought to rewrite this as a boring old script, but meh.
Get-WUSettings