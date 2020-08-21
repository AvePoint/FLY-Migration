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
    class AddGoogleGroupPlan : AbstractApplication
    {
        static void Main(string[] args)
        {
            new AddGoogleGroupPlan().RunAsync().Wait();
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
            var mappingContent = new GoogleGroupMappingContentModel
            {
                Mailbox = "<gmail>",
                Destination = new GoogleGroupMigrationExchangeMailboxModel
                {
                    Mailbox = "<destination mailbox>",
                    MailboxType = "GroupMailbox",
                },
            };

            var mappings = new GoogleGroupMappingModel
            {
                SourceConnectionId = sourceConnectionId,
                Destination = new ExchangeConnectionModel 
                {
                    OnlineConnectionOption = new ExchangeOnlineConnectionOption
                    {
                        ConnectionId = destinationConnectionId
                    }
                },
                Contents = new List<GoogleGroupMappingContentModel>
                {
                    mappingContent
                },
            };

            var planSettings = new GoogleGroupPlanSettingsModel
            {
                NameLabel = new PlanNameLabel
                {
                    Name = $"CSharp_Gmail_Plan_{DateTime.Now.ToString("yyyyMMddHHmmss")}",
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
                PlanGroups = new List<string>(),
            };

            var plan = new GoogleGroupPlanModel
            {
                Mappings = mappings,
                Settings = planSettings,
            };

            plan.Validate();

            var requestContent = JsonConvert.SerializeObject(plan);

            var content = new StringContent(requestContent, Encoding.UTF8, "application/json");

            var response = await client.PostAsync("/api/gmail/plans/googlegroup", content);

            return await response.Content.ReadAsStringAsync();
        }
    }
}
