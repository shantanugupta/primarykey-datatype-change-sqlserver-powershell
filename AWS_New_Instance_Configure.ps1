$domain="mydomain.net";
$domainOnly = "mydomain";
$user="usrname";
$password =  ConvertTo-SecureString $("Type your credentials here") -AsPlainText -Force;
$username = "$domain\$user";
$computerName = (get-WmiObject win32_computersystem).Name
$account = 'acc_name'
$credentials = New-Object System.Management.Automation.PSCredential($username, $password);
Add-Computer -DomainName $domain -Credential $credentials

$adsi = [ADSI]"WinNT://$computerName/administrators,group"
$adsi.add("WinNT://$domainOnly/$account,group");

$domainList = (Get-DnsClientGlobalSetting).SuffixSearchList;
if($domainList -Contains $domain -eq 0){
    $domainList+=$domain;
    Set-DnsClientGlobalSetting -SuffixSearchList @($domainList);
}