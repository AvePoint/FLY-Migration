﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace AvePoint.Migration.Samples
{
    /// <summary>
    /// Returns a list of plan groups
    /// </summary>
    class GetPlanGroups : AbstractApplication
    {
        static void Main(string[] args)
        {
            new GetPlanGroups().RunAsync().Wait();
        }

        /// <returns>
        /// <see cref="AvePoint.Migration.Api.Models.ServiceResponseListPlanGroupSummaryModel"/>
        /// </returns>
        protected override async Task<string> RunAsync(HttpClient client)
        {
            var response = await client.GetAsync("/api/plangroups");

            return await response.Content.ReadAsStringAsync();
        }
    }
}
