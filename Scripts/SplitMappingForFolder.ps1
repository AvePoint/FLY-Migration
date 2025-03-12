Install-Module -Name PnP.PowerShell -RequiredVersion 1.12.0
$SourceTenantDomain = "https://xxxx.sharepoint.com"
$DestnationTenantDomain = "https://xxxx.sharepoint.com"
$SrcSiteUrl = "https://xxxx.sharepoint.com/sites/xxxx"
$DestSiteUrl = "https://xxxx.sharepoint.com/sites/xxxx"
$OutputFilePath = "C:\xxxx\Mapping.csv"
$FolderServerRelativeUrl="/sites/TestxxxxSiteCollection/lib01/Folder01"
Connect-PnPOnline -Url $SrcSiteUrl -UseWebLogin

$web = Get-PnPWeb
$folder = $web.GetFolderByServerRelativeUrl($FolderServerRelativeUrl)
$ctx = Get-PnPContext
$ctx.Load($folder.Folders)
$ctx.ExecuteQuery()

#subsites
foreach($folder in $folder.Folders)
{
    if($folder.Name -ne "Forms")
    {
        $srcFolderUrl = $SourceTenantDomain+$folder.ServerRelativeUrl
        $Data = New-Object PSObject
        $Data | Add-Member NoteProperty "Source URL"($srcFolderUrl)
        $Data | Add-Member NoteProperty "Source object level"("Folder")
        $Data | Add-Member NoteProperty "Destination URL"($srcFolderUrl.Replace($SrcSiteUrl,$DestSiteUrl))
        $Data | Add-Member NoteProperty "Destination object level"("Folder")
        $Data | Add-Member NoteProperty "Method"("Merge")
        $Data | Export-CSV $OutputFilePath -NoTypeInformation -Append -Encoding UTF8 -Force
    }
}