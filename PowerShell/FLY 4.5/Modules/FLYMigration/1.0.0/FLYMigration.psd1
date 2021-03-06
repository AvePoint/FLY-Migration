<#
Code generated by Microsoft (R) PSSwagger 0.3.0
Changes may cause incorrect behavior and will be lost if the code is regenerated.
#>

#
# Module manifest for module 'FLYMigration'
#
# Generated by: administrator
#
# Generated on: 4/13/2020
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'FLYMigration.psm1'

# Version number of this module.
ModuleVersion = '1.0.0'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = 'f3454128-77df-48b2-9995-bdb232e766e3'

# Author of this module
Author = 'administrator'

# Company or vendor of this module
CompanyName = 'Unknown'

# Copyright statement for this module
Copyright = '(c) 2020 administrator. All rights reserved.'

# Description of the functionality provided by this module
Description = '<div><p>FLY API provides programmatic access to trigger and manage migration jobs through Web API endpoints. To call FLY API, you must get the API key from FLY interface > Management > General Settings > <a target=''_blank'' href=''/#!/settings/general-settings/apikeys'' rel=''noopener noreferrer'' class=''link''>API Keys</a>. For every Web API call, the API key must be attached to the Authorization header in the HTTP request.</p></div>
                                 <div class=''dxp-docFrame''>Authorization: api_key Mgo8CM3TLB0Kgxdqp9RwKTjBt/p ... E/dBN0Q1/vjzjx0qftB/jc</div> <div><p>In this page, you can try and test the API endpoints by copying and pasting the API key to the api_key text box above.</p></div>
                                 <div><p>Refer to <a target=''_blank'' href=''https://github.com/AvePoint/FLY-Migration/tree/master/WebAPI'' rel=''noopener noreferrer''>Sample Codes</a> for more sample codes.</p></div>
                                 <div><p>If you would like to write PowerShell scripts, please refer to <a target=''_blank'' href=''https://github.com/AvePoint/FLY-Migration/tree/master/PowerShell'' rel=''noopener noreferrer'' class=''link''>PowerShell</a> for more details.</p></div>'

# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = ''

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = 
               '.\Generated.PowerShell.Commands\FormatFiles\AccountSummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\AppProfileModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\BasicCredential.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\BoxConnectionSummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\BoxJobExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\BoxMappingContent.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\BoxMigrationSharePointObject.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\BoxObject.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\BoxPlanMappingModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\BoxPlanSettingsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\ConversationsMigrationSettings.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\DatabaseSummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\DistributionGroupMigrationExchangeMailboxModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\DropboxConnectionSummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\DropboxJobExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\DropboxMappingContent.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\DropboxMigrationSharePointObject.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\DropboxObject.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\DropboxPlanMappingModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\DropboxPlanSettingsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\ErrorModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\ExchangeConnectionSummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\ExchangeDistributionGroupMappingContentModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\ExchangeDistributionGroupMappingModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\ExchangeDistributionGroupPlanSettingsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\ExchangeJobExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\ExchangeMailboxModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\ExchangeMappingContentModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\ExchangeMappingModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\ExchangeOnlineConnectionOption.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\ExchangeOnPremisesConnectionOption.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\ExchangePlanExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\ExchangePlanSettingsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\ExchangeServerOption.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\ExchangeServiceProviderModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\FSConnectionsSummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\FSJobExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\FSMappingContent.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\FSMappingModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\FSMigrationSharePointObject.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\FSPath.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\FSPlanSettingsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GmailConnectionSummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GmailDistrabutionGroupMappingContentModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GmailDistrabutionGroupMappingModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GmailDistrabutionGroupMigrationExchangeMailboxModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GmailDistrabutionGroupPlanSettingsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GmailDistributionGroupMappingContentModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GmailDistributionGroupMappingModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GmailDistributionGroupMigrationExchangeMailboxModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GmailDistributionGroupPlanSettingsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GmailJobExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GmailMappingContentModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GmailMappingModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GmailMigrationExchangeMailboxModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GmailPlanSettingsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GoogleDriveConnectionSummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GoogleDriveJobExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GoogleDriveMappingContent.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GoogleDriveMappingModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GoogleDriveMigrationSharePointObject.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GoogleDriveObject.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GoogleDrivePlanSettingsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GoogleGroupMappingContentModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GoogleGroupMappingModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GoogleGroupMigrationExchangeMailboxModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GoogleGroupPlanSettingsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\IMAPPOP3ConnectionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\IMAPPOP3JobExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\IMAPPOP3MailBoxObject.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\IMAPPOP3MappingContentModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\IMAPPOP3MappingModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\IMAPPOP3PlanSettingsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\JobExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\JobSummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\MSTeamsConnectionSummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\MSTeamsJobExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\MSTeamsMappingModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\MSTeamsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\MSTeamsPlanExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\MSTeamsPlanSettingsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\Office365GroupConnectionSummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\Office365GroupJobExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\Office365GroupMappingModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\Office365GroupModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\Office365GroupPlanExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\Office365GroupPlanSettingsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PageResultViewModelListJobSummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PlanExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PlanGroupDetailsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PlanGroupModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PlanGroupSummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PlanNameLabel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PlanSummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PolicySummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PSTFileConnectionAdvancedSettingsOption.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PSTFileConnectionOption.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PSTFileJobExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PSTFileModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PSTFilePlanSettingModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\ScheduleDetailsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\ScheduleModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\ServiceResponseString.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SharePointConnectionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SharePointConnectionRegistrationResultModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SharePointCredential.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SharePointJobExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SharePointMappingContent.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SharePointObject.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SharePointPlanExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SharePointPlanSettingsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SimpleSchedule.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SlackConnectionSummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SlackJobExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SlackMappingContentModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SlackMappingModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SlackMigrationMSTeamsObject.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SlackPlanSettingsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\StatusResultModel.ps1xml'

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = @('PSSwaggerUtility')

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = 'Start-GoogleDriveJobByPlan', 'Add-ExchangeDistributionGroupPlan', 
               'Stop-PSTFileJob', 'Remove-SlackPlan', 'Get-GoogleDriveJob', 
               'Stop-IMAPPOP3Job', 'Get-BoxConnection', 'Add-GoogleDrivePlan', 
               'Remove-SPJob', 'Get-ExchangeServiceProvider', 'Get-DropboxPlan', 
               'Add-MicrosoftTeamsPlan', 'Remove-Office365GroupPlan', 
               'Stop-Office365GroupJob', 'Get-MicrosoftTeamsPlan', 
               'Get-DropboxConnection', 'Remove-MicrosoftTeamsPlan', 'Get-SlackPlan', 
               'Start-GmailJobByPlan', 'Get-PSTFilePlan', 'Start-SlackJobByPlan', 
               'Remove-GoogleDriveJob', 'Get-FSJob', 'Get-ExchangePlan', 
               'Start-PSTFileJobByPlan', 'Remove-SlackJob', 'Restart-PSTFileJob', 
               'Get-Office365GroupPolicy', 'Start-FSJobByPlan', 
               'Remove-ExchangePlan', 'Start-SPJobByPlan', 
               'Get-MicrosoftTeamsPolicy', 'Add-IMAPPOP3Plan', 
               'Find-DropboxJobsByPlan', 'Get-Office365GroupPlan', 'Stop-SPJob', 
               'Find-SPJobsByPlan', 'Get-PSTFilePolicy', 'Start-DropboxJobByPlan', 
               'Restart-FSJob', 'Get-IMAPPOP3Jobs', 'Add-FSPlan', 'Get-Account', 
               'Get-BoxJob', 'Find-Office365GroupJobsByPlan', 'Get-DropboxPolicy', 
               'Remove-GmailJob', 'Get-SlackConnection', 'Stop-DropboxJob', 
               'Find-BoxJobsByPlan', 'Get-GoogleDriveConnection', 'Stop-FSJob', 
               'Add-GoogleGroupPlan', 'Remove-Office365GroupJob', 
               'Remove-GoogleDrivePlan', 'Get-BoxPlan', 'Restart-BoxJob', 
               'Get-DropboxJob', 'Start-Office365GroupJobByPlan', 
               'Start-IMAPPOP3JobByPlan', 'Restart-IMAPPOP3Job', 
               'Find-GoogleDriveJobsByPlan', 'Get-GmailPolicy', 'Get-PlanGroup', 
               'Add-SPConnection', 'Remove-PSTFileJob', 'Stop-BoxJob', 'Get-SPPlan', 
               'Get-SlackJob', 'Get-Database', 'Remove-SPPlan', 'Add-SlackPlan', 
               'Get-ExchangeConnection', 'Get-ExchangeJob', 'Remove-DropboxJob', 
               'Get-MicrosoftTeamsJob', 'Restart-MicrosoftTeamsJob', 
               'Get-AppProfile', 'Add-ExchangePlan', 'Get-MicrosoftTeamsConnection', 
               'Remove-MicrosoftTeamsJob', 'Get-PSTFileJob', 'Restart-SPJob', 
               'Get-PlanGroupById', 'Get-Office365GroupConnection', 'Get-GmailJob', 
               'Restart-Office365GroupJob', 'Restart-DropboxJob', 'Restart-SlackJob', 
               'Get-GmailConnection', 'Remove-BoxJob', 'Find-GmailJobsByPlan', 
               'Find-ExchangeJobsByPlan', 'Find-MicrosoftTeamsJobsByPlan', 
               'Add-SPPlan', 'Remove-PSTFilePlan', 'Get-SlackPolicy', 
               'Find-SlackJobsByPlan', 'Add-GmailPlan', 'Start-BoxJobByPlan', 
               'Stop-GmailJob', 'Get-FSConnection', 'Search-ExchangeServiceProvider', 
               'Get-ExchangePolicy', 'Start-JobsByPlanGroup', 'Remove-FSPlan', 
               'Add-PlanGroup', 'Add-Office365GroupPlan', 'Get-FSPlan', 
               'Add-PSTFilePlan', 'Stop-MicrosoftTeamsJob', 'Stop-ExchangeJob', 
               'Find-IMAPPOP3JobsByPlan', 'Remove-GmailPlan', 'Stop-SlackJob', 
               'Get-Office365GroupJobs', 'Start-ExchangeJobByPlan', 
               'Remove-DropboxPlan', 'Remove-FSJob', 'Get-IMAPPOP3Policy', 
               'Get-BoxPolicy', 'Add-BoxPlan', 'Restart-GoogleDriveJob', 
               'Remove-PlanGroup', 'Start-MicrosoftTeamsJobByPlan', 
               'Find-FSJobsByPlan', 'Restart-GmailJob', 'Remove-BoxPlan', 
               'Remove-ExchangeJob', 'Add-DropboxPlan', 'Get-GoogleDrivePlan', 
               'Get-GoogleDrivePolicy', 'Remove-IMAPPOP3Job', 'Get-FSPolicy', 
               'Stop-GoogleDriveJob', 'Restart-ExchangeJob', 'Get-SPJob', 
               'Find-PSTFileJobsByPlan', 'Remove-IMAPPOP3Plan', 'Get-IMAPPOP3Plan', 
               'Get-GmailPlan', 'Get-SPPolicy', 'New-SlackMappingContentObject', 
               'New-IMAPPOP3PlanSettingsObject', 
               'New-SharePointJobExecutionObject', 'New-GmailMappingContentObject', 
               'New-ConversationsMigrationSettingsObject', 
               'New-GoogleDriveJobExecutionObject', 
               'New-DropboxPlanSettingsObject', 
               'New-ExchangeDistributionGroupMappingObject', 
               'New-FSMappingContentObject', 'New-IMAPPOP3PlanObject', 
               'New-PSTFilePlanSettingObject', 
               'New-GoogleDriveMappingContentObject', 
               'New-GoogleGroupMigrationExchangeMailboxObject', 
               'New-GmailMigrationExchangeMailboxObject', 
               'New-SharePointCredentialObject', 'New-FSMappingObject', 
               'New-ExchangeDistributionGroupPlanObject', 
               'New-SharePointPlanSettingsObject', 
               'New-FSMigrationSharePointObject', 'New-DropboxPlanObject', 
               'New-MSTeamsJobExecutionObject', 
               'New-PSTFileConnectionAdvancedSettingsOptionObject', 
               'New-GmailPlanSettingsObject', 'New-IMAPPOP3MappingObject', 
               'New-ExchangeServerOptionObject', 'New-ExchangeConnectionObject', 
               'New-ScheduleObject', 'New-MSTeamsObject', 
               'New-DistributionGroupMigrationExchangeMailboxObject', 
               'New-PSTFileMappingObject', 'New-PlanGroupObject', 
               'New-BoxMappingContentObject', 'New-Office365GroupObject', 
               'New-GoogleGroupMappingContentObject', 'New-IMAPPOP3MailBoxObject', 
               'New-Office365GroupMappingObject', 
               'New-ExchangeMappingContentObject', 'New-FSJobExecutionObject', 
               'New-BoxPlanSettingsObject', 'New-BoxMigrationSharePointObject', 
               'New-SlackJobExecutionObject', 'New-Office365GroupPlanObject', 
               'New-DropboxPlanMappingObject', 
               'New-ExchangeDistributionGroupPlanSettingsObject', 
               'New-DropboxMappingContentObject', 'New-SimpleScheduleObject', 
               'New-Office365GroupPlanExecutionObject', 
               'New-GoogleDriveMigrationSharePointObject', 'New-SharePointObject', 
               'New-DropboxObject', 'New-BoxPlanMappingObject', 'New-BoxObject', 
               'New-PSTFileObject', 'New-GoogleDriveObject', 
               'New-SharePointPlanObject', 'New-GmailPlanObject', 
               'New-SharePointMappingObject', 'New-GoogleDriveMappingObject', 
               'New-ExchangeOnlineConnectionOptionObject', 
               'New-GoogleDrivePlanObject', 'New-GmailJobExecutionObject', 
               'New-PlanExecutionObject', 'New-PSTFileMappingContentObject', 
               'New-ExchangeJobExecutionObject', 
               'New-SharePointPlanExecutionObject', 'New-FSPathObject', 
               'New-SharePointMappingContentObject', 'New-FSPlanObject', 
               'New-PSTFilePlanObject', 'New-Office365GroupMappingContentObject', 
               'New-ExchangePlanSettingsObject', 
               'New-Office365GroupJobExecutionObject', 'New-PlanNameLabelObject', 
               'New-GoogleGroupPlanObject', 'New-IMAPPOP3JobExecutionObject', 
               'New-FSPlanSettingsObject', 'New-MSTeamsPlanObject', 
               'New-SharePointConnectionObject', 'New-PSTFileJobExecutionObject', 
               'New-GmailMappingObject', 'New-SlackPlanObject', 
               'New-GoogleGroupMappingObject', 'New-SlackMappingObject', 
               'New-IMAPPOP3ConnectionObject', 'New-BasicCredentialObject', 
               'New-MSTeamsMappingContentObject', 
               'New-Office365GroupPlanSettingsObject', 
               'New-SharePointConnectionCollectionObject', 
               'New-DropboxJobExecutionObject', 
               'New-GoogleGroupPlanSettingsObject', 
               'New-DropboxMigrationSharePointObject', 
               'New-MSTeamsPlanExecutionObject', 'New-SlackPlanSettingsObject', 
               'New-ExchangeMappingObject', 'New-BoxJobExecutionObject', 
               'New-PSTFileConnectionOptionObject', 
               'New-GoogleDrivePlanSettingsObject', 'New-ExchangePlanObject', 
               'New-MSTeamsMappingObject', 'New-BoxPlanObject', 
               'New-IMAPPOP3MappingContentObject', 
               'New-ExchangeOnPremisesConnectionOptionObject', 
               'New-ExchangePlanExecutionObject', 
               'New-ExchangeDistributionGroupMappingContentObject', 
               'New-ExchangeMailboxObject', 'New-MSTeamsPlanSettingsObject', 
               'New-SlackMigrationMSTeamsObject'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
# VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        # Tags = @()

        # A URL to the license for this module.
        # LicenseUri = ''

        # A URL to the main website for this project.
        # ProjectUri = ''

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        # ReleaseNotes = ''

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}


