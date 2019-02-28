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
    class AddExchangePlan : AbstractApplication
    {
        static void Main(string[] args)
        {
            new AddExchangePlan().RunAsync().Wait();
        }

        /// <summary>
        /// <see cref="GetMigrationDatabase"/>
        /// </summary>
        private readonly string migrationDatabaseId = "<migration database id>";
        /// <summary>
        /// <see cref="GetExchangeConnection"/>
        /// </summary>
        private readonly string sourceConnectionId = "<exchange connection id>";
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
            var mappingContent = new ExchangeMappingContentModel
            {
                Source = new ExchangeMailBoxModel
                {
                    Mailbox = "<source mailbox>",
                    MailboxType = "UserMailbox",
                },
                Destination = new ExchangeMailBoxModel
                {
                    Mailbox = "<destination mailbox>",
                    MailboxType = "UserMailbox",
                },
                ConvertToSharedMailbox = false,
                MigrateArchivedMailboxOrFolder = true,
                MigrateRecoverableItemsFolder = true,
            };

            var mappings = new ExchangeMappingModel
            {
                SourceConnectionId = sourceConnectionId,
                DestinationConnectionId = destinationConnectionId,
                Contents = new List<ExchangeMappingContentModel>
                {
                    mappingContent
                },
            };

            var planSettings = new ExchangePlanSettingsModel
            {
                NameLabel = new PlanNameLabel
                {
                    Name = $"CSharp_EX_Plan_{DateTime.Now.ToString("yyyyMMddHHmmss")}",
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
                MigrateContacts = true,
                MigrateDistributionGroups = true,
                MigrateMailboxPermissions = true,
                MigrateMailboxRules = true,
                MigratePublicFolders = true,
                SynchronizeDeletion = true,
            };

            var plan = new ExchangePlanModel
            {
                Mappings = mappings,
                Settings = planSettings,
            };

            plan.Validate();

            var requestContent = JsonConvert.SerializeObject(plan);

            var content = new StringContent(requestContent, Encoding.UTF8, "application/json");

            var response = await client.PostAsync("/api/exchange/plans", content);

            return await response.Content.ReadAsStringAsync();
        }
    }
}
