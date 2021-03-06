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

    public partial class PlanGroupModel
    {
        /// <summary>
        /// Initializes a new instance of the PlanGroupModel class.
        /// </summary>
        public PlanGroupModel()
        {
            CustomInit();
        }

        /// <summary>
        /// Initializes a new instance of the PlanGroupModel class.
        /// </summary>
        /// <param name="name">Name of the plan group.</param>
        /// <param name="method">Choose a group type to run the plans in the
        /// plan group.
        /// "Parallel" will run multiple plans simultaneously according to the
        /// specified concurrent plan count.
        /// "Sequential" will run the plans according to their order in the
        /// plan group.
        /// Possible values include: ['Parallel', 'Sequential']. Possible
        /// values include: 'Parallel', 'Sequential'</param>
        /// <param name="description">Description of the plan group.</param>
        /// <param name="parallelPlanCount">Specify the number of the
        /// concurrent plans.
        /// Concurrent plan allows you to simultaneously run multiple plans in
        /// one plan group.</param>
        /// <param name="schedule">The schedule of the plan groups.</param>
        /// <param name="plans">The list of the plan id.
        /// The plans will be managed by this plan group, and the plan
        /// schedules will be disabled.</param>
        public PlanGroupModel(string name, string method, string description = default(string), int? parallelPlanCount = default(int?), ScheduleModel schedule = default(ScheduleModel), IList<string> plans = default(IList<string>))
        {
            Name = name;
            Description = description;
            Method = method;
            ParallelPlanCount = parallelPlanCount;
            Schedule = schedule;
            Plans = plans;
            CustomInit();
        }

        /// <summary>
        /// An initialization method that performs custom operations like setting defaults
        /// </summary>
        partial void CustomInit();

        /// <summary>
        /// Gets or sets name of the plan group.
        /// </summary>
        [JsonProperty(PropertyName = "name")]
        public string Name { get; set; }

        /// <summary>
        /// Gets or sets description of the plan group.
        /// </summary>
        [JsonProperty(PropertyName = "description")]
        public string Description { get; set; }

        /// <summary>
        /// Gets or sets choose a group type to run the plans in the plan
        /// group.
        /// "Parallel" will run multiple plans simultaneously according to the
        /// specified concurrent plan count.
        /// "Sequential" will run the plans according to their order in the
        /// plan group.
        /// Possible values include: ['Parallel', 'Sequential']. Possible
        /// values include: 'Parallel', 'Sequential'
        /// </summary>
        [JsonProperty(PropertyName = "method")]
        public string Method { get; set; }

        /// <summary>
        /// Gets or sets specify the number of the concurrent plans.
        /// Concurrent plan allows you to simultaneously run multiple plans in
        /// one plan group.
        /// </summary>
        [JsonProperty(PropertyName = "parallelPlanCount")]
        public int? ParallelPlanCount { get; set; }

        /// <summary>
        /// Gets or sets the schedule of the plan groups.
        /// </summary>
        [JsonProperty(PropertyName = "schedule")]
        public ScheduleModel Schedule { get; set; }

        /// <summary>
        /// Gets or sets the list of the plan id.
        /// The plans will be managed by this plan group, and the plan
        /// schedules will be disabled.
        /// </summary>
        [JsonProperty(PropertyName = "plans")]
        public IList<string> Plans { get; set; }

        /// <summary>
        /// Validate the object.
        /// </summary>
        /// <exception cref="ValidationException">
        /// Thrown if validation fails
        /// </exception>
        public virtual void Validate()
        {
            if (Name == null)
            {
                throw new ValidationException(ValidationRules.CannotBeNull, "Name");
            }
            if (Method == null)
            {
                throw new ValidationException(ValidationRules.CannotBeNull, "Method");
            }
            if (Schedule != null)
            {
                Schedule.Validate();
            }
        }
    }
}
