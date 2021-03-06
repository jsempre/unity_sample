#Accept and define parameters being passed from E2Campus parser (HamlineAlert.py)
param([string]$alertBrand = "Branding", [string]$alertTitle = "Title", [string]$alertDescription = "Description")

#Define user and retrieve encrypted password from file, assign to credential object.
$user = "hu\jordan"
$password = Get-Content C:\HamlineAlert\password.txt | convertto-securestring -key (1..16)
$cred = New-Object System.Management.Automation.PsCredential($user,$password)

#Retrieve date for log file name.
$date = Get-Date -format "MMddyyyy_hhmm_"

#Set Active Directory seach path, username and password.
$objDomain = New-Object System.DirectoryServices.DirectoryEntry("LDAP://OU=E2CampusPilot,OU=Desktops,OU=Computers,OU=Hamline,dc=hu,dc=hamline,dc=edu", $cred.UserName, $cred.GetNetworkCredential().Password)
$objDomain.Username = $cred.UserName
$objDomain.Password = $cred.GetNetworkCredential().Password

#Create search object, point it at the search path and filter results to computer names.
$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = $objDomain
$objSearcher.PageSize = 1000
$objSearcher.Filter = ("(objectCategory=computer)")
$objSearcher.SearchScope = "Subtree"

#Set log path and start logging output, stop logging if error occurs.
$file = "C:\HamlineAlert\logs\" + $date + "HamlineAlert.log"
start-transcript $file
trap { stop-transcript; break}

#Delete any old computer lists
Remove-Item C:\HamlineAlert\clients.txt

#Search active directory and save computer names to a list.
$colProplist = "name"
foreach ($i in $colPropList){$objSearcher.PropertiesToLoad.Add($i)}
$colResults = $objSearcher.FindAll()
foreach ($objResult in $colResults)
{$objComputer = $objResult.Properties; $objComputer.name

#Save list to a file
Add-Content C:\HamlineAlert\clients.txt ("`n" + $objComputer.name)}

#Read contents of file, on blank lines do nothing, all other lines send command to remote computer as a job that displays a popup message from E2Campus.
$clients = get-content C:\HamlineAlert\clients.txt
foreach ($i in $clients){
    if ($i.length -eq 0){}
    else{
        Invoke-Command -ComputerName $i -Credential $cred -AsJob -ScriptBlock { msg.exe * /TIME:43200 $args[0] "`n" $args[1] "`n" $args[2]} -ArgumentList $alertBrand, $alertTitle, $alertDescription
        }
}

#Close and save log file.
stop-transcript
