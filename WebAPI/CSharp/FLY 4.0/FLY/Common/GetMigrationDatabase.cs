using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace AvePoint.Migration.Samples
{
    class GetMigrationDatabase : AbstractApplication
    {
        static void Main(string[] args)
        {
            new GetMigrationDatabase().RunAsync().Wait();
        }

        /// <returns>
        /// <see cref="AvePoint.Migration.Api.Models.ServiceResponseListDatabaseSummaryModel"/>
        /// </returns>
        protected override async Task<string> RunAsync(HttpClient client)
        {
            var response = await client.GetAsync("/api/databases");

            return await response.Content.ReadAsStringAsync();
        }
    }
}
