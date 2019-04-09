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
using AvePoint.Migration.Api.Models;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace AvePoint.Migration.Samples
{
    /// <summary>
    /// Rerun an exiting job by passing the Job ID and settingss
    /// </summary>
    class RerunBoxJob : AbstractApplication
    {
        /// <summary>
        /// <see cref="GetBoxJob"/>
        /// <see cref="FindBoxJobByPlan"/>
        /// </summary>
        private readonly string jobId = "<job id>";

        static void Main(string[] args)
        {
            new RerunBoxJob().RunAsync().Wait();
        }

        /// <returns>
        /// <see cref="ServiceResponseString"/>
        /// </returns>
        protected override async Task<string> RunAsync(HttpClient client)
        {
            if (string.IsNullOrEmpty(jobId))
            {
                throw new ArgumentNullException(nameof(jobId));
            }

            var model = new BoxJobExecutionModel
            {
                MigrationType = "Incremental",
                StartTime = DateTime.Now.AddMinutes(2),
            };

            var requestContent = JsonConvert.SerializeObject(model);

            var content = new StringContent(requestContent, Encoding.UTF8, "application/json");

            var response = await client.PostAsync($"/api/box/jobs/{jobId}", content);

            return await response.Content.ReadAsStringAsync();
        }
    }
}
