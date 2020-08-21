using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace AvePoint.Migration.Samples.Exchange
{
    class GetExchangeServiceProvider : AbstractApplication
    {
        static void Main(string[] args)
        {
            new GetExchangeServiceProvider().RunAsync().Wait();
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="client"></param>
        /// <returns><see cref="AvePoint.Migration.Api.Models.ServiceResponseListExchangeServiceProviderModel"/></returns>
        protected override async Task<string> RunAsync(HttpClient client)
        {
            var response = await client.GetAsync("/api/exchange/serviceproviders");

            return await response.Content.ReadAsStringAsync();
        }
    }
}
