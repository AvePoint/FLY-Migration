// <auto-generated>
// Code generated by Microsoft (R) AutoRest Code Generator.
// Changes may cause incorrect behavior and will be lost if the code is
// regenerated.
// </auto-generated>

namespace AvePoint.PowerShell.FLYMigration.Models
{
    using Newtonsoft.Json;
    using System.Linq;

    public partial class FSConnectionsSummaryModel
    {
        /// <summary>
        /// Initializes a new instance of the FSConnectionsSummaryModel class.
        /// </summary>
        public FSConnectionsSummaryModel()
        {
            CustomInit();
        }

        /// <summary>
        /// Initializes a new instance of the FSConnectionsSummaryModel class.
        /// </summary>
        public FSConnectionsSummaryModel(string id = default(string), string path = default(string), string account = default(string))
        {
            Id = id;
            Path = path;
            Account = account;
            CustomInit();
        }

        /// <summary>
        /// An initialization method that performs custom operations like setting defaults
        /// </summary>
        partial void CustomInit();

        /// <summary>
        /// </summary>
        [JsonProperty(PropertyName = "id")]
        public string Id { get; set; }

        /// <summary>
        /// </summary>
        [JsonProperty(PropertyName = "path")]
        public string Path { get; set; }

        /// <summary>
        /// </summary>
        [JsonProperty(PropertyName = "account")]
        public string Account { get; set; }

    }
}
