<# /********************************************************************
 *
 *  PROPRIETARY and CONFIDENTIAL
 *
 *  This file is licensed from, and is a trade secret of:
 *
 *                   AvePoint, Inc.
 *                   525 Washington Blvd, Suite 1400
 *                   Jersey City, NJ 07310
 *                   United States of America
 *                   Telephone: +1-201-793-1111
 *                   WWW: www.avepoint.com
 *
 *  Refer to your License Agreement for restrictions on use,
 *  duplication, or disclosure.
 *
 *  RESTRICTED RIGHTS LEGEND
 *
 *  Use, duplication, or disclosure by the Government is
 *  subject to restrictions as set forth in subdivision
 *  (c)(1)(ii) of the Rights in Technical Data and Computer
 *  Software clause at DFARS 252.227-7013 (Oct. 1988) and
 *  FAR 52.227-19 (C) (June 1987).
 *
 *  Copyright © 2017-2022 AvePoint® Inc. All Rights Reserved.
 *
 *  Unpublished - All rights reserved under the copyright laws of the United States.
 */ #>
$EWSDLL = "$currentPath\Microsoft.Exchange.WebServices.dll"
."$currentPath\LogFuncs.ps1"
Log-Initialize -path "$currentPath\Log" -name ("ScanMailbox_{0}.log" -f (Get-Date).ToString("yyyyMMddHHmmSS"))
Import-Module $EWSDLL

function Get-MailboxFolderDetails{
    param(
        [System.Management.Automation.PSCredential]$Credential,
        [String]$Mailbox,
        [String]$Version,
        [String]$ServerHost
    )
try
{
    Log-Info -Message "Start getting mailbox folder details for $Mailbox"
    $ret = @()
    #Create EWS Service Connection
    Log-Info -Message "Begin to create EWS Service Connection"
	$convertPWD = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password))
    Log-Info -Message "UserName:$($Credential.UserName). Mailbox:$($Mailbox). ExchangeVersion:$($Version). ExchangeServerHost:$($ServerHost)."
    $service = New-Object Microsoft.Exchange.WebServices.Data.ExchangeService([Microsoft.Exchange.WebServices.Data.ExchangeVersion]::$Version)
    $service.Credentials =  New-Object System.Net.NetworkCredential($Credential.UserName , $convertPWD)
    $service.Url = "https://$($ServerHost)/EWS/Exchange.asmx"

    #Impersonation is important here! Impersonate the mailbox by using the service account
    Log-Info -Message "Begin to set ImpersonatedUserId. Mailbox:$($Mailbox)"
    $service.ImpersonatedUserId = New-Object Microsoft.Exchange.WebServices.Data.ImpersonatedUserId([Microsoft.Exchange.WebServices.Data.ConnectingIdType]::SmtpAddress, $Mailbox)

    try
    {
        Log-Info -Message "Begin to bind mailbox root folder by ImpersonatedUserId."
        $rootFolder = Get-RootFolder -Service $service -Mailbox $Mailbox
    }
    catch
    {
        $errorMessage = "Failed to bind root folder by ImpersonatedUserId, Error:$($_.Exception.Message)"
        Log-Error -Message $errorMessage
        $service.ImpersonatedUserId = $null
        try
        {
            Log-Info -Message "Begin to bind mailbox root folder by use full access."
            $rootFolder = Get-RootFolder -Service $service -Mailbox $Mailbox
        }
        catch
        {
            $errorMessage = "Failed to connect to mailbox, mailbox:$($Mailbox). Error:$($_.Exception.Message)"
            Log-Error -Message $errorMessage
            throw $errorMessage
        }
    }
    
    try
    {
        Log-Info -Message "Begin to get mailbox root folders."
        #Create Folder View to loop all folders
        $fView = New-Object Microsoft.Exchange.WebServices.Data.FolderView(1000)
        $fView.Traversal = [Microsoft.Exchange.WebServices.Data.FolderTraversal]::Shallow 
        #Get All Folders
        $allFolders = $rootFolder.FindFolders($fView)
        foreach($folder in $allFolders.Folders){
            $names += $folder.DisplayName + " ;"
        }
    }
    catch
    {
        $errorMessage = "Failed to get mailbox root folders, Error:$($_.Exception.Message)"
        Log-Error -Message $errorMessage
        $fObj = New-Object -TypeName PSCustomObject
        $fObj | Add-Member -Type NoteProperty -Name "Mailbox" -Value $Mailbox
        $fObj | Add-Member -Type NoteProperty -Name "Folder Display Name" -Value ""
        $fObj | Add-Member -Type NoteProperty -Name "Comment" -Value $errorMessage
        throw $errorMessage
    }

    if($names)
    {
        $folderNames = $names.TrimEnd(" ;") + "..."
    }
    $fObj = New-Object -TypeName PSCustomObject
    $fObj | Add-Member -Type NoteProperty -Name "Mailbox" -Value $Mailbox
    $fObj | Add-Member -Type NoteProperty -Name "Folder Display Name" -Value $folderNames
    $fObj | Add-Member -Type NoteProperty -Name "Comment" -Value ""
    $ret += $fObj
    Log-Info -Message "Finished to getting mailbox folder."
}
catch
{
    $errorMessage = "Failed to retrieve folders in the mailbox:$($Mailbox). Details:$($_.Exception.Message)"
    Write-Host $errorMessage -ForegroundColor Red
    $fObj = New-Object -TypeName PSCustomObject
    $fObj | Add-Member -Type NoteProperty -Name "Mailbox" -Value $Mailbox
    $fObj | Add-Member -Type NoteProperty -Name "Folder Display Name" -Value ""
    $fObj | Add-Member -Type NoteProperty -Name "Comment" -Value $($_.Exception.Message)
    $ret += $fObj
}
    return $ret
}

function Get-RootFolder{
    param(
        [Microsoft.Exchange.WebServices.Data.ExchangeService]$service,
        [String]$Mailbox
    )
    #Get Folder ID by using full access
    $rootFolderId = New-Object Microsoft.Exchange.WebServices.Data.FolderId([Microsoft.Exchange.WebServices.Data.WellKnownFolderName]::MsgFolderRoot, $Mailbox)
    #Get Folder by using Folder ID
    $rootFolder = [Microsoft.Exchange.WebServices.Data.Folder]::Bind($service, $rootFolderId)
    return $rootFolder
}