using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace AvePoint.Migration.Samples
{
    class GetExchangePlan : AbstractApplication
    {
        static void Main(string[] args)
        {
            new GetExchangePlan().RunAsync().Wait();
        }
        /// <returns>
        /// <see cref="AvePoint.Migration.Api.Models.ServiceResponseListPlanSummaryModel"/>
        /// </returns>
        protected override async Task<string> RunAsync(HttpClient client)
        {
            var response = await client.GetAsync("/api/exchange/plans");

            return await response.Content.ReadAsStringAsync();
        }
    }
}
