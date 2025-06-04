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
 *  Copyright © 2017-2025 AvePoint® Inc. All Rights Reserved. 
 *
 *  Unpublished - All rights reserved under the copyright laws of the United States.
 */ #>
function Get-BasicAuthCredentialInternal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [PSCredential]
        $Credential
    )

    if(('Microsoft.PowerShell.Commands.PSSwagger.PSBasicAuthenticationEx' -as [Type]))
    {
        # If the Extended type exists, use it
        New-Object -TypeName 'Microsoft.PowerShell.Commands.PSSwagger.PSBasicAuthenticationEx' -ArgumentList $Credential.UserName,$Credential.Password
    } else {
        # Otherwise this version should exist
        New-Object -TypeName 'Microsoft.PowerShell.Commands.PSSwagger.PSBasicAuthentication' -ArgumentList $Credential.UserName,$Credential.Password
    }
}

function Get-ApiKeyCredentialInternal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $APIKey,

        [Parameter(Mandatory=$false)]
        [string]
        $Location,

        [Parameter(Mandatory=$false)]
        [string]
        $Name
    )

    New-Object -TypeName 'Microsoft.PowerShell.Commands.PSSwagger.PSApiKeyAuthentication' -ArgumentList $APIKey,$Location,$Name
}

function Get-EmptyAuthCredentialInternal {
    [CmdletBinding()]
    param()

    New-Object -TypeName 'Microsoft.PowerShell.Commands.PSSwagger.PSDummyAuthentication'
}
