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
    /// Rerun an exiting job by passing the Job ID and settingss
    /// </summary>
    class RerunFSJob : AbstractApplication
    {
        /// <summary>
        /// <see cref="GetFSJob"/>
        /// <see cref="FindFSJobByPlan"/>
        /// </summary>
        private readonly string jobId = "<job id>";

        static void Main(string[] args)
        {
            new RerunFSJob().RunAsync().Wait();
        }

        /// <returns>
        /// <see cref="ServiceResponseStatusResultModel"/>
        /// </returns>
        protected override async Task<string> RunAsync(HttpClient client)
        {
            if (string.IsNullOrEmpty(jobId))
            {
                throw new ArgumentNullException(nameof(jobId));
            }

            var model = new JobExecutionModel
            {
                IncrementalMigrationScope = "FailedAndIncremental",
                MigrationType = "Incremental",
                StartTime = DateTime.Now.AddMinutes(2),
            };

            var requestContent = JsonConvert.SerializeObject(model);

            var content = new StringContent(requestContent, Encoding.UTF8, "application/json");

            var response = await client.PostAsync($"/api/filesystem/jobs/{jobId}", content);

            return await response.Content.ReadAsStringAsync();
        }
    }
}
