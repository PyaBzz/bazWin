
$ListOfPackages = Get-AppxPackage -AllUsers
foreach($x in $ListOfPackages){
Remove-AppxPackage -Package $x.PackageFullName}

$ListOfProvisionedPackages = Get-AppxProvisionedPackage –Online
Foreach ($x in $ListOfProvisionedPackages){
Remove-AppxProvisionedPackage -Online -PackageName $x.PackageName}

$RootPath = "SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\"
 
$SystemAppNames = @( "Windows-ContactSupport" )
 
foreach ($SystemAppName in $SystemAppNames) {
    $RegistryKeyApps = (ls "HKLM:\$RootPath" | where Name -Like "*$SystemAppName*")
         
    foreach($RegistryKeyApp in $RegistryKeyApps)
    {
        $RegistryKey = $RegistryKeyApp.Name.Substring(19) #Remove HKEY_LOCAL_MACHINE from string
        Write-Host $RegistryKey
         
        $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($RegistryKey,[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,[System.Security.AccessControl.RegistryRights]::ChangePermissions)
        $acl = $key.GetAccessControl()
        $rule = New-Object System.Security.AccessControl.RegistryAccessRule ("${[system.environment]::MachineName}\Administrator","FullControl","Allow")
        $acl.SetAccessRule($rule)
        $key.SetAccessControl($acl)
 
        $subkey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("$RegistryKey\Owners",[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,[System.Security.AccessControl.RegistryRights]::ChangePermissions)
        $subacl = $subkey.GetAccessControl()
        $subacl.SetAccessRule($rule)
        $subkey.SetAccessControl($subacl)
         
        Set-ItemProperty -Path "HKLM:\$RegistryKey" -Name Visibility -Value 1
        New-ItemProperty -Path "HKLM:\$RegistryKey" -Name DefVis -PropertyType DWord -Value 2
            Remove-Item -Path "HKLM:\$RegistryKey\Owners"
             
            $AppName = $RegistryKey.Split('\')[-1]
            DISM /Online /Remove-Package /PackageName:$AppName
    }
     
    #Remember to remove it from the currently logged in user (and rename "Windows-ContactSupport" to "Windows.ContactSupport")
    Get-AppxPackage -Name $SystemAppName.Replace("-",".") -AllUsers | Remove-AppxPackage
}