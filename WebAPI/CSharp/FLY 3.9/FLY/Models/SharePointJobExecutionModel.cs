// <auto-generated>
// Code generated by Microsoft (R) AutoRest Code Generator.
// Changes may cause incorrect behavior and will be lost if the code is
// regenerated.
// </auto-generated>

namespace AvePoint.Migration.Api.Models
{
    using Microsoft.Rest;
    using Newtonsoft.Json;
    using System.Linq;

    public partial class SharePointJobExecutionModel
    {
        /// <summary>
        /// Initializes a new instance of the SharePointJobExecutionModel
        /// class.
        /// </summary>
        public SharePointJobExecutionModel()
        {
            CustomInit();
        }

        /// <summary>
        /// Initializes a new instance of the SharePointJobExecutionModel
        /// class.
        /// </summary>
        /// <param name="mappings">Migration Mappings
        /// {AvePoint.Migration.Api.Models.SharePointMappingModel}</param>
        public SharePointJobExecutionModel(SharePointMappingModel mappings, SharePointJobExecutionSettingsModel settings = default(SharePointJobExecutionSettingsModel))
        {
            Mappings = mappings;
            Settings = settings;
            CustomInit();
        }

        /// <summary>
        /// An initialization method that performs custom operations like setting defaults
        /// </summary>
        partial void CustomInit();

        /// <summary>
        /// Gets or sets migration Mappings
        /// {AvePoint.Migration.Api.Models.SharePointMappingModel}
        /// </summary>
        [JsonProperty(PropertyName = "mappings")]
        public SharePointMappingModel Mappings { get; set; }

        /// <summary>
        /// </summary>
        [JsonProperty(PropertyName = "settings")]
        public SharePointJobExecutionSettingsModel Settings { get; set; }

        /// <summary>
        /// Validate the object.
        /// </summary>
        /// <exception cref="ValidationException">
        /// Thrown if validation fails
        /// </exception>
        public virtual void Validate()
        {
            if (Mappings == null)
            {
                throw new ValidationException(ValidationRules.CannotBeNull, "Mappings");
            }
            if (Mappings != null)
            {
                Mappings.Validate();
            }
            if (Settings != null)
            {
                Settings.Validate();
            }
        }
    }
}