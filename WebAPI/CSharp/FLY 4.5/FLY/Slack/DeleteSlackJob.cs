using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace AvePoint.Migration.Samples
{
    /// <summary>
    /// Delete a migration job
    /// </summary>
    class DeleteSlackJob : AbstractApplication
    {
        /// <summary>
        /// <see cref="GetSlackJob"/>
        /// <see cref="FindSlackJobByPlan"/>
        /// </summary>
        private readonly string id = "<job id>";

        static void Main(string[] args)
        {
            new DeleteSlackJob().RunAsync().Wait();
        }

        /// <returns>
        /// <see cref="AvePoint.Migration.Api.Models.StatusResultModel"/>
        /// </returns>
        protected override async Task<string> RunAsync(HttpClient client)
        {
            var response = await client.DeleteAsync($"/api/slack/jobs/{id}");

            return await response.Content.ReadAsStringAsync();
        }
    }
}
