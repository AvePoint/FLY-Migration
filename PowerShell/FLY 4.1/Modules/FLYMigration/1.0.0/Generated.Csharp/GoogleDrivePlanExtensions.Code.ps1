// <auto-generated>
// Code generated by Microsoft (R) AutoRest Code Generator.
// Changes may cause incorrect behavior and will be lost if the code is
// regenerated.
// </auto-generated>

namespace AvePoint.PowerShell.FLYMigration
{
    using Models;
    using System.Threading;
    using System.Threading.Tasks;

    /// <summary>
    /// Extension methods for GoogleDrivePlan.
    /// </summary>
    public static partial class GoogleDrivePlanExtensions
    {
            /// <summary>
            /// Get all plans
            /// </summary>
            /// <remarks>
            /// Returns a list of all plans
            /// </remarks>
            /// <param name='operations'>
            /// The operations group for this extension method.
            /// </param>
            public static ServiceResponseListPlanSummaryModel Get(this IGoogleDrivePlan operations)
            {
                return operations.GetAsync().GetAwaiter().GetResult();
            }

            /// <summary>
            /// Get all plans
            /// </summary>
            /// <remarks>
            /// Returns a list of all plans
            /// </remarks>
            /// <param name='operations'>
            /// The operations group for this extension method.
            /// </param>
            /// <param name='cancellationToken'>
            /// The cancellation token.
            /// </param>
            public static async Task<ServiceResponseListPlanSummaryModel> GetAsync(this IGoogleDrivePlan operations, CancellationToken cancellationToken = default(CancellationToken))
            {
                using (var _result = await operations.GetWithHttpMessagesAsync(null, cancellationToken).ConfigureAwait(false))
                {
                    return _result.Body;
                }
            }

            /// <summary>
            /// Create a new plan
            /// </summary>
            /// <remarks>
            /// Create a new migration plan by passing the plan settings
            /// </remarks>
            /// <param name='operations'>
            /// The operations group for this extension method.
            /// </param>
            /// <param name='planSettings'>
            /// Detailed settings of the plan
            /// </param>
            public static ServiceResponsePlanSummaryModel Add(this IGoogleDrivePlan operations, GoogleDrivePlanModel planSettings)
            {
                return operations.AddAsync(planSettings).GetAwaiter().GetResult();
            }

            /// <summary>
            /// Create a new plan
            /// </summary>
            /// <remarks>
            /// Create a new migration plan by passing the plan settings
            /// </remarks>
            /// <param name='operations'>
            /// The operations group for this extension method.
            /// </param>
            /// <param name='planSettings'>
            /// Detailed settings of the plan
            /// </param>
            /// <param name='cancellationToken'>
            /// The cancellation token.
            /// </param>
            public static async Task<ServiceResponsePlanSummaryModel> AddAsync(this IGoogleDrivePlan operations, GoogleDrivePlanModel planSettings, CancellationToken cancellationToken = default(CancellationToken))
            {
                using (var _result = await operations.AddWithHttpMessagesAsync(planSettings, null, cancellationToken).ConfigureAwait(false))
                {
                    return _result.Body;
                }
            }

    }
}
