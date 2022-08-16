<#
Code generated by Microsoft (R) PSSwagger 0.3.0
Changes may cause incorrect behavior and will be lost if the code is regenerated.
#>

#
# Module manifest for module 'FLYMigration'
#
# Generated by: Administrator
#
# Generated on: 7/6/2022
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'FLYMigration.psm1'

# Version number of this module.
ModuleVersion = '1.0.0'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = 'bae2baef-b847-4138-8f92-6bf420ddbcc1'

# Author of this module
Author = 'Administrator'

# Company or vendor of this module
CompanyName = 'Unknown'

# Copyright statement for this module
Copyright = '(c) 2022 Administrator. All rights reserved.'

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
               '.\Generated.PowerShell.Commands\FormatFiles\BoxAdvancedSettings.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\BoxConnectionSummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\BoxJobExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\BoxMappingContent.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\BoxMigrationSharePointObject.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\BoxObject.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\BoxPlanMappingModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\BoxPlanSettingsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\BoxPreMigrationModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\ChannelMappingModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\ConversationsMigrationSettings.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\Credential.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\DatabaseModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\DatabaseSummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\DbServiceAccount.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\DistributionGroupDestinationMappingModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\DistributionGroupSourceMappingModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\DropBoxAdvancedSettings.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\DropboxConnectionSummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\DropboxJobExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\DropboxMappingContent.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\DropboxMigrationSharePointObject.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\DropboxObject.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\DropboxPlanMappingModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\DropboxPlanSettingsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\DropBoxPreMigrationModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\ErrorModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\ExchangeConnectionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\ExchangeConnectionSummaryModel.ps1xml', 
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
               '.\Generated.PowerShell.Commands\FormatFiles\ExchangePreMapping.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\ExchangePreMigrationModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\ExchangeServerOption.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\ExchangeServiceProviderModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\FileSystemAdvanced.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\FileSystemPreMapping.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\FSConnectionsSummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\FSJobExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\FSMappingContent.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\FSMappingModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\FSMigrationSharePointObject.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\FSPath.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\FSPlanSettingsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\FSPreMigrationModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GmailConnectionSummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GmailJobExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GmailMappingContentModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GmailMappingModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GmailMigrationExchangeMailboxModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GmailPlanSettingsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GmailPreMapping.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GmailPreMigrationModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GoogleDriveAdvancedSettings.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GoogleDriveConnectionSummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GoogleDriveJobExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GoogleDriveMappingContent.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GoogleDriveMappingModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GoogleDriveMigrationSharePointObject.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GoogleDriveObject.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GoogleDrivePlanSettingsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GoogleDrivePreMigrationModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GoogleGroupMappingContentModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GoogleGroupMappingModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GoogleGroupMigrationExchangeMailboxModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GoogleGroupPlanSettingsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GroupsPreMapping.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\GroupsPreMigrationModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\ImapMigrationExchangeMailboxModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\IMAPPOP3ConnectionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\IMAPPOP3JobExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\IMAPPOP3MailBoxObject.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\IMAPPOP3MappingModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\IMAPPOP3PlanSettingsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\JobSummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\MSTeamsConnectionSummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\MSTeamsJobExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\MSTeamsMappingModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\MSTeamsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\MSTeamsPlanExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\MSTeamsPlanSettingsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\MultigeoTenantModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\Office365GroupConnectionSummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\Office365GroupJobExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\Office365GroupMappingModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\Office365GroupModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\Office365GroupPlanExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\Office365GroupPlanSettingsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PageResultViewModelListJobSummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PageResultViewModelListSPJobSummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PFPreMapping.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PFPreMigrationModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PlanExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PlanGroupDetailsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PlanGroupModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PlanGroupSummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PlanNameLabel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PlanSummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PolicySummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PostMigrationOptions.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PSTFileConnectionOption.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PSTFileJobExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PSTFileMappingModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PSTFileModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PSTFilePlanSettingModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PstPlanExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PublicFolderConnectionOption.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PublicFolderJobExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PublicFolderModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PublicFolderPlanExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\PublicFoldersSettings.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\ScheduleDetailsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\ScheduleModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\ServiceResponseString.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SharePointConnectionCollectionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SharePointConnectionOnlineModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SharePointConnectionOnPremisesModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SharePointConnectionSiteModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SharePointConnectionSummary.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SharePointJobExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SharePointMappingContent.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SharePointMappingModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SharePointObject.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SharePointPlanExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SharePointPlanSettingsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SharePointPreMapping.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SharePointPreMigrationModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SharePointUpdateModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SimpleSchedule.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SlackCompleteModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SlackConnectionSummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SlackJobExecutionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SlackMappingContentModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SlackMappingModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SlackMigrationMSTeamsObject.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SlackPlanSettingsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SlackPreMapping.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SlackPreMigrationModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SPJobSummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\SPPlanSummaryModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\StatusResultModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\TeamsCompleteModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\TeamsPreMapping.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\TeamsPreMigrationModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\UpdateBoxPlanModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\UpdateDistributionGroupPlanModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\UpdateDropBoxPlan.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\UpdateExchangePlanModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\UpdateFSPlanModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\UpdateGmailPlanModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\UpdateGoogleDrivePlanModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\UpdateGoogleGroupPlanSettingsModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\UpdateIMAPPOP3PlanModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\UpdateMSTeamsPlanModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\UpdateOffice365GroupPlanModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\UpdatePSTFilePlanModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\UpdatePublicFoldersPlanModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\UpdateSharePointConnectionCollectionModel.ps1xml', 
               '.\Generated.PowerShell.Commands\FormatFiles\UpdateSlackPlanModel.ps1xml'

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = @('PSSwaggerUtility')

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = 'Start-GoogleDriveJobByPlan', 'Add-ExchangeDistributionGroupPlan', 
               'Get-PublicFolder', 'Find-SPJobsByPlan', 'Update-SPPlan', 
               'Add-FileSystemPreMigration', 'Stop-PSTFileJob', 
               'Get-PublicFolderConnection', 'Remove-SlackPlan', 
               'Get-GoogleDriveJob', 'Update-ExchangeDistributionGroupPlan', 
               'Stop-IMAPPOP3Job', 'Get-BoxConnection', 'Add-GoogleDrivePlan', 
               'Remove-SPJob', 'Get-ExchangeServiceProvider', 
               'Add-DropboxPreMigration', 'Add-Office365GroupPreMigration', 
               'Start-PublicFolderJobByPlan', 'Get-DropboxPlan', 
               'Start-PSTFileJobByPlan', 'Add-SlackPreMigration', 
               'Remove-Office365GroupPlan', 'Stop-Office365GroupJob', 
               'Update-GoogleDrivePlan', 'Get-MicrosoftTeamsPlan', 
               'Get-DropboxConnection', 'Remove-MicrosoftTeamsPlan', 
               'Remove-PublicFolderPlan', 'Get-SPConnection', 
               'Find-PublicFolderJobsByPlan', 'Find-ExchangeJobsByPlan', 
               'Start-GmailJobByPlan', 'Get-PSTFilePlan', 'Start-SlackJobByPlan', 
               'Complete-MicrosoftTeamsPlan', 'Remove-GoogleDriveJob', 'Get-FSJob', 
               'Get-ExchangePlan', 'Remove-SlackJob', 'Restart-PSTFileJob', 
               'Add-Database', 'Get-Office365GroupPolicy', 'Start-FSJobByPlan', 
               'Remove-ExchangePlan', 'Get-PublicFolderPolicy', 'Start-SPJobByPlan', 
               'Get-MicrosoftTeamsPolicy', 'Add-SharePointPreMigration', 
               'Add-IMAPPOP3Plan', 'Find-DropboxJobsByPlan', 
               'Get-Office365GroupPlan', 'Stop-SPJob', 'Restart-FSJob', 
               'Get-PSTFilePolicy', 'Update-PublicFolderPlan', 
               'Start-DropboxJobByPlan', 'Get-IMAPPOP3Jobs', 'Add-FSPlan', 
               'Get-Account', 'Get-BoxJob', 'Find-Office365GroupJobsByPlan', 
               'Get-DropboxPolicy', 'Update-GmailPlan', 'Remove-GmailJob', 
               'Update-ExchangePlan', 'Get-SlackConnection', 'Stop-DropboxJob', 
               'Find-BoxJobsByPlan', 'Get-GoogleDriveConnection', 'Stop-FSJob', 
               'Add-GoogleGroupPlan', 'Remove-Office365GroupJob', 'Get-FSPolicy', 
               'Add-PublicFolderPreMigration', 'Get-BoxPlan', 'Restart-BoxJob', 
               'Get-DropboxJob', 'Remove-GoogleDrivePlan', 'Start-IMAPPOP3JobByPlan', 
               'Restart-IMAPPOP3Job', 'Find-GoogleDriveJobsByPlan', 
               'Get-GmailPolicy', 'Get-PlanGroup', 'Add-SPConnection', 
               'Remove-PSTFileJob', 'Remove-PublicFolderJob', 'Get-SPPlan', 
               'Get-SlackJob', 'Start-Office365GroupJobByPlan', 'Remove-SPPlan', 
               'Add-SlackPlan', 'Update-SlackPlan', 'Update-IMAPPOP3Plan', 
               'Get-ExchangeConnection', 'Get-ExchangeJob', 'Add-GmailPreMigration', 
               'Remove-DropboxJob', 'Get-MicrosoftTeamsJob', 
               'Restart-MicrosoftTeamsJob', 'Add-GoogleDrivePreMigration', 
               'Add-BoxPreMigration', 'Get-AppProfile', 'Add-ExchangePlan', 
               'Get-MicrosoftTeamsConnection', 'Add-MicrosoftTeamsPlan', 
               'Get-PSTFileJob', 'Restart-SPJob', 'Get-PlanGroupById', 
               'Update-DropboxPlan', 'Get-Office365GroupConnection', 'Get-GmailJob', 
               'Restart-Office365GroupJob', 'Restart-DropboxJob', 'Restart-SlackJob', 
               'Get-GmailConnection', 'Remove-BoxJob', 'Find-GmailJobsByPlan', 
               'Restart-PublicFolder', 'Find-MicrosoftTeamsJobsByPlan', 'Add-SPPlan', 
               'Remove-PSTFilePlan', 'Find-SlackJobsByPlan', 'Add-GmailPlan', 
               'Update-MicrosoftTeamsPlan', 'Start-BoxJobByPlan', 
               'Update-PSTFilePlan', 'Search-ExchangeServiceProvider', 
               'Get-SlackPlan', 'Stop-GmailJob', 'Get-FSConnection', 
               'Stop-GoogleDriveJob', 'Stop-PlanGroup', 'Get-ExchangePolicy', 
               'Start-JobsByPlanGroup', 'Remove-FSPlan', 'Add-PlanGroup', 
               'Add-Office365GroupPlan', 'Get-FSPlan', 'Add-PSTFilePlan', 
               'Stop-MicrosoftTeamsJob', 'Add-PublicFolderPlan', 'Update-FSPlan', 
               'Stop-ExchangeJob', 'Find-IMAPPOP3JobsByPlan', 'Remove-GmailPlan', 
               'Stop-SlackJob', 'Get-PublicFolderPlan', 'Add-ConnectionSite', 
               'Get-Office365GroupJobs', 'Update-BoxPlan', 'Restart-GmailJob', 
               'Start-ExchangeJobByPlan', 'Update-SPConnection', 
               'Add-ExchangePreMigration', 'Remove-DropboxPlan', 'Remove-FSJob', 
               'Remove-MicrosoftTeamsJob', 'Get-BoxPolicy', 'Add-BoxPlan', 
               'Restart-GoogleDriveJob', 'Remove-PlanGroup', 
               'Start-MicrosoftTeamsJobByPlan', 'Find-FSJobsByPlan', 
               'Remove-IMAPPOP3Plan', 'Complete-MicrosoftSlackPlan', 
               'Remove-BoxPlan', 'Stop-BoxJob', 'Add-TeamsPreMigration', 
               'Down-PreMigrationReportLoad', 'Add-DropboxPlan', 
               'Get-GoogleDrivePlan', 'Get-GoogleDrivePolicy', 'Remove-ExchangeJob', 
               'Remove-IMAPPOP3Job', 'Get-IMAPPOP3Policy', 'Start-PreMigration', 
               'Get-SlackPolicy', 'Restart-ExchangeJob', 'Stop-PublicFolderJob', 
               'Get-SPJob', 'Find-PSTFileJobsByPlan', 'Get-Database', 
               'Get-IMAPPOP3Plan', 'Update-Office365GroupPlan', 'Get-GmailPlan', 
               'Update-GoogleGroupPlan', 'Get-SPPolicy', 
               'New-SlackMappingContentObject', 'New-IMAPPOP3PlanSettingsObject', 
               'New-BoxObject', 'New-DropBoxPreMigrationObject', 
               'New-FileSystemAdvancedObject', 'New-GmailMappingContentObject', 
               'New-Office365GroupJobExecutionObject', 
               'New-ConversationsMigrationSettingsObject', 
               'New-PublicFolderConnectionObject', 'New-SharePointUpdateObject', 
               'New-DropBoxAdvancedSettingsObject', 
               'New-GoogleDriveJobExecutionObject', 
               'New-DropboxPlanSettingsObject', 'New-FSMappingContentObject', 
               'New-IMAPPOP3PlanObject', 'New-PSTFilePlanSettingObject', 
               'New-GoogleDriveMappingContentObject', 
               'New-GoogleGroupMigrationExchangeMailboxObject', 
               'New-UpdateOffice365GroupPlanObject', 
               'New-GmailMigrationExchangeMailboxObject', 
               'New-UpdateIMAPPOP3PlanObject', 'New-TeamsPreMigrationObject', 
               'New-DatabaseObject', 'New-UpdatePublicFoldersPlanObject', 
               'New-FSMappingObject', 'New-ExchangeDistributionGroupPlanObject', 
               'New-UpdateMSTeamsPlanObject', 'New-SharePointPlanSettingsObject', 
               'New-BoxAdvancedSettingsObject', 
               'New-SharePointPlanExecutionObject', 
               'New-FSMigrationSharePointObject', 'New-PostMigrationOptionsObject', 
               'New-DropboxPlanObject', 'New-MSTeamsJobExecutionObject', 
               'New-GmailPlanSettingsObject', 'New-SharePointConnectionSiteObject', 
               'New-IMAPPOP3MappingObject', 'New-ExchangeServerOptionObject', 
               'New-UpdateExchangePlanObject', 
               'New-DistributionGroupDestinationMappingObject', 
               'New-ExchangeConnectionObject', 'New-UpdateGmailPlanObject', 
               'New-ScheduleObject', 'New-MSTeamsObject', 'New-SlackCompleteObject', 
               'New-ExchangePreMappingObject', 'New-BoxPreMigrationObject', 
               'New-PlanGroupObject', 'New-BoxMappingContentObject', 
               'New-SharePointPreMappingObject', 
               'New-SharePointPreMigrationObject', 'New-BoxPlanMappingObject', 
               'New-GoogleGroupMappingContentObject', 
               'New-UpdateDropBoxPlanObject', 'New-IMAPPOP3MailBoxObject', 
               'New-ChannelMappingObject', 'New-Office365GroupMappingObject', 
               'New-ExchangeMappingContentObject', 'New-FSJobExecutionObject', 
               'New-BoxPlanSettingsObject', 'New-BoxMigrationSharePointObject', 
               'New-PublicFolderMappingContentObject', 
               'New-SlackJobExecutionObject', 'New-Office365GroupPlanObject', 
               'New-DropboxPlanMappingObject', 'New-PstPlanExecutionObject', 
               'New-ExchangeDistributionGroupPlanSettingsObject', 
               'New-DropboxMappingContentObject', 
               'New-ImapMigrationExchangeMailboxObject', 
               'New-SimpleScheduleObject', 'New-TeamsPreMappingObject', 
               'New-SlackPreMappingObject', 
               'New-Office365GroupPlanExecutionObject', 
               'New-GoogleDriveMigrationSharePointObject', 'New-SharePointObject', 
               'New-DropboxObject', 'New-GroupsPreMappingObject', 
               'New-SharePointJobExecutionObject', 
               'New-UpdateSharePointConnectionCollectionObject', 
               'New-PSTFileObject', 'New-UpdateDistributionGroupPlanObject', 
               'New-FSPreMigrationObject', 'New-PublicFolderJobExecutionObject', 
               'New-GoogleDriveObject', 'New-GoogleDrivePreMigrationObject', 
               'New-SharePointPlanObject', 'New-SharePointConnectionOnlineObject', 
               'New-SlackPreMigrationObject', 'New-GmailPlanObject', 
               'New-GmailPreMappingObject', 'New-SharePointMappingObject', 
               'New-DistributionGroupSourceMappingObject', 
               'New-GoogleDriveMappingObject', 'New-FileSystemPreMappingObject', 
               'New-ExchangeOnlineConnectionOptionObject', 
               'New-GoogleDrivePlanObject', 'New-GmailJobExecutionObject', 
               'New-PFPreMappingObject', 'New-PSTFileMappingContentObject', 
               'New-TeamsCompleteObject', 'New-ExchangeJobExecutionObject', 
               'New-UpdateGoogleDrivePlanObject', 
               'New-MSTeamsMappingContentObject', 'New-Office365GroupObject', 
               'New-PublicFolderObject', 'New-GoogleDriveAdvancedSettingsObject', 
               'New-FSPathObject', 'New-SharePointMappingContentObject', 
               'New-UpdateFSPlanObject', 'New-PSTFilePlanObject', 
               'New-Office365GroupMappingContentObject', 
               'New-ExchangePlanSettingsObject', 'New-PublicFoldersSettingsObject', 
               'New-MSTeamsPlanSettingsObject', 'New-PlanExecutionObject', 
               'New-PlanNameLabelObject', 'New-GoogleGroupPlanObject', 
               'New-PublicFolderMappingObject', 'New-IMAPPOP3JobExecutionObject', 
               'New-ExchangePreMigrationObject', 'New-UpdatePSTFilePlanObject', 
               'New-PublicFolderConnectionOptionObject', 'New-UpdateBoxPlanObject', 
               'New-FSPlanSettingsObject', 'New-DropboxMigrationSharePointObject', 
               'New-MSTeamsPlanObject', 'New-DbServiceAccountObject', 
               'New-ExchangeDistributionGroupMappingObject', 
               'New-CredentialObject', 'New-GmailMappingObject', 
               'New-SlackPlanObject', 'New-GoogleGroupMappingObject', 
               'New-SharePointConnectionOnPremisesObject', 
               'New-UpdateGoogleGroupPlanSettingsObject', 
               'New-GmailPreMigrationObject', 'New-SlackMappingObject', 
               'New-GroupsPreMigrationObject', 'New-BasicCredentialObject', 
               'New-IMAPPOP3ConnectionObject', 'New-PSTFileMappingObject', 
               'New-PublicFolderPlanObject', 
               'New-Office365GroupPlanSettingsObject', 
               'New-SharePointConnectionCollectionObject', 
               'New-DropboxJobExecutionObject', 'New-MultigeoTenantObject', 
               'New-GoogleGroupPlanSettingsObject', 'New-UpdateSlackPlanObject', 
               'New-MSTeamsPlanExecutionObject', 'New-SlackPlanSettingsObject', 
               'New-ExchangeMappingObject', 'New-BoxJobExecutionObject', 
               'New-PFPreMigrationObject', 'New-PSTFileConnectionOptionObject', 
               'New-GoogleDrivePlanSettingsObject', 'New-ExchangePlanObject', 
               'New-PSTFileJobExecutionObject', 'New-MSTeamsMappingObject', 
               'New-BoxPlanObject', 'New-IMAPPOP3MappingContentObject', 
               'New-ExchangeOnPremisesConnectionOptionObject', 
               'New-ExchangePlanExecutionObject', 'New-FSPlanObject', 
               'New-ExchangeDistributionGroupMappingContentObject', 
               'New-PublicFolderPlanExecutionObject', 'New-ExchangeMailboxObject', 
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


