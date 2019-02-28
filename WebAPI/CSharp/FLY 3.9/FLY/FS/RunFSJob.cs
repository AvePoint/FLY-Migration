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
    class RunFSJob : AbstractApplication
    {
        static void Main(string[] args)
        {
            new RunFSJob().RunAsync().Wait();
        }
        /// <returns>
        /// <see cref="ServiceResponseString"/>
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

            var mappingContent = new FSMappingContent
            {
                Source = new FSPath
                {
                    Path = "<path>",
                },
                Destination = new SharePointObject
                {
                    Url = "<sharepoint library url>",
                    Level = "Library"
                }
            };

            var mappings = new FSMappingModel
            {
                SourceAccount = sourceAccount,
                DestinationAccount = destinationAccount,
                Contents = new List<FSMappingContent>
                {
                    mappingContent
                },
            };

            var settings = new FSJobExecutionSettingsModel
            {
                MigrationMode = "HighSpeed",
                PolicyId = "Default_FileMigration_Profile",
                Schedule = new ScheduleModel
                {
                    IntervalType = "OnlyOnce",
                    StartTime = DateTime.Now.AddMinutes(2),
                },
            };

            var model = new FSJobExecutionModel
            {
                Mappings = mappings,
                Settings = settings,
            };

            var requestContent = JsonConvert.SerializeObject(model);

            var content = new StringContent(requestContent, Encoding.UTF8, "application/json");

            var response = await client.PostAsync($"/api/filesystem/jobs", content);

            return await response.Content.ReadAsStringAsync();
        }
    }
}
