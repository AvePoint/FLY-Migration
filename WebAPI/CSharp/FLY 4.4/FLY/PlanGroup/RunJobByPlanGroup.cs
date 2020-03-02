using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace AvePoint.Migration.Samples
{
    class RunJobByPlanGroup : AbstractApplication
    {
        static void Main(string[] args)
        {
            new RunJobByPlanGroup().RunAsync().Wait();
        }

        /// <returns>
        /// <see cref="GetPlanGroups"/>
        /// </returns>
        private readonly string id = "<plan group id>";

        /// <returns>
        /// <see cref="AvePoint.Migration.Api.Models.StatusResultModel"/>
        /// </returns>
        protected override async Task<string> RunAsync(HttpClient client)
        {
            var settings = new AvePoint.Migration.Api.Models.PlanExecutionModel
            {
                MigrationType = "Incremental"
            };

            var requestContent = JsonConvert.SerializeObject(settings);

            var content = new StringContent(requestContent, Encoding.UTF8, "application/json");

            var response = await client.PostAsync($"/api/plangroups/{id}/jobs", content);

            return await response.Content.ReadAsStringAsync();
        }
    }
}
