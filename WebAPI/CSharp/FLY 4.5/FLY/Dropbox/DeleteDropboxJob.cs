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
    class DeleteDropboxJob : AbstractApplication
    {
        /// <summary>
        /// <see cref="GetDropboxJob"/>
        /// <see cref="FindDropboxJobByPlan"/>
        /// </summary>
        private readonly string id = "<job id>";

        static void Main(string[] args)
        {
            new DeleteDropboxJob().RunAsync().Wait();
        }

        /// <returns>
        /// <see cref="AvePoint.Migration.Api.Models.StatusResultModel"/>
        /// </returns>
        protected override async Task<string> RunAsync(HttpClient client)
        {
            var response = await client.DeleteAsync($"/api/dropbox/jobs/{id}");

            return await response.Content.ReadAsStringAsync();
        }
    }
}
