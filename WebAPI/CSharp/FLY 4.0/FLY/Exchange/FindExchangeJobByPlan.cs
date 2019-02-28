using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace AvePoint.Migration.Samples
{
    class FindExchangeJobByPlan : AbstractApplication
    {
        /// <summary>
        /// <see cref="GetExchangePlan"/>
        /// </summary>
        private readonly string planId = "<plan id>";

        static void Main(string[] args)
        {
            new FindExchangeJobByPlan().RunAsync().Wait();
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

            var response = await client.GetAsync($"/api/exchange/plans/{planId}/jobs");

            return await response.Content.ReadAsStringAsync();
        }
    }
}
