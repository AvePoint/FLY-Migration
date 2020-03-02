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
    class AddGmailDistributionGroupPlan : AbstractApplication
    {
        static void Main(string[] args)
        {
            new AddGmailDistributionGroupPlan().RunAsync().Wait();
        }
        /// <summary>
        /// <see cref="GetMigrationDatabase"/>
        /// </summary>
        private readonly string migrationDatabaseId = "<migration database id>";
        /// <summary>
        /// <see cref="GetGmailConnection"/>
        /// </summary>
        private readonly string sourceConnectionId = "<gmail connection id>";
        /// <summary>
        /// <see cref="GetExchangeConnection"/>
        /// </summary>
        private readonly string destinationConnectionId = "<exchange connection id>";
        /// <summary>
        /// <see cref="GetGmailMigrationPolicy"/>
        /// </summary>
        private readonly string migrationPolicyId = "<migration policy id>";
        /// <returns>
        /// <see cref="ServiceResponsePlanSummaryModel"/>
        /// </returns>
        protected override async Task<string> RunAsync(HttpClient client)
        {
            var mappingContent = new GmailDistributionGroupMappingContentModel
            {
                Mailbox = "<gmail>",
                Destination = new GmailDistributionGroupMigrationExchangeMailboxModel
                {
                    Mailbox = "<destination mailbox>",
                    MailboxType = "GroupMailbox",
                },
            };

            var mappings = new GmailDistributionGroupMappingModel
            {
                SourceConnectionId = sourceConnectionId,
                DestinationConnectionId = destinationConnectionId,
                Contents = new List<GmailDistributionGroupMappingContentModel>
                {
                    mappingContent
                },
            };

            var planSettings = new GmailDistributionGroupPlanSettingsModel
            {
                NameLabel = new PlanNameLabel
                {
                    Name = $"CSharp_Gmail_Plan_{DateTime.Now.ToString("yyyyMMddHHmmss")}",
                    BusinessUnit = "<BusinessUnit name>",
                    Wave = "<Wave name>",
                },
                PolicyId = migrationPolicyId,
                Schedule = new ScheduleModel
                {
                    IntervalType = "OnlyOnce",
                    StartTime = DateTime.Now.AddMinutes(2),
                },
                DatabaseId = migrationDatabaseId,
                PlanGroups = new List<string>(),
            };

            var plan = new GmailDistributionGroupPlanModel
            {
                Mappings = mappings,
                Settings = planSettings,
            };

            plan.Validate();

            var requestContent = JsonConvert.SerializeObject(plan);

            var content = new StringContent(requestContent, Encoding.UTF8, "application/json");

            var response = await client.PostAsync("/api/gmail/plans/distributiongroup", content);

            return await response.Content.ReadAsStringAsync();
        }
    }
}
