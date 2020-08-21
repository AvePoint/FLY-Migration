using System.Net.Http;
using System.Threading.Tasks;

namespace AvePoint.Migration.Samples.Exchange
{
    class SearchExchangeServiceProvider : AbstractApplication
    {
        private readonly string providerName = "<provider name>";

        static void Main(string[] args)
        {
            new SearchExchangeServiceProvider().RunAsync().Wait();
        }
        /// <summary>
        /// 
        /// </summary>
        /// <param name="client"></param>
        /// <returns><see cref="AvePoint.Migration.Api.Models.ServiceResponseListExchangeServiceProviderModel"/></returns>
        protected override async Task<string> RunAsync(HttpClient client)
        {
            var response = await client.GetAsync($"/api/exchange/serviceproviders/search?name={providerName}");

            return await response.Content.ReadAsStringAsync();
        }
    }
}
