Install-Module PnP.PowerShell
$SrcSiteUrl = ""
$DestSiteUrl = ""
$OutputFilePath = "C:\xxxxxx\Mapping.csv"
Connect-PnPOnline -Url $SrcSiteUrl -UseWebLogin
$allWebs = Get-PnPSubWeb -Recurse

if(Test-Path $OutputFilePath)
{
    remove-Item -Recurse -Force $OutputFilePath
}
#RootSite
$Data = New-Object PSObject
$Data | Add-Member NoteProperty "Source URL"($SrcSiteUrl) 
$Data | Add-Member NoteProperty "Source object level"("Site collection")
$Data | Add-Member NoteProperty "Destination URL"($DestSiteUrl)
$Data | Add-Member NoteProperty "Destination object level"("Site collection")
$Data | Add-Member NoteProperty "Method"("Merge")
$Data | Export-CSV $OutputFilePath -NoTypeInformation -Append -Encoding UTF8 -Force

#subsites
foreach($web in $allWebs)
{
    $Data = New-Object PSObject
    $Data | Add-Member NoteProperty "Source URL"($web.Url) 
    $Data | Add-Member NoteProperty "Source object level"("Site")
    $Data | Add-Member NoteProperty "Destination URL"($web.Url.Replace($SrcSiteUrl,$DestSiteUrl))
    $Data | Add-Member NoteProperty "Destination object level"("Site")
    $Data | Add-Member NoteProperty "Method"("Merge")
    $Data | Export-CSV $OutputFilePath -NoTypeInformation -Append -Encoding UTF8 -Force
}