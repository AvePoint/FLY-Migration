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

ConvertFrom-StringData @'
###PSLOC

    NugetBootstrapPrompt=One or more NuGet packages that PSSwagger requires are missing, and PSSwagger is unable to find NuGet.exe in its cache locations or in your Path. PSSwagger needs to download NuGet.exe.
    NugetBootstrapDownload=Downloading NuGet.exe from '{0}' to '{1}'.
    NuGetPackageRequired=PSSwagger needs to download the NuGet package '{0}' to compile the generated assembly for .NET.
    NuGetPackageSpecificVersionRequired=PSSwagger needs to download the NuGet package '{0}' of version '{1}' to compile the generated assembly for .NET.
    DownloadingNuGetPackage=Downloading NuGet package '{0}'...
    BootstrapConfirmTitle=Do you want PSSwagger to download the missing tools or packages for you?
    FailedToInstallNuGetPackage=NuGet package '{0}' failed to install.
    NuGetStandardOut=Output from NuGet.exe: {0}
    MissingNuGetPackage=NuGet package '{0}' was not found in either the local PSSwagger package cache '{1}' or the global PSSwagger package cache '{2}'.
    MissingNuGetPackageSpecificVersion=NuGet package '{0}' of version '{3}' was not found in either the local PSSwagger package cache '{1}' or the global PSSwagger package cache '{2}'.
    CodeFileSignatureValidationFailed=Failed to validate the signature of file '{0}'.
    FailedToAddType=Unable to add '{0}' type.
    NuGetMissing=NuGet.exe missing. This usually means the user did not consent to download NuGet.exe when prompted.
    NuGetFailedToInstall=NuGet.exe failed to install to path '{0}'.
###PSLOC
'@

