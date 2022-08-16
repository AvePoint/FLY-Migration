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
$invocation = (Get-Variable MyInvocation).Value
$timestamp = Get-Date -UFormat %Y%m%d%H%M%S
$currentPath = (Get-Item $invocation.MyCommand.Path).Directory.FullName
$ImportCsv = "$currentPath\MailAddress.csv"
$EWSDLL = "$currentPath\Microsoft.Exchange.WebServices.dll"
$result = @()
$ListInfos =@()
$error.Clear()
$code= @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
            public bool CheckValidationResult(ServicePoint srvPoint, X509Certificate certificate, WebRequest request, int certificateProblem) {
                return true;
            }
        }
"@
try
{
    try
    {
        Import-Module $EWSDLL
        if($error)
        {
            throw $error
        }
    }
    catch
    {
        throw $_.Exception.Message
    }
    ."$currentPath\ValidationFuncs.ps1"
    Add-Type -TypeDefinition $code -Language CSharp
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
    $cred = Get-Credential 

    do
    {
        [string]$vision =  Read-Host "Please choose Exchange Version: a.Exchange_SP1.  b.Exchange_SP2.  c.Exchange_SP3."
    }
    until ("a","b","c" -contains $vision)
    switch($vision)
    {
        a{[String]$ExchangeVersion = "Exchange2010_SP1"}
        b{[String]$ExchangeVersion = "Exchange2010_SP2"}
        c{[String]$ExchangeVersion = "Exchange2010_SP2"}
    }
    do
    {
        [string]$ServerHost =  Read-Host "Please input Exchange Server Host"
    }
    until ($ServerHost)

    if (test-path $ImportCsv)
    {
        Write-Host "Get user mailbox from csv, csv path: $($ImportCsv)"
        Log-Info -Message "Begin get user from csv file."
        $ListInfos= Import-Csv $ImportCsv
        try
        {
            foreach($Info in $ListInfos)
            {
                if($Info.'Mailbox Address')
                {
                    #ValidationFunction
                    Log-Info -Message "Mailbox:$($Info.'Mailbox Address'). Version:$($ExchangeVersion). Host:$($ServerHost) "
                    $result += Get-MailboxFolderDetails -Credential $cred -Mailbox $Info.'Mailbox Address' -Version $ExchangeVersion -ServerHost $ServerHost
                }
            }
        }
        catch
        {
            Log-Error $_.Exception.Message
            $fObj = New-Object -TypeName PSCustomObject
            $fObj | Add-Member -Type NoteProperty -Name "Mailbox" -Value "All Mailboxes"
            $fObj | Add-Member -Type NoteProperty -Name "Folder Display Name" -Value ""
            $fObj | Add-Member -Type NoteProperty -Name "Comment" -Value $($_.Exception.Message)
            $result += $fObj
        }
    }
    else
    {
        $errorMessage = "The ""MailboxAddress.csv"" file does not exist in the $($currentPath) directory. Make sure the file is in the same directory as the script."
        Log-Error $errorMessage
        $fObj = New-Object -TypeName PSCustomObject
        $fObj | Add-Member -Type NoteProperty -Name "Mailbox" -Value "All Mailboxes"
        $fObj | Add-Member -Type NoteProperty -Name "Folder Display Name" -Value ""
        $fObj | Add-Member -Type NoteProperty -Name "Comment" -Value $($errorMessage)
        $result += $fObj
    }
}
catch
{
    Write-Host $_.Exception.Message -ForegroundColor Red
    $fObj = New-Object -TypeName PSCustomObject
    $fObj | Add-Member -Type NoteProperty -Name "Mailbox" -Value 'All Mailboxes'
    $fObj | Add-Member -Type NoteProperty -Name "Folder Display Name" -Value ""
    $fObj | Add-Member -Type NoteProperty -Name "Comment" -Value $($_.Exception.Message)
    $result += $fObj
} 


if($result.Count -eq 0)
{
    $errorMessage = "Failed to retrieve the mailbox address from $($ImportCsv). Make sure the ""Mailbox Address"" column exists and is correct in the file."
    Log-Error $errorMessage
    $fObj = New-Object -TypeName PSCustomObject
    $fObj | Add-Member -Type NoteProperty -Name "Mailbox" -Value 'All Mailboxes'
    $fObj | Add-Member -Type NoteProperty -Name "Folder Display Name" -Value ""
    $fObj | Add-Member -Type NoteProperty -Name "Comment" -Value $($errorMessage)
    $result += $fObj
}

$result | Export-Csv -Path "$currentPath\FolderInfo_Mailbox_$timestamp.csv" -NoTypeInformation -Encoding UTF8
Log-Info -Message "Done. Please check the report for details. Path: $($currentPath)\FolderInfo_Mailbox_$($timestamp).csv"