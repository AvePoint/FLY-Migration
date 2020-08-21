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
    class DeletePSTFileJob : AbstractApplication
    {
        /// <summary>
        /// <see cref="GetPSTFileJob"/>
        /// <see cref="FindPSTFileJobByPlan"/>
        /// </summary>
        private readonly string id = "<job id>";

        static void Main(string[] args)
        {
            new DeletePSTFileJob().RunAsync().Wait();
        }

        /// <returns>
        /// <see cref="AvePoint.Migration.Api.Models.StatusResultModel"/>
        /// </returns>
        protected override async Task<string> RunAsync(HttpClient client)
        {
            var response = await client.DeleteAsync($"/api/pstfiles/plans/{id}");

            return await response.Content.ReadAsStringAsync();
        }
    }
}
