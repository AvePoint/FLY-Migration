//********************************************************************
//*
//*  PROPRIETARY and CONFIDENTIAL
//*
//*  This file is licensed from, and is a trade secret of:
//*
//*                   AvePoint, Inc.
//*                   525 Washington Blvd, Suite 1400
//*                   Jersey City, NJ 07310
//*                   United States of America
//*                   Telephone: +1-201-793-1111
//*                   WWW: www.avepoint.com
//*
//*  Refer to your License Agreement for restrictions on use,
//*  duplication, or disclosure.
//*
//*  RESTRICTED RIGHTS LEGEND
//*
//*  Use, duplication, or disclosure by the Government is
//*  subject to restrictions as set forth in subdivision
//*  (c)(1)(ii) of the Rights in Technical Data and Computer
//*  Software clause at DFARS 252.227-7013 (Oct. 1988) and
//*  FAR 52.227-19 (C) (June 1987).
//*
//*  Copyright © 2017-2023 AvePoint® Inc. All Rights Reserved.
//*
//*  Unpublished - All rights reserved under the copyright laws of the United States.
//*
//********************************************************************

// Licensed under the MIT license.

// PSSwaggerUtility Module
namespace Microsoft.PowerShell.Commands.PSSwagger
{
	using Microsoft.Rest;
	using System;
	using System.Collections.Generic;
	using System.Linq;
	using System.Management.Automation;
	using System.Management.Automation.Runspaces;
	using System.Net.Http;
    using System.Net.Http.Headers;
    using System.Runtime.InteropServices;
    using System.Security;
    using System.Threading;
	using System.Threading.Tasks;

    /// <summary>
    /// Creates a PSSwaggerJob with the specified script block.
    /// </summary>
    [Cmdlet(VerbsLifecycle.Start, "PSSwaggerJob")]
    [OutputType(typeof(Job2))]
    public sealed class StartPSSwaggerJobCommand : PSCmdlet
    {
        #region Parameters

        // ScriptBlock to be executed in the PSSwaggerJob
        [Parameter(Position = 0, Mandatory = true)]
        [ValidateNotNullOrEmpty]
        public ScriptBlock ScriptBlock { get; set; }

        // Name of the PSSwaggerJob.
        [Parameter(Position = 1, Mandatory = false)]
        [ValidateNotNullOrEmpty]
        public string Name { get; set; }

        // Parameters to be passed into the specified script block.
        [Parameter(Position = 2, Mandatory = false)]
        [ValidateNotNullOrEmpty]
        public Dictionary<string, object> Parameters  { get; set; }

        // List of module paths to be imported for executing the specified scriptblock.
        [Parameter(Position = 3, Mandatory = false)]
        [ValidateNotNullOrEmpty]
        public string[] RequiredModules { get; set; }

        #endregion

        #region Overrides

        protected override void ProcessRecord()
        {
            // Create PSSwaggerJob parameters (ScriptBlock and Parameters).
            var psSwaggerJobParameters = new Dictionary<string, object>
            {
                {PSSwaggerJobSourceAdapter.ScriptBlockProperty, ScriptBlock}
            };

            if (null != Parameters)
            {
                psSwaggerJobParameters.Add(PSSwaggerJobSourceAdapter.ParametersProperty, Parameters);
            }

            if (null != RequiredModules)
            {
                psSwaggerJobParameters.Add(PSSwaggerJobSourceAdapter.RequiredModulesProperty, RequiredModules);
            }

            if (!string.IsNullOrWhiteSpace(Name))
            {
                psSwaggerJobParameters.Add(PSSwaggerJobSourceAdapter.NameProperty, Name);
            }

            // Create job specification.
            var psSwaggerJobSpecification = new JobInvocationInfo(
                new JobDefinition(typeof(PSSwaggerJobSourceAdapter), ScriptBlock.ToString(), Name),
                psSwaggerJobParameters);

            if (!string.IsNullOrWhiteSpace(Name))
            {
                psSwaggerJobSpecification.Name = Name;
            }

            // Create PSSwagger job from job source adapter and start it.
            var psSwaggerJob = PSSwaggerJobSourceAdapter.GetInstance().NewJob(psSwaggerJobSpecification);
            psSwaggerJob.StartJob();

            WriteObject(psSwaggerJob);
        }

        #endregion
    }

    /// <summary>
    /// PSSwaggerJob class derived from Job2.
    /// </summary>
    public sealed class PSSwaggerJob : Job2
    {
        #region Private members

        private const string PSSwaggerJobTypeName = "PSSwaggerJob";
        private Task _task;
        private System.Management.Automation.PowerShell _powerShell;
        private PSDataCollection<object> _input;
        private PSDataCollection<PSObject> _output;
        private Runspace _runSpace;
        private bool _runningInit;

        private static int _jobIdCounter = 0;
        #endregion

        #region Constructor

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="scriptBlock">ScriptBlock</param>
        /// <param name="parameters">Parameters to the scriptblock</param>
        /// <param name="requiredModules">list of modules to be imported prior to executing the scriptblock.</param>
        /// <param name="name">Job name</param>
        public PSSwaggerJob(
            ScriptBlock scriptBlock,
            Dictionary<string, object> parameters,
            string[] requiredModules,
            string name)
        {
            if (null == scriptBlock)
            {
                throw new ArgumentException("scriptBlock");
            }

            ScriptBlock = scriptBlock;
            Parameters = parameters;
            RequiredModules = requiredModules;

            Name = string.IsNullOrWhiteSpace(name) ? AutoGenerateJobName() : name;

            PSJobTypeName = PSSwaggerJobTypeName;

            _powerShell = System.Management.Automation.PowerShell.Create();
            _input = new PSDataCollection<object>();
            _output = new PSDataCollection<PSObject>();
            _runSpace = RunspaceFactory.CreateRunspace();

            _task = new Task(ExecuteScriptBlock);

            // Job state changed callback.
            StateChanged += HandleJobStateChanged;

            _output.DataAdded += HandleOutputDataAdded;

            _powerShell.Streams.Debug.DataAdded += HandleDebugAdded;
            _powerShell.Streams.Error.DataAdded += HandleErrorAdded;
            _powerShell.Streams.Progress.DataAdded += HandleProgressAdded;
            _powerShell.Streams.Verbose.DataAdded += HandleVerboseAdded;
            _powerShell.Streams.Warning.DataAdded += HandleWarningAdded;

            // Add the InvocationStateChanged event handler to set the Job state accordingly.
            _powerShell.InvocationStateChanged += HandleInvocationStateChanged;
        }

