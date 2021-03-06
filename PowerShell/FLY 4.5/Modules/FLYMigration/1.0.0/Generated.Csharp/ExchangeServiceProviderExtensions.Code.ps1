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
    /// Extension methods for ExchangeServiceProvider.
    /// </summary>
    public static partial class ExchangeServiceProviderExtensions
    {
            /// <param name='operations'>
            /// The operations group for this extension method.
            /// </param>
            public static ServiceResponseListExchangeServiceProviderModel Get(this IExchangeServiceProvider operations)
            {
                return operations.GetAsync().GetAwaiter().GetResult();
            }

            /// <param name='operations'>
            /// The operations group for this extension method.
            /// </param>
            /// <param name='cancellationToken'>
            /// The cancellation token.
            /// </param>
            public static async Task<ServiceResponseListExchangeServiceProviderModel> GetAsync(this IExchangeServiceProvider operations, CancellationToken cancellationToken = default(CancellationToken))
            {
                using (var _result = await operations.GetWithHttpMessagesAsync(null, cancellationToken).ConfigureAwait(false))
                {
                    return _result.Body;
                }
            }

            /// <param name='operations'>
            /// The operations group for this extension method.
            /// </param>
            /// <param name='name'>
            /// </param>
            /// <param name='version'>
            /// Possible values include: 'None', 'Exchange2010', 'Exchange2010SP2',
            /// 'Exchange2010SP3', 'Exchange2013', 'Exchange2013SP1', 'Exchange2016',
            /// 'Exchange2019'
            /// </param>
            public static ServiceResponseListExchangeServiceProviderModel Search(this IExchangeServiceProvider operations, string name, string version = default(string))
            {
                return operations.SearchAsync(name, version).GetAwaiter().GetResult();
            }

            /// <param name='operations'>
            /// The operations group for this extension method.
            /// </param>
            /// <param name='name'>
            /// </param>
            /// <param name='version'>
            /// Possible values include: 'None', 'Exchange2010', 'Exchange2010SP2',
            /// 'Exchange2010SP3', 'Exchange2013', 'Exchange2013SP1', 'Exchange2016',
            /// 'Exchange2019'
            /// </param>
            /// <param name='cancellationToken'>
            /// The cancellation token.
            /// </param>
            public static async Task<ServiceResponseListExchangeServiceProviderModel> SearchAsync(this IExchangeServiceProvider operations, string name, string version = default(string), CancellationToken cancellationToken = default(CancellationToken))
            {
                using (var _result = await operations.SearchWithHttpMessagesAsync(name, version, null, cancellationToken).ConfigureAwait(false))
                {
                    return _result.Body;
                }
            }

    }
}
