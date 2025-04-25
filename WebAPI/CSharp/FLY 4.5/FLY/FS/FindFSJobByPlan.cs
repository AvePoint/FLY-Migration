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
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace AvePoint.Migration.Samples
{
    /// <summary>
    /// Return a list of jobs of the plan
    /// </summary>
    class FindFSJobByPlan : AbstractApplication
    {
        /// <summary>
        /// <see cref="GetFSPlan"/>
        /// </summary>
        private readonly string planId = "<plan id>";

        static void Main(string[] args)
        {
            new FindFSJobByPlan().RunAsync().Wait();
        }

        /// <returns>
        /// <see cref="AvePoint.Migration.Api.Models.ServiceResponsePageResultViewModelListJobSummaryModel"/>
        /// </returns>
        protected override async Task<string> RunAsync(HttpClient client)
        {
            if (string.IsNullOrEmpty(planId))
            {
                throw new ArgumentNullException(nameof(planId));
            }

            //var response = await client.GetAsync($"/api/filesystem/plans/{planId}/jobs);
            var response = await client.GetAsync($"/api/filesystem/plans/findjobs?id={planId}");

            return await response.Content.ReadAsStringAsync();
        }
    }
}
