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
    class RemoveBoxPlan : AbstractApplication
    {
        /// <summary>
        /// <see cref="GetBoxPlan"/>
        /// </summary>
        private readonly string planId = "<plan id>";

        static void Main(string[] args)
        {
            new RemoveBoxPlan().RunAsync().Wait();
        }

        protected override async Task<string> RunAsync(HttpClient client)
        {
            if (string.IsNullOrEmpty(planId))
            {
                throw new ArgumentNullException(nameof(planId));
            }

            var response = await client.DeleteAsync($"/api/box/plans/{planId}");

            return await response.Content.ReadAsStringAsync();
        }
    }
}
