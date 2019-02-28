using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace AvePoint.Migration.Samples
{
    /// <summary>
    /// Returns a list of all plans
    /// </summary>
    class GetFSPlan : AbstractApplication
    {
        static void Main(string[] args)
        {
            new GetFSPlan().RunAsync().Wait();
        }
        /// <returns>
        /// <see cref="AvePoint.Migration.Api.Models.ServiceResponseListPlanSummaryModel"/>
        /// </returns>
        protected override async Task<string> RunAsync(HttpClient client)
        {
            var response = await client.GetAsync("/api/filesystem/plans");

            return await response.Content.ReadAsStringAsync();
        }
    }
}
