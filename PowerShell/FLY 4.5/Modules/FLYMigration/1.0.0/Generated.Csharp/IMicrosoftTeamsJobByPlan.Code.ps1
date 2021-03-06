// <auto-generated>
// Code generated by Microsoft (R) AutoRest Code Generator.
// Changes may cause incorrect behavior and will be lost if the code is
// regenerated.
// </auto-generated>

namespace AvePoint.PowerShell.FLYMigration
{
    using Microsoft.Rest;
    using Models;
    using System.Collections;
    using System.Collections.Generic;
    using System.Threading;
    using System.Threading.Tasks;

    /// <summary>
    /// MicrosoftTeamsJobByPlan operations.
    /// </summary>
    public partial interface IMicrosoftTeamsJobByPlan
    {
        /// <summary>
        /// Run a new job by plan ID
        /// </summary>
        /// <remarks>
        /// Run a new job of a plan by passing the ID of the plan and plan
        /// settings
        /// </remarks>
        /// <param name='id'>
        /// ID of the plan
        /// </param>
        /// <param name='settings'>
        /// job mode
        /// </param>
        /// <param name='customHeaders'>
        /// The headers that will be added to request.
        /// </param>
        /// <param name='cancellationToken'>
        /// The cancellation token.
        /// </param>
        /// <exception cref="Microsoft.Rest.HttpOperationException">
        /// Thrown when the operation returned an invalid status code
        /// </exception>
        /// <exception cref="Microsoft.Rest.SerializationException">
        /// Thrown when unable to deserialize the response
        /// </exception>
        /// <exception cref="Microsoft.Rest.ValidationException">
        /// Thrown when a required parameter is null
        /// </exception>
        Task<HttpOperationResponse<ServiceResponseStatusResultModel>> StartWithHttpMessagesAsync(string id, MSTeamsPlanExecutionModel settings, Dictionary<string, List<string>> customHeaders = null, CancellationToken cancellationToken = default(CancellationToken));
    }
}