        #endregion

        #region Public properties

        public ScriptBlock ScriptBlock { get; private set; }
        public Dictionary<string, object> Parameters { get; private set; }
        public string[] RequiredModules { get; private set; }

        #endregion

        #region Public methods

        public override void StartJob()
        {
            if (JobStateInfo.State != JobState.NotStarted)
            {
                throw new InvalidOperationException("Cannot start job.");
            }

            _task.Start();
        }

        public override void StartJobAsync()
        {
            StartJob();
            OnStartJobCompleted(new System.ComponentModel.AsyncCompletedEventArgs(null, false, null));
        }

        public override void StopJob()
        {
            if ((null != _powerShell) && 
                ((_task.Status == TaskStatus.Running) ||
                (_task.Status == TaskStatus.WaitingToRun)))
            {
                _powerShell.Stop();
            }

            if (!IsFinishedState(JobStateInfo.State))
            {
                SetJobState(JobState.Stopped);
            }
        }

        public override void StopJobAsync()
        {
            StopJob();
            OnStopJobCompleted(new System.ComponentModel.AsyncCompletedEventArgs(null, false, null));
        }

        public override void StopJob(bool force, string reason)
        {
            StopJob();
        }

        public override void StopJobAsync(bool force, string reason)
        {
            StopJobAsync();
        }

        public override void SuspendJob()
        {
            throw new NotImplementedException();
        }

        public override void SuspendJobAsync()
        {
            SuspendJob();
            OnSuspendJobCompleted(new System.ComponentModel.AsyncCompletedEventArgs(null, false, null));
        }

        public override void SuspendJob(bool force, string reason)
        {
            SuspendJob();
        }

        public override void SuspendJobAsync(bool force, string reason)
        {
            SuspendJobAsync();
        }

        public override void ResumeJob()
        {
            throw new NotImplementedException();
        }

        public override void ResumeJobAsync()
        {
            ResumeJob();
            OnResumeJobCompleted(new System.ComponentModel.AsyncCompletedEventArgs(null, false, null));
        }

        public override void UnblockJob()
        {
            throw new NotImplementedException();
        }

        public override void UnblockJobAsync()
        {
            throw new NotImplementedException();
        }

        public override bool HasMoreData
        {
            get
            {
                return (Output.Count > 0 ||
                        Error.Count > 0);
            }
        }

        public override string Location
        {
            get { return "localhost"; }
        }

        public override string StatusMessage
        {
            get { return string.Empty; }
        }

        #endregion

        #region IDispose

        protected override void Dispose(bool disposing)
        {
            if (!IsFinishedState(JobStateInfo.State))
            {
                SetJobState(JobState.Stopped);
            }

            base.Dispose(disposing);
        }

        #endregion

        #region Private methods
        private new static string AutoGenerateJobName()
        {
            return "PSSwaggerJob" + (++_jobIdCounter);
        }

        private void ExecuteScriptBlock()
        {
            if (IsFinishedState(JobStateInfo.State))
            {
                return;
            }

            _runSpace.Open();
            _powerShell.Runspace = _runSpace;

            // Import the required modules
            if ((null != RequiredModules) && (0 < RequiredModules.Length))
            {
                _runningInit = true;
                _powerShell.AddCommand("Import-Module")
                            .AddParameter("Name", RequiredModules)
                            .AddParameter("Verbose", false)
                            .AddParameter("Debug", false)
                            .AddParameter("WarningAction", "Ignore");

                _powerShell.Invoke();
                _powerShell.Commands.Clear();
            }

            if (!_powerShell.HadErrors)
            {
                _powerShell.AddScript(ScriptBlock.ToString());
                if (null != Parameters)
                {
                    _powerShell.AddParameters(Parameters);
                }

                _powerShell.Invoke<PSObject>(_input, _output);
            }

            if (!IsFinishedState(JobStateInfo.State))
            {
                SetJobState(Error.Count > 0 ? JobState.Failed : JobState.Completed);
            }
        }
        private void HandleInvocationStateChanged(object sender, PSInvocationStateChangedEventArgs e)
        {
            switch (e.InvocationStateInfo.State)
            {
                case PSInvocationState.Running:
                    SetJobState(JobState.Running);
                    break;

                case PSInvocationState.Completed:
                    if (_runningInit)
                    {
                        _runningInit = false;
                    }
                    else
                    {
                        SetJobState(JobState.Completed);
                    }
                    break;

                case PSInvocationState.Failed:
                    SetJobState(JobState.Failed, e.InvocationStateInfo.Reason);
                    break;

                case PSInvocationState.Stopped:
                    SetJobState(JobState.Stopped);
                    break;

                case PSInvocationState.NotStarted:
                    break;

                case PSInvocationState.Stopping:
                    break;

                case PSInvocationState.Disconnected:
                    break;

                default:
                    throw new ArgumentOutOfRangeException();
            }
        }

        private void HandleOutputDataAdded(object sender, DataAddedEventArgs e)
        {
            var record = ((PSDataCollection<PSObject>)sender)[e.Index];
            Output.Add(record);
        }

        private void HandleJobStateChanged(object sender, JobStateEventArgs e)
        {
            if (IsFinishedState(e.JobStateInfo.State))
            {
                Cleanup();
            }
        }

        private void HandleErrorAdded(object sender, DataAddedEventArgs e)
        {
            var record = ((PSDataCollection<ErrorRecord>)sender)[e.Index]; 
            Error.Add(record);
        }

        private void HandleDebugAdded(object sender, DataAddedEventArgs e)
        {
            var record = ((PSDataCollection<DebugRecord>)sender)[e.Index];
            Debug.Add(record);
        }

        private void HandleProgressAdded(object sender, DataAddedEventArgs e)
        {
            var record = ((PSDataCollection<ProgressRecord>)sender)[e.Index];
            Progress.Add(record);
        }

        private void HandleVerboseAdded(object sender, DataAddedEventArgs e)
        {
            var record = ((PSDataCollection<VerboseRecord>)sender)[e.Index];
            Verbose.Add(record);
        }

        private void HandleWarningAdded(object sender, DataAddedEventArgs e)
        {
            var record = ((PSDataCollection<WarningRecord>)sender)[e.Index];
            Warning.Add(record);
        }

