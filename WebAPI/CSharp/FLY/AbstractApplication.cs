using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using Newtonsoft.Json.Serialization;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace AvePoint.Migration.Samples
{
    abstract class AbstractApplication
    {
        protected string BaseUri { get { return ConfigurationManager.AppSettings.Get("BaseUri"); } }

        protected string ApiKey { get { return ConfigurationManager.AppSettings.Get("ApiKey"); } }

        internal AbstractApplication()
        {
            ServicePointManager.ServerCertificateValidationCallback = (sender, certificate, chain, sslPolicyErrors) => true;
            JsonConvert.DefaultSettings = () => new JsonSerializerSettings
            {
                DateFormatHandling = DateFormatHandling.IsoDateFormat,
                DateTimeZoneHandling = DateTimeZoneHandling.Utc,
                NullValueHandling = NullValueHandling.Ignore,
                ContractResolver = new CamelCasePropertyNamesContractResolver(),
            };
        }

        protected async Task RunAsync()
        {
            try
            {
                using (var client = new HttpClient { BaseAddress = new Uri(BaseUri) })
                {
                    client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("api_key", ApiKey);
                    var responseContent = await RunAsync(client);
                    Console.WriteLine(JToken.Parse(responseContent).ToString(Formatting.Indented));
                }
            }
            catch (Exception e)
            {
                Console.WriteLine("The application terminated with an error.");
                Console.WriteLine(e.ToString());
            }
            finally
            {
                Console.ReadKey();
            }
        }

        protected abstract Task<string> RunAsync(HttpClient client);
    }
}
