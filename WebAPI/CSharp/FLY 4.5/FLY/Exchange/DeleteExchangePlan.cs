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
    class DeleteExchangePlan : AbstractApplication
    {
        /// <summary>
        /// <see cref="GetExchangePlan"/>
        /// </summary>
        private readonly string id = "<plan id>";

        static void Main(string[] args)
        {
            new DeleteExchangePlan().RunAsync().Wait();
        }

        /// <returns>
        /// <see cref="AvePoint.Migration.Api.Models.StatusResultModel"/>
        /// </returns>
        protected override async Task<string> RunAsync(HttpClient client)
        {
            var response = await client.DeleteAsync($"/api/exchange/plans/{id}");

            return await response.Content.ReadAsStringAsync();
        }
    }
}