        private void Cleanup()
        {
            StateChanged -= HandleJobStateChanged;

            if (null != _input)
            {
                _input.Complete();
                _input.Dispose();
                _input = null;
            }

            if (null != _output)
            {
                _output.DataAdded -= HandleOutputDataAdded;
                _output.Complete();
                _output.Dispose();
                _output = null;
            }

            if (_powerShell != null)
            {
                _powerShell.Streams.Debug.DataAdded -= HandleDebugAdded;
                _powerShell.Streams.Error.DataAdded -= HandleErrorAdded;
                _powerShell.Streams.Progress.DataAdded -= HandleProgressAdded;
                _powerShell.Streams.Verbose.DataAdded -= HandleVerboseAdded;
                _powerShell.Streams.Warning.DataAdded -= HandleWarningAdded;

                _powerShell.InvocationStateChanged -= HandleInvocationStateChanged;

                _powerShell.Dispose();
                _powerShell = null;
            }

            if (_runSpace != null)
            {
                _runSpace.Dispose();
                _runSpace = null;
            }

            // A task may only be disposed if it is in a completion state (RanToCompletion, Faulted or Canceled).
            if (_task != null && (_task.IsCanceled || _task.IsCompleted || _task.IsFaulted))
            {
                _task.Dispose();
                _task = null;
            }
        }

        private static bool IsFinishedState(JobState state)
        {
            return (state == JobState.Completed || state == JobState.Stopped || state == JobState.Failed);
        }

        #endregion
    }

    /// <summary>
    /// JobSourceAdapter for PSSwagger jobs.
    /// Creates new PSSwagger jobs.
    /// Maintains repository for PSSwagger Jobs.
    /// </summary>
    public sealed class PSSwaggerJobSourceAdapter : JobSourceAdapter
    {
        #region Private members

        private const string AdapterTypeName = "PSSwaggerJobSourceAdapter";

        private static List<Job2> JobRepository = new List<Job2>();

        private static readonly PSSwaggerJobSourceAdapter Instance = new PSSwaggerJobSourceAdapter();

        #endregion

        #region Public strings

        // PSSwagger job properties.
        public const string ScriptBlockProperty = "ScriptBlock";
        public const string ParametersProperty = "Parameters";
        public const string RequiredModulesProperty = "RequiredModules";
        public const string NameProperty = "Name";

        #endregion

        #region Constructor

        public PSSwaggerJobSourceAdapter()
        {
            Name = AdapterTypeName;
        }

        #endregion

        #region Public methods

        /// <summary>
        /// Gets the WorkflowJobSourceAdapter instance.
        /// </summary>
        public static PSSwaggerJobSourceAdapter GetInstance()
        {
            return Instance;
        }

        public override Job2 NewJob(JobInvocationInfo specification)
        {
            if (specification == null)
            {
                throw new NullReferenceException("specification");
            }

            if (specification.Parameters.Count != 1)
            {
                throw new ArgumentException("JobInvocationInfo specification parameters not specified.");
            }

            // Retrieve parameters information from specification
            ScriptBlock scriptBlock = null;
            Dictionary<string, object> parameters = null;
            string[] requiredModules = null;
            string name = null;
            var commandParameterCollection = specification.Parameters[0];

            foreach (var item in commandParameterCollection)
            {
                if (item.Name.Equals(ScriptBlockProperty, StringComparison.OrdinalIgnoreCase))
                {
                    scriptBlock = item.Value as ScriptBlock;
                }
                else if (item.Name.Equals(ParametersProperty, StringComparison.OrdinalIgnoreCase))
                {
                    parameters = item.Value as Dictionary<string, object>;
                }
                else if (item.Name.Equals(RequiredModulesProperty, StringComparison.OrdinalIgnoreCase))
                {
                    requiredModules = item.Value as string[];
                }
                else if (item.Name.Equals(NameProperty, StringComparison.OrdinalIgnoreCase))
                {
                    name = item.Value as string;
                }
            }

            // Create PSSwaggerJob
            var rtnJob = new PSSwaggerJob(scriptBlock, parameters, requiredModules, name);
            lock (JobRepository)
            {
                JobRepository.Add(rtnJob);
            }
            return rtnJob;
        }

        public override void RemoveJob(Job2 job)
        {
            lock (JobRepository)
            {
                if (JobRepository.Contains(job))
                {
                    JobRepository.Remove(job);
                }
            }

            job.Dispose();
        }

        public override IList<Job2> GetJobs()
        {
            lock (JobRepository)
            {
                return JobRepository.ToArray<Job2>();
            }
        }

        public override Job2 GetJobByInstanceId(Guid instanceId, bool recurse)
        {
            lock (JobRepository)
            {
                foreach (var job in JobRepository)
                {
                    if (job.InstanceId == instanceId)
                    {
                        return job;
                    }
                }
            }

            return null;
        }

        public override Job2 GetJobBySessionId(int id, bool recurse)
        {
            lock (JobRepository)
            {
                foreach (var job in JobRepository)
                {
                    if (job.Id == id)
                    {
                        return job;
                    }
                }
            }

            return null;
        }

        public override IList<Job2> GetJobsByName(string name, bool recurse)
        {
            var rtnJobs = new List<Job2>();
            var namePattern = new WildcardPattern(name, WildcardOptions.IgnoreCase);
            lock (JobRepository)
            {
                rtnJobs.AddRange(JobRepository.Where(job => namePattern.IsMatch(job.Name)));
            }

            return rtnJobs;
        }

        public override IList<Job2> GetJobsByState(JobState state, bool recurse)
        {
            var rtnJobs = new List<Job2>();
            lock (JobRepository)
            {
                rtnJobs.AddRange(JobRepository.Where(job => job.JobStateInfo.State == state));
            }

            return rtnJobs;
        }

        public override IList<Job2> GetJobsByCommand(string command, bool recurse)
        {
            throw new NotImplementedException();
        }

        public override IList<Job2> GetJobsByFilter(Dictionary<string, object> filter, bool recurse)
        {
            throw new NotImplementedException();
        }

        #endregion
    }
	
	/// <summary>
    /// Base class to handle Microsoft.Rest.ServiceClientTracing output from PowerShell.
    /// </summary>
    public class PSSwaggerClientTracingBase : IServiceClientTracingInterceptor
    {
		public virtual void Configuration(string source, string name, string value)
        {
            WriteToTraceStream(String.Format("({0}) Configuration setting '{1}' set to '{2}'", source, name, value));
        }

