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
    /// <summary>
    /// Create a new migration plan by passing the plan settings
    /// </summary>
    class AddSPPlan : AbstractApplication
    {
        static void Main(string[] args)
        {
            new AddSPPlan().RunAsync().Wait();
        }
        /// <summary>
        /// <see cref="GetMigrationDatabase"/>
        /// </summary>
        private readonly string migrationDatabaseId = "<migration database id>";
        /// <summary>
        /// <see cref="GetSPMigrationPolicy"/>
        /// </summary>
        private readonly string migrationPolicyId = "<migration policy id>";
        /// <summary>
        /// <see cref="GetAccount"/>
        /// </summary>
        private readonly string sourceSharePointAccount = "<sharepoint account name>";
        /// <summary>
        /// <see cref="GetSPAccount"/>
        /// </summary>
        private readonly string destinationSharePointAccount = "<sharepoint account name>";
        /// <returns>
        /// <see cref="ServiceResponsePlanSummaryModel"/>
        /// </returns>
        protected override async Task<string> RunAsync(HttpClient client)
        {
            var sourceCredential = new SharePointCredential
            {
                AccountName = sourceSharePointAccount,
            };

            var destinationCredential = new SharePointCredential
            {
                AccountName = destinationSharePointAccount,
            };

            var siteLevelMappingContent = new SharePointMappingContent
            {
                Source = new SharePointObject
                {
                    Url = "<sharepoint site url>",
                    Level = "Site",
                },
                Destination = new SharePointObject
                {
                    Url = "<sharepoint site url>",
                    Level = "Site"
                },
                Method = "Combine",
            };

            var siteCollectionLevelMappingContent = new SharePointMappingContent
            {
                Source = new SharePointObject
                {
                    Url = "<sharepoint site collection url>",
                    Level = "SiteCollection",
                },
                Destination = new SharePointObject
                {
                    Url = "<sharepoint site collection url>",
                    Level = "SiteCollection"
                },
                Method = "Combine",
            };

            var mappings = new SharePointMappingModel
            {
                SourceCredential = sourceCredential,
                DestinationCredential = destinationCredential,
                Contents = new List<SharePointMappingContent>
                {
                    siteLevelMappingContent,
                    siteCollectionLevelMappingContent
                },
            };

            var planSettings = new SharePointPlanSettingsModel
            {
                NameLabel = new PlanNameLabel
                {
                    Name = $"CSharp_SP_Plan_{DateTime.Now.ToString("yyyyMMddHHmmss")}",
                    BusinessUnit = "<BusinessUnit name>",
                    Wave = "<Wave name>"
                },
                DatabaseId = migrationDatabaseId,
                MigrationMode = "HighSpeed",
                PolicyId = migrationPolicyId,
                Schedule = new ScheduleModel
                {
                    IntervalType = "OnlyOnce",
                    StartTime = DateTime.Now.AddMinutes(2),
                },
            };

            var plan = new SharePointPlanModel
            {
                Mappings = mappings,
                Settings = planSettings,
            };

            plan.Validate();

            var requestContent = JsonConvert.SerializeObject(plan);

            var content = new StringContent(requestContent, Encoding.UTF8, "application/json");

            var response = await client.PostAsync("/api/sharepoint/plans", content);

            return await response.Content.ReadAsStringAsync();
        }
    }
}
