/********************************************************************
 *
 *  PROPRIETARY and CONFIDENTIAL
 *
 *  This file is licensed from, and is a trade secret of:
 *
 *                   AvePoint, Inc.
 *                   Harborside Financial Center
 *                   9th Fl.   Plaza Ten
 *                   Jersey City, NJ 07311
 *                   United States of America
 *                   Telephone: +1-800-661-6588
 *                   WWW: www.avepoint.com
 *
 *  Refer to your License Agreement for restrictions on use,
 *  duplication, or disclosure.
 *
 *  RESTRICTED RIGHTS LEGEND
 *
 *  Use, duplication, or disclosure by the Government is
 *  subject to restrictions as set forth in subdivision
 *  (c)(1)(ii) of the Rights in Technical Data and Computer
 *  Software clause at DFARS 252.227-7013 (Oct. 1988) and
 *  FAR 52.227-19 (C) (June 1987).
 *
 *  Copyright © 2017-2019 AvePoint® Inc. All Rights Reserved. 
 *
 *  Unpublished - All rights reserved under the copyright laws of the United States.
 *  $Revision:  $
 *  $Author:  $        
 *  $Date:  $
 */
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using Newtonsoft.Json.Serialization;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace AvePoint.Migration.Samples
{
    abstract class AbstractApplication
    {
        protected string BaseUri { get { return ConfigurationManager.AppSettings.Get("BaseUri"); } }

        protected string ApiKey { get { return ConfigurationManager.AppSettings.Get("ApiKey"); } }

        internal AbstractApplication()
        {
            ServicePointManager.ServerCertificateValidationCallback = (sender, certificate, chain, sslPolicyErrors) => true;
            JsonConvert.DefaultSettings = () => new JsonSerializerSettings
            {
                DateFormatHandling = DateFormatHandling.IsoDateFormat,
                DateTimeZoneHandling = DateTimeZoneHandling.Utc,
                NullValueHandling = NullValueHandling.Ignore,
                ContractResolver = new CamelCasePropertyNamesContractResolver(),
            };
        }

        protected async Task RunAsync()
        {
            try
            {
                using (var client = new HttpClient { BaseAddress = new Uri(BaseUri) })
                {
                    client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("api_key", ApiKey);
                    var responseContent = await RunAsync(client);
                    Console.WriteLine(JToken.Parse(responseContent).ToString(Formatting.Indented));
                }
            }
            catch (Exception e)
            {
                Console.WriteLine("The application terminated with an error.");
                Console.WriteLine(e.ToString());
            }
            finally
            {
                Console.ReadKey();
            }
        }

        protected abstract Task<string> RunAsync(HttpClient client);
    }
}
