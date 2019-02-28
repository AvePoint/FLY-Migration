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
    class RunSPJob : AbstractApplication
    {
        static void Main(string[] args)
        {
            new RunSPJob().RunAsync().Wait();
        }

        /// <returns>
        /// <see cref="ServiceResponsePlanSummaryModel"/>
        /// </returns>
        protected override async Task<string> RunAsync(HttpClient client)
        {
            var sourceAccount = new AccountModel
            {
                Username = "<account>",
                Password = "<password>",
            };

            var destinationAccount = new AccountModel
            {
                Username = "<account>",
                Password = "<password>",
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
                Method = "Combine"
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
                Method = "Combine"
            };

            var mappings = new SharePointMappingModel
            {
                SourceAccount = sourceAccount,
                DestinationAccount = destinationAccount,
                Contents = new List<SharePointMappingContent>
                {
                    siteLevelMappingContent,
                    siteCollectionLevelMappingContent
                },
            };

            var settings = new SharePointJobExecutionSettingsModel
            {
                MigrationMode = "HighSpeed",
                PolicyId = "Default_SP07To10MigrationOnlineMapping_Profile",
                Schedule = new ScheduleModel
                {
                    IntervalType = "OnlyOnce",
                    StartTime = DateTime.Now.AddMinutes(2),
                },
            };

            var model = new SharePointJobExecutionModel
            {
                Mappings = mappings,
                Settings = settings,
            };

            var requestContent = JsonConvert.SerializeObject(model);

            var content = new StringContent(requestContent, Encoding.UTF8, "application/json");

            var response = await client.PostAsync("/api/sharepoint/jobs", content);

            return await response.Content.ReadAsStringAsync();
        }
    }
}