        public virtual void EnterMethod(string invocationId, object instance, string method, IDictionary<string, object> parameters)
        {
			string parametersStr = String.Empty;
			foreach (KeyValuePair<string, object> entry in parameters)
			{
				parametersStr += String.Format("({0}={1})", entry.Key, entry.Value);
			}
			
            WriteToTraceStream(String.Format("({0}) Entered method '{1}' with parameters: {2}", invocationId, method, parametersStr));
        }

        public virtual void ExitMethod(string invocationId, object returnValue)
        {
            WriteToTraceStream(String.Format("({0}) Exited method with value: {1}", invocationId, returnValue));
        }

        public virtual void Information(string message)
        {
            WriteToTraceStream(message);
        }

        public virtual void ReceiveResponse(string invocationId, HttpResponseMessage response)
        {
            WriteToTraceStream(String.Format("({0}) HTTP response: {1}", invocationId, response.ToString()));
        }

        public virtual void SendRequest(string invocationId, HttpRequestMessage request)
        {
            WriteToTraceStream(String.Format("({0}) HTTP request: {1}", invocationId, request.ToString()));
        }

        public virtual void TraceError(string invocationId, Exception exception)
        {
            WriteToTraceStream(String.Format("({0}) Exception: {1}", invocationId, exception.Message));
        }
		
		protected virtual void WriteToTraceStream(string message) 
		{
		}
	}

    /// <summary>
    /// Basic support for Basic Authentication protocol using SecureString password. Note: Use PSBasicAuthenticationEx where possible.
    /// </summary>
    public class PSBasicAuthentication : ServiceClientCredentials
    {
        public string UserName { get; set; }
        public SecureString Password { get; set; }
        public PSBasicAuthentication(string userName, SecureString password)
        {
            this.UserName = userName;
            this.Password = password;
        }

        public override async Task ProcessHttpRequestAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            IntPtr valuePtr = IntPtr.Zero;
            string pwd = String.Empty;
            try
            {
                System.Reflection.MethodInfo[] mi = typeof(SecureString).GetMethods(System.Reflection.BindingFlags.Instance | System.Reflection.BindingFlags.NonPublic);
                foreach (var method in mi)
                {
                    if (method.Name.Equals("MarshalToString", StringComparison.OrdinalIgnoreCase))
                    {
                        // Global + Unicode
                        valuePtr = (IntPtr)method.Invoke(this.Password, new object[] { true, true });
                    }
                }

                if (valuePtr == IntPtr.Zero)
                {
                    valuePtr = Marshal.SecureStringToGlobalAllocUnicode(this.Password);
                }

                pwd = Marshal.PtrToStringUni(valuePtr);
            }
            finally
            {
                Marshal.ZeroFreeGlobalAllocUnicode(valuePtr);
            }

            if (String.IsNullOrEmpty(pwd))
            {
                throw new Exception("Unable to transform SecureString into String.");
            }

            BasicAuthenticationCredentials basicAuth = new BasicAuthenticationCredentials();
            basicAuth.UserName = this.UserName;
            basicAuth.Password = pwd;
            await basicAuth.ProcessHttpRequestAsync(request, cancellationToken);
        }
    }

    /// <summary>
    /// Basic support for API Key Authentication protocol. Always adds the Authorization header with the APIKEY prefix.
    /// </summary>
    public class PSApiKeyAuthentication : ServiceClientCredentials
    {
        public string ApiKey { get; set; }
        public string Location { get; set; }
        public string Name { get; set; }
        public PSApiKeyAuthentication(string apiKey, string location, string name)
        {
            this.ApiKey = apiKey;
            this.Location = location;
            this.Name = name;
        }

        public override async Task ProcessHttpRequestAsync(HttpRequestMessage request, CancellationToken cancellationToken)
        {
            // First, always add the authorization header
            request.Headers.Authorization = new AuthenticationHeaderValue("APIKEY", this.ApiKey);

            // Then, check if user requested the key in another header or a query
            if (!String.IsNullOrEmpty(this.Location))
            {
                if (String.IsNullOrEmpty(this.Name))
                {
                    throw new Exception("When Location is specified, the Name property must also be specified.");
                }

                if (this.Location.Equals("query", StringComparison.OrdinalIgnoreCase))
                {
                    // Note this method will not work in PowerShell Core Alpha 6.0.0.12+
                    // This means that query-based API keys are not supported
                    // But query-based API keys are not recommended anyways
                    string location = request.RequestUri.AbsoluteUri + (request.RequestUri.AbsoluteUri.Contains("?") ? "&" : "?") + this.Name + "=" + this.ApiKey;
                    request.RequestUri = new Uri(location);
                }
                else if (this.Location.Equals("header"))
                {
                    request.Headers.Add(this.Name, this.ApiKey);
                }
                else
                {
                    throw new Exception("Unsupported API key location: " + this.Location);
                }
            }
        }
    }

    /// <summary>
    /// Dummy service client credentials for services with no authentication.
    /// </summary>
    public class PSDummyAuthentication : ServiceClientCredentials
    {
    }
}


