using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace AvePoint.Migration.Samples
{
    class GetExchangeConnection : AbstractApplication
    {
        static void Main(string[] args)
        {
            new GetExchangeConnection().RunAsync().Wait();
        }

        /// <returns>
        /// <see cref="AvePoint.Migration.Api.Models.ServiceResponseListExchangeConnectionSummaryModel"/>
        /// </returns>
        protected override async Task<string> RunAsync(HttpClient client)
        {
            var response = await client.GetAsync("/api/exchange/connections");

            return await response.Content.ReadAsStringAsync();
        }
    }
}
