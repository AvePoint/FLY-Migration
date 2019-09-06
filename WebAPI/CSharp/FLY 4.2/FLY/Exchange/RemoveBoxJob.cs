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
    class RemoveBoxJob : AbstractApplication
    {
        /// <summary>
        /// <see cref="GetBoxJob"/>
        /// <see cref="FindBoxJobByPlan"/>
        /// </summary>
        private readonly string jobId = "<job id>";

        static void Main(string[] args)
        {
            new RemoveBoxJob().RunAsync().Wait();
        }

        protected override async Task<string> RunAsync(HttpClient client)
        {
            if (string.IsNullOrEmpty(jobId))
            {
                throw new ArgumentNullException(nameof(jobId));
            }

            var response = await client.DeleteAsync($"/api/box/jobs/{jobId}");

            return await response.Content.ReadAsStringAsync();
        }
    }
}
