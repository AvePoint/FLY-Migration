// <auto-generated>
// Code generated by Microsoft (R) AutoRest Code Generator.
// Changes may cause incorrect behavior and will be lost if the code is
// regenerated.
// </auto-generated>

namespace AvePoint.PowerShell.FLYMigration.Models
{
    using Newtonsoft.Json;
    using System.Linq;

    public partial class AppProfileModel
    {
        /// <summary>
        /// Initializes a new instance of the AppProfileModel class.
        /// </summary>
        public AppProfileModel()
        {
            CustomInit();
        }

        /// <summary>
        /// Initializes a new instance of the AppProfileModel class.
        /// </summary>
        public AppProfileModel(string id = default(string), string name = default(string), string globalAdministrator = default(string), string status = default(string))
        {
            Id = id;
            Name = name;
            GlobalAdministrator = globalAdministrator;
            Status = status;
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
        [JsonProperty(PropertyName = "name")]
        public string Name { get; set; }

        /// <summary>
        /// </summary>
        [JsonProperty(PropertyName = "globalAdministrator")]
        public string GlobalAdministrator { get; set; }

        /// <summary>
        /// </summary>
        [JsonProperty(PropertyName = "status")]
        public string Status { get; set; }

    }
}
