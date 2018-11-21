using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace AvePoint.Migration.Samples
{
    /// <summary>
    /// Returns a list of jobs
    /// </summary>
    class GetSPJob : AbstractApplication
    {
        private readonly int pageNumber = 1;

        private readonly int pageSize = 50;

        static void Main(string[] args)
        {
            new GetSPJob().RunAsync().Wait();
        }

        /// <returns>
        /// <see cref="AvePoint.Migration.Api.Models.ServiceResponsePageResultViewModelListJobSummaryModel"/>
        /// </returns>
        protected override async Task<string> RunAsync(HttpClient client)
        {
            var response = await client.GetAsync($"/api/sharepoint/jobs?pageNumber={pageNumber}&pageSize={pageSize}");

            return await response.Content.ReadAsStringAsync();
        }
    }
}
