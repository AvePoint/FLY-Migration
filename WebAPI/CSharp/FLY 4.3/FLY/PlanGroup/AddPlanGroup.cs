using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace AvePoint.Migration.Samples
{
    class AddPlanGroup : AbstractApplication
    {
        static void Main(string[] args)
        {
            new AddPlanGroup().RunAsync().Wait();
        }

        /// <returns>
        /// <see cref="AvePoint.Migration.Api.Models.PlanGroupSummaryModel"/>
        /// </returns>
        protected override async Task<string> RunAsync(HttpClient client)
        {
            var planGroup = new AvePoint.Migration.Api.Models.PlanGroupModel
            {
                Name = "<plan group name>",
                Description = "<plan group description>",
                Method = "Parallel",
                ParallelPlanCount = 10,
                Plans = new List<string>(),
                Schedule = new AvePoint.Migration.Api.Models.ScheduleModel
                {
                    StartTime = DateTime.UtcNow,
                    IntervalType = "OnlyOnce",
                }
            };

            var requestContent = JsonConvert.SerializeObject(planGroup);

            var content = new StringContent(requestContent, Encoding.UTF8, "application/json");

            var response = await client.PostAsync($"/api/plangroups", content);

            return await response.Content.ReadAsStringAsync();
        }
    }
}
