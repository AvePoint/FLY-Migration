// <auto-generated>
// Code generated by Microsoft (R) AutoRest Code Generator.
// Changes may cause incorrect behavior and will be lost if the code is
// regenerated.
// </auto-generated>

namespace AvePoint.PowerShell.FLYMigration.Models
{
    using Microsoft.Rest;
    using Newtonsoft.Json;
    using System.Linq;

    public partial class ConversationsMigrationSettings
    {
        /// <summary>
        /// Initializes a new instance of the ConversationsMigrationSettings
        /// class.
        /// </summary>
        public ConversationsMigrationSettings()
        {
            CustomInit();
        }

        /// <summary>
        /// Initializes a new instance of the ConversationsMigrationSettings
        /// class.
        /// </summary>
        /// <param name="style">Possible values include: 'HTMLFile',
        /// 'HTMLFileAndMessages'</param>
        /// <param name="scope">Possible values include: 'All',
        /// 'Customization'</param>
        /// <param name="duration">Migrate conversations within the last [x]
        /// days or months</param>
        /// <param name="durationUnit">the duration unit to migrate
        /// conversations within a specific period. Possible values include:
        /// 'Day', 'Month'</param>
        public ConversationsMigrationSettings(string style, string scope, int? duration = default(int?), string durationUnit = default(string))
        {
            Style = style;
            Scope = scope;
            Duration = duration;
            DurationUnit = durationUnit;
            CustomInit();
        }

        /// <summary>
        /// An initialization method that performs custom operations like setting defaults
        /// </summary>
        partial void CustomInit();

        /// <summary>
        /// Gets or sets possible values include: 'HTMLFile',
        /// 'HTMLFileAndMessages'
        /// </summary>
        [JsonProperty(PropertyName = "style")]
        public string Style { get; set; }

        /// <summary>
        /// Gets or sets possible values include: 'All', 'Customization'
        /// </summary>
        [JsonProperty(PropertyName = "scope")]
        public string Scope { get; set; }

        /// <summary>
        /// Gets or sets migrate conversations within the last [x] days or
        /// months
        /// </summary>
        [JsonProperty(PropertyName = "duration")]
        public int? Duration { get; set; }

        /// <summary>
        /// Gets or sets the duration unit to migrate conversations within a
        /// specific period. Possible values include: 'Day', 'Month'
        /// </summary>
        [JsonProperty(PropertyName = "durationUnit")]
        public string DurationUnit { get; set; }

        /// <summary>
        /// Validate the object.
        /// </summary>
        /// <exception cref="ValidationException">
        /// Thrown if validation fails
        /// </exception>
        public virtual void Validate()
        {
            if (Style == null)
            {
                throw new ValidationException(ValidationRules.CannotBeNull, "Style");
            }
            if (Scope == null)
            {
                throw new ValidationException(ValidationRules.CannotBeNull, "Scope");
            }
        }
    }
}