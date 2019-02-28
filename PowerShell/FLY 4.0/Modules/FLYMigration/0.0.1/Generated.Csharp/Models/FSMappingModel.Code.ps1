// <auto-generated>
// Code generated by Microsoft (R) AutoRest Code Generator.
// Changes may cause incorrect behavior and will be lost if the code is
// regenerated.
// </auto-generated>

namespace AvePoint.PowerShell.FLYMigration.Models
{
    using Microsoft.Rest;
    using Newtonsoft.Json;
    using System.Collections;
    using System.Collections.Generic;
    using System.Linq;

    public partial class FSMappingModel
    {
        /// <summary>
        /// Initializes a new instance of the FSMappingModel class.
        /// </summary>
        public FSMappingModel()
        {
            CustomInit();
        }

        /// <summary>
        /// Initializes a new instance of the FSMappingModel class.
        /// </summary>
        /// <param
        /// name="destinationCredential">{AvePoint.Migration.Api.Models.AccountModel}</param>
        public FSMappingModel(string sourceConnectionId, SharePointCredential destinationCredential, IList<FSMappingContent> contents)
        {
            SourceConnectionId = sourceConnectionId;
            DestinationCredential = destinationCredential;
            Contents = contents;
            CustomInit();
        }

        /// <summary>
        /// An initialization method that performs custom operations like setting defaults
        /// </summary>
        partial void CustomInit();

        /// <summary>
        /// </summary>
        [JsonProperty(PropertyName = "sourceConnectionId")]
        public string SourceConnectionId { get; set; }

        /// <summary>
        /// Gets or sets {AvePoint.Migration.Api.Models.AccountModel}
        /// </summary>
        [JsonProperty(PropertyName = "destinationCredential")]
        public SharePointCredential DestinationCredential { get; set; }

        /// <summary>
        /// </summary>
        [JsonProperty(PropertyName = "contents")]
        public IList<FSMappingContent> Contents { get; set; }

        /// <summary>
        /// Validate the object.
        /// </summary>
        /// <exception cref="ValidationException">
        /// Thrown if validation fails
        /// </exception>
        public virtual void Validate()
        {
            if (SourceConnectionId == null)
            {
                throw new ValidationException(ValidationRules.CannotBeNull, "SourceConnectionId");
            }
            if (DestinationCredential == null)
            {
                throw new ValidationException(ValidationRules.CannotBeNull, "DestinationCredential");
            }
            if (Contents == null)
            {
                throw new ValidationException(ValidationRules.CannotBeNull, "Contents");
            }
            if (Contents != null)
            {
                foreach (var element in Contents)
                {
                    if (element != null)
                    {
                        element.Validate();
                    }
                }
            }
        }
    }
}
