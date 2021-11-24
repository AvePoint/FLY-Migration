// Copyright (c) Microsoft Corporation. All rights reserved.

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
# MIIevgYJKoZIhvcNAQcCoIIerzCCHqsCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUlQGTMs5iNNudH705DfnTX0VH
# cXCgghnUMIIE/jCCA+agAwIBAgIQDUJK4L46iP9gQCHOFADw3TANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgVGltZXN0YW1waW5nIENBMB4XDTIxMDEwMTAwMDAwMFoXDTMxMDEw
# NjAwMDAwMFowSDELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lDZXJ0LCBJbmMu
# MSAwHgYDVQQDExdEaWdpQ2VydCBUaW1lc3RhbXAgMjAyMTCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBAMLmYYRnxYr1DQikRcpja1HXOhFCvQp1dU2UtAxQ
# tSYQ/h3Ib5FrDJbnGlxI70Tlv5thzRWRYlq4/2cLnGP9NmqB+in43Stwhd4CGPN4
# bbx9+cdtCT2+anaH6Yq9+IRdHnbJ5MZ2djpT0dHTWjaPxqPhLxs6t2HWc+xObTOK
# fF1FLUuxUOZBOjdWhtyTI433UCXoZObd048vV7WHIOsOjizVI9r0TXhG4wODMSlK
# XAwxikqMiMX3MFr5FK8VX2xDSQn9JiNT9o1j6BqrW7EdMMKbaYK02/xWVLwfoYer
# vnpbCiAvSwnJlaeNsvrWY4tOpXIc7p96AXP4Gdb+DUmEvQECAwEAAaOCAbgwggG0
# MA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsG
# AQUFBwMIMEEGA1UdIAQ6MDgwNgYJYIZIAYb9bAcBMCkwJwYIKwYBBQUHAgEWG2h0
# dHA6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzAfBgNVHSMEGDAWgBT0tuEgHf4prtLk
# YaWyoiWyyBc1bjAdBgNVHQ4EFgQUNkSGjqS6sGa+vCgtHUQ23eNqerwwcQYDVR0f
# BGowaDAyoDCgLoYsaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJl
# ZC10cy5jcmwwMqAwoC6GLGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFz
# c3VyZWQtdHMuY3JsMIGFBggrBgEFBQcBAQR5MHcwJAYIKwYBBQUHMAGGGGh0dHA6
# Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBPBggrBgEFBQcwAoZDaHR0cDovL2NhY2VydHMu
# ZGlnaWNlcnQuY29tL0RpZ2lDZXJ0U0hBMkFzc3VyZWRJRFRpbWVzdGFtcGluZ0NB
# LmNydDANBgkqhkiG9w0BAQsFAAOCAQEASBzctemaI7znGucgDo5nRv1CclF0CiNH
# o6uS0iXEcFm+FKDlJ4GlTRQVGQd58NEEw4bZO73+RAJmTe1ppA/2uHDPYuj1UUp4
# eTZ6J7fz51Kfk6ftQ55757TdQSKJ+4eiRgNO/PT+t2R3Y18jUmmDgvoaU+2QzI2h
# F3MN9PNlOXBL85zWenvaDLw9MtAby/Vh/HUIAHa8gQ74wOFcz8QRcucbZEnYIpp1
# FUL1LTI4gdr0YKK6tFL7XOBhJCVPst/JKahzQ1HavWPWH1ub9y4bTxMd90oNcX6X
# t/Q/hOvB46NJofrOp79Wz7pZdmGJX36ntI5nePk2mOHLKNpbh6aKLzCCBS0wggQV
# oAMCAQICEAMmzPECcthqkUhxrnGIVd0wDQYJKoZIhvcNAQELBQAwcjELMAkGA1UE
# BhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2lj
# ZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUg
# U2lnbmluZyBDQTAeFw0yMDExMDMwMDAwMDBaFw0yMzExMDcyMzU5NTlaMGoxCzAJ
# BgNVBAYTAlVTMRMwEQYDVQQIEwpOZXcgSmVyc2V5MRQwEgYDVQQHEwtKZXJzZXkg
# Q2l0eTEXMBUGA1UEChMOQXZlUG9pbnQsIEluYy4xFzAVBgNVBAMTDkF2ZVBvaW50
# LCBJbmMuMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA25HqHTGU8iMU
# K/1be1ZQ6Y5vQ/ZsUSe1d4NX/NspXT8gD9T5QXMx5JcPYBffpEkF0ver9H50HEFr
# XuRcdvUzCp6JgICrzJK/yyXNFtHWR8iJetQwlIUGbuidm0+kz0CiLle3kNWWLPkv
# sGsPEjfnRN1l/Kndd9TpS+6tshy09BK2GUDm4L9/S9mevrt3RPDBcgFJlg0J3q2N
# frHG+/JDcFUuKNscYugCnixUPmVhYesDNpXKID8Ak4dJiNXFPvgBzuIFYB/cj3O+
# aGWtBsysx/Xapn/DlvrZ0JPUDwIVj+hC7Za5twILBnxj/s3GiAdSaAGwEV/bHpN7
# 5E8d7eVwIQIDAQABo4IBxTCCAcEwHwYDVR0jBBgwFoAUWsS5eyoKo6XqcQPAYPkt
# 9mV1DlgwHQYDVR0OBBYEFOyYwss5KyzTx5mZqk7DzZlBLArqMA4GA1UdDwEB/wQE
# AwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzB3BgNVHR8EcDBuMDWgM6Axhi9odHRw
# Oi8vY3JsMy5kaWdpY2VydC5jb20vc2hhMi1hc3N1cmVkLWNzLWcxLmNybDA1oDOg
# MYYvaHR0cDovL2NybDQuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1jcy1nMS5j
# cmwwTAYDVR0gBEUwQzA3BglghkgBhv1sAwEwKjAoBggrBgEFBQcCARYcaHR0cHM6
# Ly93d3cuZGlnaWNlcnQuY29tL0NQUzAIBgZngQwBBAEwgYQGCCsGAQUFBwEBBHgw
# djAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsGAQUF
# BzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEyQXNz
# dXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0B
# AQsFAAOCAQEAeM+lpkJgU7WywjheIlM3Ctg47zhJL9bpESzxEgcTAhE+rWOuufQB
# ygYFz/7CjCAyFZx7PMdIm/QJJUm2WXMm7XCPxO9oi2i++prTKdqTWyt3pFRSBOQr
# A+SCn05IpQ7jwtpMsYs7FhhOK+nlxGMxjxjuCwSBA3UZeiZnX9yTEVAHem42rngP
# DabRfNxFQIf/k7T6ckHUSwUvut+tuc9N4VBlyn795tVYyBZ872fFevb/tIb7gl40
# dmNTLPIJ9YVkTaz2hhP8WoTzYgbGnv/9eToJq7tddsEQJARa4+9TFk5Bo2Cr0GSz
# ylCAoI/zv1cTlMhJ8pHyZn5OAIckaXZDEDCCBTAwggQYoAMCAQICEAQJGBtf1btm
# dVNDtW+VUAgwDQYJKoZIhvcNAQELBQAwZTELMAkGA1UEBhMCVVMxFTATBgNVBAoT
# DERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIGA1UE
# AxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTEzMTAyMjEyMDAwMFoX
# DTI4MTAyMjEyMDAwMFowcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0
# IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNl
# cnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBDQTCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBAPjTsxx/DhGvZ3cH0wsxSRnP0PtFmbE620T1f+Wo
# ndsy13Hqdp0FLreP+pJDwKX5idQ3Gde2qvCchqXYJawOeSg6funRZ9PG+yknx9N7
# I5TkkSOWkHeC+aGEI2YSVDNQdLEoJrskacLCUvIUZ4qJRdQtoaPpiCwgla4cSocI
# 3wz14k1gGL6qxLKucDFmM3E+rHCiq85/6XzLkqHlOzEcz+ryCuRXu0q16XTmK/5s
# y350OTYNkO/ktU6kqepqCquE86xnTrXE94zRICUj6whkPlKWwfIPEvTFjg/Bougs
# UfdzvL2FsWKDc0GCB+Q4i2pzINAPZHM8np+mM6n9Gd8lk9ECAwEAAaOCAc0wggHJ
# MBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoG
# CCsGAQUFBwMDMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDovL29j
# c3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8EejB4
# MDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVk
# SURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGln
# aUNlcnRBc3N1cmVkSURSb290Q0EuY3JsME8GA1UdIARIMEYwOAYKYIZIAYb9bAAC
# BDAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BTMAoG
# CGCGSAGG/WwDMB0GA1UdDgQWBBRaxLl7KgqjpepxA8Bg+S32ZXUOWDAfBgNVHSME
# GDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG9w0BAQsFAAOCAQEAPuwN
# WiSz8yLRFcgsfCUpdqgdXRwtOhrE7zBh134LYP3DPQ/Er4v97yrfIFU3sOH20ZJ1
# D1G0bqWOWuJeJIFOEKTuP3GOYw4TS63XX0R58zYUBor3nEZOXP+QsRsHDpEV+7qv
# tVHCjSSuJMbHJyqhKSgaOnEoAjwukaPAJRHinBRHoXpoaK+bp1wgXNlxsQyPu6j4
# xRJon89Ay0BEpRPw5mQMJQhCMrI2iiQC/i9yfhzXSUWW6Fkd6fp0ZGuy62ZD2rOw
# jNXpDd32ASDOmTFjPQgaGLOBm0/GkxAG/AeB+ova+YJJ92JuoVP6EpQYhS6Skepo
# bEQysmah5xikmmRR7zCCBTEwggQZoAMCAQICEAqhJdbWMht+QeQF2jaXwhUwDQYJ
# KoZIhvcNAQELBQAwZTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IElu
# YzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIGA1UEAxMbRGlnaUNlcnQg
# QXNzdXJlZCBJRCBSb290IENBMB4XDTE2MDEwNzEyMDAwMFoXDTMxMDEwNzEyMDAw
# MFowcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UE
# CxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1
# cmVkIElEIFRpbWVzdGFtcGluZyBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
# AQoCggEBAL3QMu5LzY9/3am6gpnFOVQoV7YjSsQOB0UzURB90Pl9TWh+57ag9I2z
# iOSXv2MhkJi/E7xX08PhfgjWahQAOPcuHjvuzKb2Mln+X2U/4Jvr40ZHBhpVfgsn
# fsCi9aDg3iI/Dv9+lfvzo7oiPhisEeTwmQNtO4V8CdPuXciaC1TjqAlxa+DPIhAP
# dc9xck4Krd9AOly3UeGheRTGTSQjMF287DxgaqwvB8z98OpH2YhQXv1mblZhJymJ
# hFHmgudGUP2UKiyn5HU+upgPhH+fMRTWrdXyZMt7HgXQhBlyF/EXBu89zdZN7wZC
# /aJTKk+FHcQdPK/P2qwQ9d2srOlW/5MCAwEAAaOCAc4wggHKMB0GA1UdDgQWBBT0
# tuEgHf4prtLkYaWyoiWyyBc1bjAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd
# 823IDzASBgNVHRMBAf8ECDAGAQH/AgEAMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUE
# DDAKBggrBgEFBQcDCDB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6
# Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMu
# ZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDCBgQYDVR0f
# BHoweDA6oDigNoY0aHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNz
# dXJlZElEUm9vdENBLmNybDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNlcnQuY29t
# L0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDBQBgNVHSAESTBHMDgGCmCGSAGG
# /WwAAgQwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29tL0NQ
# UzALBglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggEBAHGVEulRh1Zpze/d2nyq
# Y3qzeM8GN0CE70uEv8rPAwL9xafDDiBCLK938ysfDCFaKrcFNB1qrpn4J6Jmvwmq
# YN92pDqTD/iy0dh8GWLoXoIlHsS6HHssIeLWWywUNUMEaLLbdQLgcseY1jxk5R9I
# EBhfiThhTWJGJIdjjJFSLK8pieV4H9YLFKWA1xJHcLN11ZOFk362kmf7U2GJqPVr
# lsD0WGkNfMgBsbkodbeZY4UijGHKeZR+WfyMD+NvtQEmtmyl7odRIeRYYJu6DC0r
# baLEfrvEJStHAgh8Sa4TtuF8QkIoxhhWz0E0tmZdtnR79VYzIi8iNrJLokqV2PWm
# jlIwggU0MIIDHKADAgECAgphHLKKAAAAAAAmMA0GCSqGSIb3DQEBBQUAMH8xCzAJ
# BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25k
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKTAnBgNVBAMTIE1pY3Jv
# c29mdCBDb2RlIFZlcmlmaWNhdGlvbiBSb290MB4XDTExMDQxNTE5NDEzN1oXDTIx
# MDQxNTE5NTEzN1owZTELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IElu
# YzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIGA1UEAxMbRGlnaUNlcnQg
# QXNzdXJlZCBJRCBSb290IENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
# AQEArQ4VzuRDgFyxh/O3YPlxEqWu3CaUiKr0zvUgOShYYAz4gNqpFZUyYTy1sSiE
# iorcnwoMgxd6j5Csiud5U1wxhCr2D5gyNnbM3t08qKLvavsh8lJh358g1x/isdn+
# GGTSEltf+VgYNbxHzaE2+Wt/1LA4PsEbw4wz2dgvGP4oD7Ong9bDbkTAYTWWFv5Z
# nIt2bdfxoksNK/8LctqeYNCOkDXGeFWHIKHP5W0KyEl8MZgzbCLph9AyWqK6E4IR
# 7TkXnZk6cqHm+qTZ1Rcxda6FfSKuPwFGhvYoecix2uRXF8R+HA6wtJKmVrO9spft
# qqfwt8WoP5UW0P+hlusIXxh3TwIDAQABo4HLMIHIMBEGA1UdIAQKMAgwBgYEVR0g
# ADALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUReuir/SS
# y4IxLVGLp6chnfNtyA8wHwYDVR0jBBgwFoAUYvsKIVt/Q24R2glUUGv10pZx8Z4w
# VQYDVR0fBE4wTDBKoEigRoZEaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9j
# cmwvcHJvZHVjdHMvTWljcm9zb2Z0Q29kZVZlcmlmUm9vdC5jcmwwDQYJKoZIhvcN
# AQEFBQADggIBAFz1si0Czu0BtTUS2BP3qkAUx6FcoIpV7X5V6mrEVxdv0EciQjZY
# 78WsYcX2LFLOaubIDYXaszRCDqQCJRgmcrkqTqV+SxbyoOQMRJziTZr0dPD5J6Zp
# kDHCRGVDSMdIadD8hAnyhhQKwimWhX8R64cTF27T7Gv/HVeKsXsepaB86aJ6aOX6
# xrFh1nJj+jeRY4NVmfgdYU8Mb6P3vLEVKsyNheMUF+9+SUQ/sCLA8Ky+L9vhDIaw
# 9FhcWhCpS83zRIpGUgg+CmIQ6UWVBLeLjUsHT1ANt7vn+4yieHjGxTt2Y7LP5SGE
# Wmb84Ex5g07PqO5wBYZYfMKc1zyjrTx+dmJch9DtfNXFWxQh9L51onXS6eFa0CAw
# eEFiTWtebhsXECRK2FiHddAV12K7/RhWZYQlYZd/qtSd9PNdbaAxwuGeAqw+kMMy
# fugykDQW0IsUz5WszuWMVKJluL/tGGpXBz7T55pKLwgaBBxJhxqK5hsIo2XYHDHF
# DZy6s2jd9FB2FgZ1/sQD59E+39yGLhACfmYSllNOevM2WHmxIELYlj81vj+O8pmX
# Q/XkDOE8aHKMjUnXWlK1c/t6NZQ6YbCEgsBIhcGXMtObcl+g0jSPfvBGfPKMcpTH
# B7DXtbIwuBll8JyDJ7Cgq9Cicn4FD7Ou3blbm0K8wyZjRWuG8R1GQ+3IMYIEVDCC
# BFACAQEwgYYwcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZ
# MBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hB
# MiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBDQQIQAybM8QJy2GqRSHGucYhV3TAJ
# BgUrDgMCGgUAoHAwEAYKKwYBBAGCNwIBDDECMAAwGQYJKoZIhvcNAQkDMQwGCisG
# AQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcN
# AQkEMRYEFK58lzEcxvBGXuj2XlkbugDGtlziMA0GCSqGSIb3DQEBAQUABIIBAKzt
# sN3cH6+Y1UOciMHVWZzZTXSJWZQviaECa6v+qybh94tL3uEsDkRUc17h9Hi0At9T
# d0ov032On+P5SXl1Pc2oRrRHuzIlfiRI7Za96Co+tjm6KIaPXRatOCsRKbf4GehP
# csHVA5KbPCAj8G3+/ZKBh1ggWtul6shEvA8rQ0lVHC96D5a+oC3gO9Cs+r1O3uWC
# XHtRSmd+8E1HBT+6/uiDCsjDWICx/a/I0e3TmhBjlGGNCpgE6u/F2w5vUkfodfVH
# gx/WeNVQ6jwN3/pg6jIdVzbrOTQlUpaNJJ8iN5COtsfbHUKE9P9IXhxJVyY3tV4y
# lOOImaMBOP68mQ30ZumhggIwMIICLAYJKoZIhvcNAQkGMYICHTCCAhkCAQEwgYYw
# cjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQ
# d3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVk
# IElEIFRpbWVzdGFtcGluZyBDQQIQDUJK4L46iP9gQCHOFADw3TANBglghkgBZQME
# AgEFAKBpMBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8X
# DTIxMTEyMzA5MTUzMlowLwYJKoZIhvcNAQkEMSIEIGmm9WOIcXaS5bO6cLXO30ru
# h33JRG16Z6wMLvTXMjW+MA0GCSqGSIb3DQEBAQUABIIBAH/PwrVlNbsrXnV5HdHD
# +k15Proi2P8qxJf8qiphRJ+TuikMBsmQM6jVaEzNsbgbAZfdmZ8w6wWpFSuFjVcz
# z0vmHo1wIHrWPdp2Uzmb9IWd2gQCYljhQD/etoOMLGN3+joQtBSCMFBA7MCVF7Yi
# ALcPqUTd9oJkw0qOOVIG2fteZjyq4uYBMC1S+nk958CMuo12He2NclbCiZGy19EC
# Uibb22WKRZFh6WijO/r/q9DOz/XDGsm+FkGNHLN4p2b2Z2AVGHwyDcZwJhGvR3NJ
# kkTQ0HchGTiEkWQJ+c2CZuuyVkBqtzPS1dqzKEzqozVZYKSsEF0lR2IWRSOZoVGl
# FO0=
# SIG # End signature block
