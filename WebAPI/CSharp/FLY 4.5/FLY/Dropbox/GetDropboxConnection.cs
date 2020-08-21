using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace AvePoint.Migration.Samples
{
    class GetDropboxConnection : AbstractApplication
    {
        static void Main(string[] args)
        {
            new GetDropboxConnection().RunAsync().Wait();
        }

        /// <returns>
        /// <see cref="AvePoint.Migration.Api.Models.ServiceResponseListBoxConnectionSummaryModel"/>
        /// </returns>
        protected override async Task<string> RunAsync(HttpClient client)
        {
            var response = await client.GetAsync("/api/dropbox/connections");

            return await response.Content.ReadAsStringAsync();
        }
    }
}
