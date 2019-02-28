using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace AvePoint.Migration.Samples
{
    class GetFSConnection : AbstractApplication
    {
        static void Main(string[] args)
        {
            new GetFSConnection().RunAsync().Wait();
        }

        /// <returns>
        /// <see cref="AvePoint.Migration.Api.Models.ServiceResponseListFSConnectionsSummaryModel"/>
        /// </returns>
        protected override async Task<string> RunAsync(HttpClient client)
        {
            var response = await client.GetAsync("/api/filesystem/connections");

            return await response.Content.ReadAsStringAsync();
        }
    }
}
