using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace AvePoint.Migration.Samples
{
    /// <summary>
    /// Return a list of jobs of the plan
    /// </summary>
    class FindFSJobByPlan : AbstractApplication
    {
        /// <summary>
        /// <see cref="GetFSPlan"/>
        /// </summary>
        private readonly string planId = "<plan id>";

        static void Main(string[] args)
        {
            new FindFSJobByPlan().RunAsync().Wait();
        }

        /// <returns>
        /// <see cref="AvePoint.Migration.Api.Models.ServiceResponsePageResultViewModelListJobSummaryModel"/>
        /// </returns>
        protected override async Task<string> RunAsync(HttpClient client)
        {
            if (string.IsNullOrEmpty(planId))
            {
                throw new ArgumentNullException(nameof(planId));
            }

            var response = await client.GetAsync($"/api/filesystem/plans/{planId}/jobs");

            return await response.Content.ReadAsStringAsync();
        }
    }
}
