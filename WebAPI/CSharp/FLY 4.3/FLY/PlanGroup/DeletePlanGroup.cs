using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace AvePoint.Migration.Samples
{
    class DeletePlanGroup : AbstractApplication
    {
        static void Main(string[] args)
        {
            new DeletePlanGroup().RunAsync().Wait();
        }

        /// <returns>
        /// <see cref="GetPlanGroups"/>
        /// </returns>
        private readonly string id = "<plan group id>";

        /// <returns>
        /// <see cref="AvePoint.Migration.Api.Models.StatusResultModel"/>
        /// </returns>
        protected override async Task<string> RunAsync(HttpClient client)
        {
            var response = await client.DeleteAsync($"/api/plangroups/{id}");

            return await response.Content.ReadAsStringAsync();
        }
    }
}
