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
    class AddExchangeDistributionGroupPlan : AbstractApplication
    {
        static void Main(string[] args)
        {
            new AddExchangeDistributionGroupPlan().RunAsync().Wait();
        }

        /// <summary>
        /// <see cref="GetMigrationDatabase"/>
        /// </summary>
        private readonly string migrationDatabaseId = "<migration database id>";
        /// <summary>
        /// <see cref="GetExchangeConnection"/>
        /// </summary>
        private readonly string destinationConnectionId = "<exchange connection id>";
        /// <summary>
        /// <see cref="GetExchangeMigrationPolicy"/>
        /// </summary>
        private readonly string migrationPolicyId = "<migration policy id>";
        /// <returns>
        /// <see cref="ServiceResponsePlanSummaryModel"/>
        /// </returns>
        protected override async Task<string> RunAsync(HttpClient client)
        {
            var mappingContent = new ExchangeDistributionGroupMappingContentModel
            {
                Mailbox = "<source mailbox>",
                Destination = new DistributionGroupMigrationExchangeMailboxModel
                {
                    Mailbox = "<destination mailbox>",
                    MailboxType = "DistributionGroup",
                },
            };

            var mappings = new ExchangeDistributionGroupMappingModel
            {
                Source = new ExchangeConnectionModel 
                { 
                    OnPremisesConnectionOption = new ExchangeOnPremisesConnectionOption 
                    {
                        BasicCredential = new BasicCredential 
                        {
                            Username = "<username>",
                            Password = "<password>"
                        }
                    } 
                },
                Destination = new ExchangeConnectionModel 
                { 
                    OnlineConnectionOption = new ExchangeOnlineConnectionOption 
                    {
                        ConnectionId = destinationConnectionId
                    } 
                },
                Contents = new List<ExchangeDistributionGroupMappingContentModel>
                {
                    mappingContent
                },
            };

            var planSettings = new ExchangeDistributionGroupPlanSettingsModel
            {
                NameLabel = new PlanNameLabel
                {
                    Name = $"CSharp_EX_Plan_{DateTime.Now.ToString("yyyyMMddHHmmss")}",
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

            var plan = new ExchangeDistributionGroupPlanModel
            {
                Mappings = mappings,
                Settings = planSettings,
            };

            plan.Validate();

            var requestContent = JsonConvert.SerializeObject(plan);

            var content = new StringContent(requestContent, Encoding.UTF8, "application/json");

            var response = await client.PostAsync("/api/exchange/plans/distributiongroup", content);

            return await response.Content.ReadAsStringAsync();
        }
    }
}
