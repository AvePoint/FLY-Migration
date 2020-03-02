using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace AvePoint.Migration.Samples
{
    /// <summary>
    /// Stop a migration job
    /// </summary>
    class StopIMAPPOP3Job : AbstractApplication
    {
        /// <summary>
        /// <see cref="GetIMAPPOP3Job"/>
        /// <see cref="FindIMAPPOP3JobByPlan"/>
        /// </summary>
        private readonly string id = "<job id>";

        static void Main(string[] args)
        {
            new StopIMAPPOP3Job().RunAsync().Wait();
        }

        /// <returns>
        /// <see cref="AvePoint.Migration.Api.Models.StatusResultModel"/>
        /// </returns>
        protected override async Task<string> RunAsync(HttpClient client)
        {
            var response = await client.PutAsync($"/api/imap-pop3/jobs/{id}/status/stopped", null);

            return await response.Content.ReadAsStringAsync();
        }
    }
}
