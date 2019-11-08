using AvePoint.Migration.Api.Models;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace AvePoint.Migration.Samples
{
    class AddSharePointConnections : AbstractApplication
    {
        static void Main(string[] args)
        {
            new AddSharePointConnections().RunAsync().Wait();
        }

        protected override async Task<string> RunAsync(HttpClient client)
        {
            var connectionContent = new SharePointConnectionCollectionModel
            {
                Connections = new List<SharePointConnectionModel>(),
            };

            var model = new SharePointConnectionModel
            {
                Account = "<Account Name>",
                Password = "<Account Password>",
                AppProfileName = "<App Profile Name>",
                SiteCollections = new List<string> { "<SharePoint Site Url>" },
            };

            connectionContent.Connections.Add(model);

            var requestContent = JsonConvert.SerializeObject(connectionContent);

            var content = new StringContent(requestContent, Encoding.UTF8, "application/json");

            var response = await client.PostAsync("/api/sharepoint/connections", content);

            return await response.Content.ReadAsStringAsync();

        }
    }
}
