using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace AvePoint.Migration.Samples
{
    /// <summary>
    /// Delete a migration plan
    /// </summary>
    class DeleteMSTeamsPlan : AbstractApplication
    {
        /// <summary>
        /// <see cref="GetMSTeamsPlan"/>
        /// </summary>
        private readonly string id = "<plan id>";

        static void Main(string[] args)
        {
            new DeleteMSTeamsPlan().RunAsync().Wait();
        }

        /// <returns>
        /// <see cref="AvePoint.Migration.Api.Models.StatusResultModel"/>
        /// </returns>
        protected override async Task<string> RunAsync(HttpClient client)
        {
            var response = await client.DeleteAsync($"/api/microsoftteams/plans/{id}");

            return await response.Content.ReadAsStringAsync();
        }
    }
}