# SIG # Begin signature block
# MIIofgYJKoZIhvcNAQcCoIIobzCCKGsCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUZUOk7IaucF9Mful7Wb94yoQ2
# hQ2ggiKkMIIFLTCCBBWgAwIBAgIQAybM8QJy2GqRSHGucYhV3TANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTIwMTEwMzAwMDAwMFoXDTIzMTEw
# NzIzNTk1OVowajELMAkGA1UEBhMCVVMxEzARBgNVBAgTCk5ldyBKZXJzZXkxFDAS
# BgNVBAcTC0plcnNleSBDaXR5MRcwFQYDVQQKEw5BdmVQb2ludCwgSW5jLjEXMBUG
# A1UEAxMOQXZlUG9pbnQsIEluYy4wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
# AoIBAQDbkeodMZTyIxQr/Vt7VlDpjm9D9mxRJ7V3g1f82yldPyAP1PlBczHklw9g
# F9+kSQXS96v0fnQcQWte5Fx29TMKnomAgKvMkr/LJc0W0dZHyIl61DCUhQZu6J2b
# T6TPQKIuV7eQ1ZYs+S+waw8SN+dE3WX8qd131OlL7q2yHLT0ErYZQObgv39L2Z6+
# u3dE8MFyAUmWDQnerY1+scb78kNwVS4o2xxi6AKeLFQ+ZWFh6wM2lcogPwCTh0mI
# 1cU++AHO4gVgH9yPc75oZa0GzKzH9dqmf8OW+tnQk9QPAhWP6ELtlrm3AgsGfGP+
# zcaIB1JoAbARX9sek3vkTx3t5XAhAgMBAAGjggHFMIIBwTAfBgNVHSMEGDAWgBRa
# xLl7KgqjpepxA8Bg+S32ZXUOWDAdBgNVHQ4EFgQU7JjCyzkrLNPHmZmqTsPNmUEs
# CuowDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHcGA1UdHwRw
# MG4wNaAzoDGGL2h0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9zaGEyLWFzc3VyZWQt
# Y3MtZzEuY3JsMDWgM6Axhi9odHRwOi8vY3JsNC5kaWdpY2VydC5jb20vc2hhMi1h
# c3N1cmVkLWNzLWcxLmNybDBMBgNVHSAERTBDMDcGCWCGSAGG/WwDATAqMCgGCCsG
# AQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BTMAgGBmeBDAEEATCB
# hAYIKwYBBQUHAQEEeDB2MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2Vy
# dC5jb20wTgYIKwYBBQUHMAKGQmh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9E
# aWdpQ2VydFNIQTJBc3N1cmVkSURDb2RlU2lnbmluZ0NBLmNydDAMBgNVHRMBAf8E
# AjAAMA0GCSqGSIb3DQEBCwUAA4IBAQB4z6WmQmBTtbLCOF4iUzcK2DjvOEkv1ukR
# LPESBxMCET6tY6659AHKBgXP/sKMIDIVnHs8x0ib9AklSbZZcybtcI/E72iLaL76
# mtMp2pNbK3ekVFIE5CsD5IKfTkilDuPC2kyxizsWGE4r6eXEYzGPGO4LBIEDdRl6
# Jmdf3JMRUAd6bjaueA8NptF83EVAh/+TtPpyQdRLBS+63625z03hUGXKfv3m1VjI
# FnzvZ8V69v+0hvuCXjR2Y1Ms8gn1hWRNrPaGE/xahPNiBsae//15Ogmru112wRAk
# BFrj71MWTkGjYKvQZLPKUICgj/O/VxOUyEnykfJmfk4AhyRpdkMQMIIFMDCCBBig
# AwIBAgIQBAkYG1/Vu2Z1U0O1b5VQCDANBgkqhkiG9w0BAQsFADBlMQswCQYDVQQG
# EwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNl
# cnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcN
# MTMxMDIyMTIwMDAwWhcNMjgxMDIyMTIwMDAwWjByMQswCQYDVQQGEwJVUzEVMBMG
# A1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEw
# LwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgQ29kZSBTaWduaW5nIENB
# MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA+NOzHH8OEa9ndwfTCzFJ
# Gc/Q+0WZsTrbRPV/5aid2zLXcep2nQUut4/6kkPApfmJ1DcZ17aq8JyGpdglrA55
# KDp+6dFn08b7KSfH03sjlOSRI5aQd4L5oYQjZhJUM1B0sSgmuyRpwsJS8hRniolF
# 1C2ho+mILCCVrhxKhwjfDPXiTWAYvqrEsq5wMWYzcT6scKKrzn/pfMuSoeU7MRzP
# 6vIK5Fe7SrXpdOYr/mzLfnQ5Ng2Q7+S1TqSp6moKq4TzrGdOtcT3jNEgJSPrCGQ+
# UpbB8g8S9MWOD8Gi6CxR93O8vYWxYoNzQYIH5DiLanMg0A9kczyen6Yzqf0Z3yWT
# 0QIDAQABo4IBzTCCAckwEgYDVR0TAQH/BAgwBgEB/wIBADAOBgNVHQ8BAf8EBAMC
# AYYwEwYDVR0lBAwwCgYIKwYBBQUHAwMweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUF
# BzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6
# Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5j
# cnQwgYEGA1UdHwR6MHgwOqA4oDaGNGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9E
# aWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRp
# Z2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwTwYDVR0gBEgw
# RjA4BgpghkgBhv1sAAIEMCowKAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2lj
# ZXJ0LmNvbS9DUFMwCgYIYIZIAYb9bAMwHQYDVR0OBBYEFFrEuXsqCqOl6nEDwGD5
# LfZldQ5YMB8GA1UdIwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA0GCSqGSIb3
# DQEBCwUAA4IBAQA+7A1aJLPzItEVyCx8JSl2qB1dHC06GsTvMGHXfgtg/cM9D8Sv
# i/3vKt8gVTew4fbRknUPUbRupY5a4l4kgU4QpO4/cY5jDhNLrddfRHnzNhQGivec
# Rk5c/5CxGwcOkRX7uq+1UcKNJK4kxscnKqEpKBo6cSgCPC6Ro8AlEeKcFEehemho
# r5unXCBc2XGxDI+7qPjFEmifz0DLQESlE/DmZAwlCEIysjaKJAL+L3J+HNdJRZbo
# WR3p+nRka7LrZkPas7CM1ekN3fYBIM6ZMWM9CBoYs4GbT8aTEAb8B4H6i9r5gkn3
# Ym6hU/oSlBiFLpKR6mhsRDKyZqHnGKSaZFHvMIIFNDCCAxygAwIBAgIKYRyyigAA
# AAAAJjANBgkqhkiG9w0BAQUFADB/MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSkwJwYDVQQDEyBNaWNyb3NvZnQgQ29kZSBWZXJpZmljYXRpb24g
# Um9vdDAeFw0xMTA0MTUxOTQxMzdaFw0yMTA0MTUxOTUxMzdaMGUxCzAJBgNVBAYT
# AlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2Vy
# dC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTCCASIw
# DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAK0OFc7kQ4BcsYfzt2D5cRKlrtwm
# lIiq9M71IDkoWGAM+IDaqRWVMmE8tbEohIqK3J8KDIMXeo+QrIrneVNcMYQq9g+Y
# MjZ2zN7dPKii72r7IfJSYd+fINcf4rHZ/hhk0hJbX/lYGDW8R82hNvlrf9SwOD7B
# G8OMM9nYLxj+KA+zp4PWw25EwGE1lhb+WZyLdm3X8aJLDSv/C3LanmDQjpA1xnhV
# hyChz+VtCshJfDGYM2wi6YfQMlqiuhOCEe05F52ZOnKh5vqk2dUXMXWuhX0irj8B
# Rob2KHnIsdrkVxfEfhwOsLSSplazvbKX7aqn8LfFqD+VFtD/oZbrCF8Yd08CAwEA
# AaOByzCByDARBgNVHSAECjAIMAYGBFUdIAAwCwYDVR0PBAQDAgGGMA8GA1UdEwEB
# /wQFMAMBAf8wHQYDVR0OBBYEFEXroq/0ksuCMS1Ri6enIZ3zbcgPMB8GA1UdIwQY
# MBaAFGL7CiFbf0NuEdoJVFBr9dKWcfGeMFUGA1UdHwROMEwwSqBIoEaGRGh0dHA6
# Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY3Jvc29mdENv
# ZGVWZXJpZlJvb3QuY3JsMA0GCSqGSIb3DQEBBQUAA4ICAQBc9bItAs7tAbU1EtgT
# 96pAFMehXKCKVe1+VepqxFcXb9BHIkI2WO/FrGHF9ixSzmrmyA2F2rM0Qg6kAiUY
# JnK5Kk6lfksW8qDkDESc4k2a9HTw+SemaZAxwkRlQ0jHSGnQ/IQJ8oYUCsIploV/
# EeuHExdu0+xr/x1XirF7HqWgfOmiemjl+saxYdZyY/o3kWODVZn4HWFPDG+j97yx
# FSrMjYXjFBfvfklEP7AiwPCsvi/b4QyGsPRYXFoQqUvN80SKRlIIPgpiEOlFlQS3
# i41LB09QDbe75/uMonh4xsU7dmOyz+UhhFpm/OBMeYNOz6jucAWGWHzCnNc8o608
# fnZiXIfQ7XzVxVsUIfS+daJ10unhWtAgMHhBYk1rXm4bFxAkSthYh3XQFddiu/0Y
# VmWEJWGXf6rUnfTzXW2gMcLhngKsPpDDMn7oMpA0FtCLFM+VrM7ljFSiZbi/7Rhq
# Vwc+0+eaSi8IGgQcSYcaiuYbCKNl2BwxxQ2curNo3fRQdhYGdf7EA+fRPt/chi4Q
# An5mEpZTTnrzNlh5sSBC2JY/Nb4/jvKZl0P15AzhPGhyjI1J11pStXP7ejWUOmGw
# hILASIXBlzLTm3JfoNI0j37wRnzyjHKUxwew17WyMLgZZfCcgyewoKvQonJ+BQ+z
# rt25W5tCvMMmY0VrhvEdRkPtyDCCBY0wggR1oAMCAQICEA6bGI750C3n79tQ4ghA
# GFowDQYJKoZIhvcNAQEMBQAwZTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lD
# ZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIGA1UEAxMbRGln
# aUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTIyMDgwMTAwMDAwMFoXDTMxMTEw
# OTIzNTk1OVowYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZ
# MBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgVHJ1
# c3RlZCBSb290IEc0MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAv+aQ
# c2jeu+RdSjwwIjBpM+zCpyUuySE98orYWcLhKac9WKt2ms2uexuEDcQwH/MbpDgW
# 61bGl20dq7J58soR0uRf1gU8Ug9SH8aeFaV+vp+pVxZZVXKvaJNwwrK6dZlqczKU
# 0RBEEC7fgvMHhOZ0O21x4i0MG+4g1ckgHWMpLc7sXk7Ik/ghYZs06wXGXuxbGrzr
# yc/NrDRAX7F6Zu53yEioZldXn1RYjgwrt0+nMNlW7sp7XeOtyU9e5TXnMcvak17c
# jo+A2raRmECQecN4x7axxLVqGDgDEI3Y1DekLgV9iPWCPhCRcKtVgkEy19sEcypu
# kQF8IUzUvK4bA3VdeGbZOjFEmjNAvwjXWkmkwuapoGfdpCe8oU85tRFYF/ckXEaP
# ZPfBaYh2mHY9WV1CdoeJl2l6SPDgohIbZpp0yt5LHucOY67m1O+SkjqePdwA5EUl
# ibaaRBkrfsCUtNJhbesz2cXfSwQAzH0clcOP9yGyshG3u3/y1YxwLEFgqrFjGESV
# GnZifvaAsPvoZKYz0YkH4b235kOkGLimdwHhD5QMIR2yVCkliWzlDlJRR3S+Jqy2
# QXXeeqxfjT/JvNNBERJb5RBQ6zHFynIWIgnffEx1P2PsIV/EIFFrb7GrhotPwtZF
# X50g/KEexcCPorF+CiaZ9eRpL5gdLfXZqbId5RsCAwEAAaOCATowggE2MA8GA1Ud
# EwEB/wQFMAMBAf8wHQYDVR0OBBYEFOzX44LScV1kTN8uZz/nupiuHA9PMB8GA1Ud
# IwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA4GA1UdDwEB/wQEAwIBhjB5Bggr
# BgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNv
# bTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lD
# ZXJ0QXNzdXJlZElEUm9vdENBLmNydDBFBgNVHR8EPjA8MDqgOKA2hjRodHRwOi8v
# Y3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMBEG
# A1UdIAQKMAgwBgYEVR0gADANBgkqhkiG9w0BAQwFAAOCAQEAcKC/Q1xV5zhfoKN0
# Gz22Ftf3v1cHvZqsoYcs7IVeqRq7IviHGmlUIu2kiHdtvRoU9BNKei8ttzjv9P+A
# ufih9/Jy3iS8UgPITtAq3votVs/59PesMHqai7Je1M/RQ0SbQyHrlnKhSLSZy51P
# pwYDE3cnRNTnf+hZqPC/Lwum6fI0POz3A8eHqNJMQBk1RmppVLC4oVaO7KTVPeix
# 3P0c2PR3WlxUjG/voVA9/HYJaISfb8rbII01YBwCA8sgsKxYoA5AY8WYIsGyWfVV
# a88nq2x2zm8jLfR+cWojayL/ErhULSd+2DrZ8LaHlv1b0VysGMNNn3O3AamfV6pe
# KOK5lDCCBq4wggSWoAMCAQICEAc2N7ckVHzYR6z9KGYqXlswDQYJKoZIhvcNAQEL
# BQAwYjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UE
# CxMQd3d3LmRpZ2ljZXJ0LmNvbTEhMB8GA1UEAxMYRGlnaUNlcnQgVHJ1c3RlZCBS
# b290IEc0MB4XDTIyMDMyMzAwMDAwMFoXDTM3MDMyMjIzNTk1OVowYzELMAkGA1UE
# BhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMuMTswOQYDVQQDEzJEaWdpQ2Vy
# dCBUcnVzdGVkIEc0IFJTQTQwOTYgU0hBMjU2IFRpbWVTdGFtcGluZyBDQTCCAiIw
# DQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAMaGNQZJs8E9cklRVcclA8TykTep
# l1Gh1tKD0Z5Mom2gsMyD+Vr2EaFEFUJfpIjzaPp985yJC3+dH54PMx9QEwsmc5Zt
# +FeoAn39Q7SE2hHxc7Gz7iuAhIoiGN/r2j3EF3+rGSs+QtxnjupRPfDWVtTnKC3r
# 07G1decfBmWNlCnT2exp39mQh0YAe9tEQYncfGpXevA3eZ9drMvohGS0UvJ2R/dh
# gxndX7RUCyFobjchu0CsX7LeSn3O9TkSZ+8OpWNs5KbFHc02DVzV5huowWR0QKfA
# csW6Th+xtVhNef7Xj3OTrCw54qVI1vCwMROpVymWJy71h6aPTnYVVSZwmCZ/oBpH
# IEPjQ2OAe3VuJyWQmDo4EbP29p7mO1vsgd4iFNmCKseSv6De4z6ic/rnH1pslPJS
# lRErWHRAKKtzQ87fSqEcazjFKfPKqpZzQmiftkaznTqj1QPgv/CiPMpC3BhIfxQ0
# z9JMq++bPf4OuGQq+nUoJEHtQr8FnGZJUlD0UfM2SU2LINIsVzV5K6jzRWC8I41Y
# 99xh3pP+OcD5sjClTNfpmEpYPtMDiP6zj9NeS3YSUZPJjAw7W4oiqMEmCPkUEBID
# fV8ju2TjY+Cm4T72wnSyPx4JduyrXUZ14mCjWAkBKAAOhFTuzuldyF4wEr1GnrXT
# drnSDmuZDNIztM2xAgMBAAGjggFdMIIBWTASBgNVHRMBAf8ECDAGAQH/AgEAMB0G
# A1UdDgQWBBS6FtltTYUvcyl2mi91jGogj57IbzAfBgNVHSMEGDAWgBTs1+OC0nFd
# ZEzfLmc/57qYrhwPTzAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAwwCgYIKwYBBQUH
# AwgwdwYIKwYBBQUHAQEEazBpMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdp
# Y2VydC5jb20wQQYIKwYBBQUHMAKGNWh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3J0MEMGA1UdHwQ8MDowOKA2oDSGMmh0
# dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRSb290RzQuY3Js
# MCAGA1UdIAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATANBgkqhkiG9w0BAQsF
# AAOCAgEAfVmOwJO2b5ipRCIBfmbW2CFC4bAYLhBNE88wU86/GPvHUF3iSyn7cIoN
# qilp/GnBzx0H6T5gyNgL5Vxb122H+oQgJTQxZ822EpZvxFBMYh0MCIKoFr2pVs8V
# c40BIiXOlWk/R3f7cnQU1/+rT4osequFzUNf7WC2qk+RZp4snuCKrOX9jLxkJods
# kr2dfNBwCnzvqLx1T7pa96kQsl3p/yhUifDVinF2ZdrM8HKjI/rAJ4JErpknG6sk
# HibBt94q6/aesXmZgaNWhqsKRcnfxI2g55j7+6adcq/Ex8HBanHZxhOACcS2n82H
# hyS7T6NJuXdmkfFynOlLAlKnN36TU6w7HQhJD5TNOXrd/yVjmScsPT9rp/Fmw0HN
# T7ZAmyEhQNC3EyTN3B14OuSereU0cZLXJmvkOHOrpgFPvT87eK1MrfvElXvtCl8z
# OYdBeHo46Zzh3SP9HSjTx/no8Zhf+yvYfvJGnXUsHicsJttvFXseGYs2uJPU5vIX
# mVnKcPA3v5gA3yAWTyf7YGcWoWa63VXAOimGsJigK+2VQbc61RWYMbRiCQ8KvYHZ
# E/6/pNHzV9m8BPqC3jLfBInwAM1dwvnQI38AC+R2AibZ8GV2QqYphwlHK+Z/GqSF
# D/yYlvZVVCsfgPrA8g4r5db7qS9EFUrnEw4d2zc4GqEr9u3WfPwwggbAMIIEqKAD
# AgECAhAMTWlyS5T6PCpKPSkHgD1aMA0GCSqGSIb3DQEBCwUAMGMxCzAJBgNVBAYT
# AlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQg
# VHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0EwHhcNMjIw
# OTIxMDAwMDAwWhcNMzMxMTIxMjM1OTU5WjBGMQswCQYDVQQGEwJVUzERMA8GA1UE
# ChMIRGlnaUNlcnQxJDAiBgNVBAMTG0RpZ2lDZXJ0IFRpbWVzdGFtcCAyMDIyIC0g
# MjCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAM/spSY6xqnya7uNwQ2a
# 26HoFIV0MxomrNAcVR4eNm28klUMYfSdCXc9FZYIL2tkpP0GgxbXkZI4HDEClvty
# sZc6Va8z7GGK6aYo25BjXL2JU+A6LYyHQq4mpOS7eHi5ehbhVsbAumRTuyoW51BI
# u4hpDIjG8b7gL307scpTjUCDHufLckkoHkyAHoVW54Xt8mG8qjoHffarbuVm3eJc
# 9S/tjdRNlYRo44DLannR0hCRRinrPibytIzNTLlmyLuqUDgN5YyUXRlav/V7QG5v
# FqianJVHhoV5PgxeZowaCiS+nKrSnLb3T254xCg/oxwPUAY3ugjZNaa1Htp4WB05
# 6PhMkRCWfk3h3cKtpX74LRsf7CtGGKMZ9jn39cFPcS6JAxGiS7uYv/pP5Hs27wZE
# 5FX/NurlfDHn88JSxOYWe1p+pSVz28BqmSEtY+VZ9U0vkB8nt9KrFOU4ZodRCGv7
# U0M50GT6Vs/g9ArmFG1keLuY/ZTDcyHzL8IuINeBrNPxB9ThvdldS24xlCmL5kGk
# ZZTAWOXlLimQprdhZPrZIGwYUWC6poEPCSVT8b876asHDmoHOWIZydaFfxPZjXnP
# YsXs4Xu5zGcTB5rBeO3GiMiwbjJ5xwtZg43G7vUsfHuOy2SJ8bHEuOdTXl9V0n0Z
# KVkDTvpd6kVzHIR+187i1Dp3AgMBAAGjggGLMIIBhzAOBgNVHQ8BAf8EBAMCB4Aw
# DAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAgBgNVHSAEGTAX
# MAgGBmeBDAEEAjALBglghkgBhv1sBwEwHwYDVR0jBBgwFoAUuhbZbU2FL3Mpdpov
# dYxqII+eyG8wHQYDVR0OBBYEFGKK3tBh/I8xFO2XC809KpQU31KcMFoGA1UdHwRT
# MFEwT6BNoEuGSWh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0
# ZWRHNFJTQTQwOTZTSEEyNTZUaW1lU3RhbXBpbmdDQS5jcmwwgZAGCCsGAQUFBwEB
# BIGDMIGAMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wWAYI
# KwYBBQUHMAKGTGh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRy
# dXN0ZWRHNFJTQTQwOTZTSEEyNTZUaW1lU3RhbXBpbmdDQS5jcnQwDQYJKoZIhvcN
# AQELBQADggIBAFWqKhrzRvN4Vzcw/HXjT9aFI/H8+ZU5myXm93KKmMN31GT8Ffs2
# wklRLHiIY1UJRjkA/GnUypsp+6M/wMkAmxMdsJiJ3HjyzXyFzVOdr2LiYWajFCpF
# h0qYQitQ/Bu1nggwCfrkLdcJiXn5CeaIzn0buGqim8FTYAnoo7id160fHLjsmEHw
# 9g6A++T/350Qp+sAul9Kjxo6UrTqvwlJFTU2WZoPVNKyG39+XgmtdlSKdG3K0gVn
# K3br/5iyJpU4GYhEFOUKWaJr5yI+RCHSPxzAm+18SLLYkgyRTzxmlK9dAlPrnuKe
# 5NMfhgFknADC6Vp0dQ094XmIvxwBl8kZI4DXNlpflhaxYwzGRkA7zl011Fk+Q5oY
# rsPJy8P7mxNfarXH4PMFw1nfJ2Ir3kHJU7n/NBBn9iYymHv+XEKUgZSCnawKi8ZL
# FUrTmJBFYDOA4CPe+AOk9kVH5c64A0JH6EE2cXet/aLol3ROLtoeHYxayB6a1cLw
# xiKoT5u92ByaUcQvmvZfpyeXupYuhVfAYOd4Vn9q78KVmksRAsiCnMkaBXy6cbVO
# epls9Oie1FqYyJ+/jbsYXEP10Cro4mLueATbvdH7WwqocH7wl4R44wgDXUcsY6gl
# OJcB0j862uXl9uab3H4szP8XTE0AotjWAQ64i+7m4HJViSwnGWH2dwGMMYIFRDCC
# BUACAQEwgYYwcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZ
# MBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hB
# MiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBDQQIQAybM8QJy2GqRSHGucYhV3TAJ
# BgUrDgMCGgUAoHAwEAYKKwYBBAGCNwIBDDECMAAwGQYJKoZIhvcNAQkDMQwGCisG
# AQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcN
# AQkEMRYEFI47vDfzj+E7ouTrz6+r1nxW9rEzMA0GCSqGSIb3DQEBAQUABIIBABI6
# EANvqj/lLmMnIS2Cg71sPuBKvdk5AuKaIoGhZPaZN5VmYEe5UzsKReVqedHDktWm
# QPu2w75/VFcAiQzKRw5/liTHeqSGQQi4sO+KRR3mUFD0kngisCYnndkXDei4CI5E
# mHXNPJv/hJuuln8BfpRFBWu6P4W2hKJ4ubUoMOeirU1E+ofxUIudgBEnJMhE6Vq2
# 5Yl/IW9adTdBcDa24ISGp03KKb0Uo9Sx9eSgV1gEEmZfiEpHUbjIu+BWECG9qALo
# 0ySiehKYNodyCRzXJHSQkIG9rNG9ooWf6X+OCMzsP+XferB+Vl6kxExdyo+Agq4U
# s8c7FD0yYHS+QwJxWEyhggMgMIIDHAYJKoZIhvcNAQkGMYIDDTCCAwkCAQEwdzBj
# MQswCQYDVQQGEwJVUzEXMBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMT
# MkRpZ2lDZXJ0IFRydXN0ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5n
# IENBAhAMTWlyS5T6PCpKPSkHgD1aMA0GCWCGSAFlAwQCAQUAoGkwGAYJKoZIhvcN
# AQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMjMwMjIwMDIyNjQ2WjAv
# BgkqhkiG9w0BCQQxIgQgodb2wm8ueNucOBvetiJjPDCDzViXVE4KOFmHMZBTphcw
# DQYJKoZIhvcNAQEBBQAEggIAIJzm5o8EUK5eq2xkflWSyutk4mERNKeIJb0bqnbj
# 2YpFNahhU5yooJU1ZadRsbc00Mi5j49mmJoH6Lz0FUUS151XdEiyv/zjEGvpM01d
# 9StjjLgN0ZXmpnT5J2bIQhvlcG3sPOJPJQHn+3ZqolQs+e7HXXz+SzhIkoy1vW7c
# 5VwD31aIigbn0vOA1W4uNr6LrkfD6BDKCVQkuZwT+zwC4Rty2zzWp6XE7jx8a5DZ
# jKogY/by/jZd+NdPL6M8YZrsMtLt06xLE73kpCo3IezR5aH42v9P4qUotc1niJjf
# WNEBHXyKHwEaytJSKbMtd7QGrhwNyaSj/J0vhJNGbpKgU+58CQnDPfQj727MaPVP
# IA+yindtO0kS+/oTqO7Djdafys7IjXxliIpEesbVssW4rL34wX54UrESazzdxLY6
# ggmBGvW9hN9qbxFpUfWjnaBIGtj65ZP84S2+ZNx20YQDdlZi+9qSl9rjdhw2Gg+A
# eu5cHnvSJrfQTwTMSxphXsQqMNqfBLBJKGWfuFgNR8UBQvKE8J2AKffpn1ShKOmD
# RFrTv3wWZnixxAANsaHQwWr/rVVm+mVEU4t4QPXDMLyeOIgQVCvW/Beqx2HY0naO
# dTyjQLbaN8AwHw+X82kgNHoxl/1tAfFengPOCeBjp+tafQ3Edy80gQyTFhSKTMiJ
# UmI=
# SIG # End signature block
