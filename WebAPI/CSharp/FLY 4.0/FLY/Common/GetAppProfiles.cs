using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace AvePoint.Migration.Samples
{
    class GetAppProfiles : AbstractApplication
    {
        static void Main(string[] args)
        {
            new GetAppProfiles().RunAsync().Wait();
        }

        /// <returns>
        /// <see cref="AvePoint.Migration.Api.Models.ServiceResponseListAppProfileModel"/>
        /// </returns>
        protected override async Task<string> RunAsync(HttpClient client)
        {
            var response = await client.GetAsync("/api/appprofiles");

            return await response.Content.ReadAsStringAsync();
        }
    }
}
