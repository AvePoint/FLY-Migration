﻿/********************************************************************
 *
 *  PROPRIETARY and CONFIDENTIAL
 *
 *  This file is licensed from, and is a trade secret of:
 *
 *                   AvePoint, Inc.
 *                   Harborside Financial Center
 *                   9th Fl.   Plaza Ten
 *                   Jersey City, NJ 07311
 *                   United States of America
 *                   Telephone: +1-800-661-6588
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
 *  Copyright © 2017-2019 AvePoint® Inc. All Rights Reserved. 
 *
 *  Unpublished - All rights reserved under the copyright laws of the United States.
 *  $Revision:  $
 *  $Author:  $        
 *  $Date:  $
 */
using AvePoint.Migration.Api.Models;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace AvePoint.Migration.Samples
{
    class AddGoogleDrivePlan : AbstractApplication
    {
        static void Main(string[] args)
        {
            new AddGoogleDrivePlan().RunAsync().Wait();
        }

        /// <summary>
        /// <see cref="GetMigrationDatabase"/>
        /// </summary>
        private readonly string migrationDatabaseId = "<migration database id>";
        /// <summary>
        /// <see cref="GetGoogleDriveConnection"/>
        /// </summary>
        private readonly string sourceConnectionId = "<google drive connection id>";
        /// <summary>
        /// <see cref="GetAccount"/>
        /// </summary>
        private readonly string sharepointAccount = "<sharepoint account name>";
        /// <summary>
        /// <see cref="GetGmailMigrationPolicy"/>
        /// </summary>
        private readonly string migrationPolicyId = "<migration policy id>";
        /// <returns>
        /// <see cref="ServiceResponsePlanSummaryModel"/>
        /// </returns>
        protected override async Task<string> RunAsync(HttpClient client)
        {
            var destinationCredential = new SharePointCredential
            {
                AccountName = sharepointAccount,
                AppProfileName = "<app profile name>"
            };
            var mappingContent = new GoogleDriveMappingContent
            {
                Source = new GoogleDriveObject
                {
                    Path = "<path>",
                    Level = "Folder",
                },
                Destination = new GoogleDriveMigrationSharePointObject
                {
                    Url = "<sharepoint library url>",
                    Level = "Library",
                },
                Method = "Combine"
            };

            var mappings = new GoogleDriveMappingModel
            {
                SourceConnectionId = sourceConnectionId,
                DestinationCredential = destinationCredential,
                Contents = new List<GoogleDriveMappingContent>
                {
                    mappingContent
                },
            };

            var planSettings = new GoogleDrivePlanSettingsModel
            {
                NameLabel = new PlanNameLabel
                {
                    Name = $"CSharp_GD_Plan_{DateTime.Now.ToString("yyyyMMddHHmmss")}",
                    BusinessUnit = "<BusinessUnit name>",
                    Wave = "<Wave name>",
                },
                PolicyId = migrationPolicyId,
                Schedule = new SimpleSchedule
                {
                    IntervalType = "Once",
                    StartTime = DateTime.Now.AddMinutes(2),
                },
                DatabaseId = migrationDatabaseId,
                MigrateVersions = true,
                PlanGroups = new List<string>()
            };

            var plan = new GoogleDrivePlanModel
            {
                Mappings = mappings,
                Settings = planSettings,
            };

            plan.Validate();

            var requestContent = JsonConvert.SerializeObject(plan);

            var content = new StringContent(requestContent, Encoding.UTF8, "application/json");

            var response = await client.PostAsync("/api/googledrive/plans", content);

            return await response.Content.ReadAsStringAsync();
        }
    }
}
