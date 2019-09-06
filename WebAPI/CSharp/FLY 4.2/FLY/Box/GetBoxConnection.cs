using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace AvePoint.Migration.Samples
{
    class GetBoxConnection : AbstractApplication
    {
        static void Main(string[] args)
        {
            new GetBoxConnection().RunAsync().Wait();
        }

        /// <returns>
        /// <see cref="AvePoint.Migration.Api.Models.ServiceResponseListBoxConnectionSummaryModel"/>
        /// </returns>
        protected override async Task<string> RunAsync(HttpClient client)
        {
            var response = await client.GetAsync("/api/box/connections");

            return await response.Content.ReadAsStringAsync();
        }
    }
}
