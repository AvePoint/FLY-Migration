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
# MIIfPgYJKoZIhvcNAQcCoIIfLzCCHysCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUlQGTMs5iNNudH705DfnTX0VH
# cXCgghlsMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
# AQUFADCBizELMAkGA1UEBhMCWkExFTATBgNVBAgTDFdlc3Rlcm4gQ2FwZTEUMBIG
# A1UEBxMLRHVyYmFudmlsbGUxDzANBgNVBAoTBlRoYXd0ZTEdMBsGA1UECxMUVGhh
# d3RlIENlcnRpZmljYXRpb24xHzAdBgNVBAMTFlRoYXd0ZSBUaW1lc3RhbXBpbmcg
# Q0EwHhcNMTIxMjIxMDAwMDAwWhcNMjAxMjMwMjM1OTU5WjBeMQswCQYDVQQGEwJV
# UzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFu
# dGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMjCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBALGss0lUS5ccEgrYJXmRIlcqb9y4JsRDc2vCvy5Q
# WvsUwnaOQwElQ7Sh4kX06Ld7w3TMIte0lAAC903tv7S3RCRrzV9FO9FEzkMScxeC
# i2m0K8uZHqxyGyZNcR+xMd37UWECU6aq9UksBXhFpS+JzueZ5/6M4lc/PcaS3Er4
# ezPkeQr78HWIQZz/xQNRmarXbJ+TaYdlKYOFwmAUxMjJOxTawIHwHw103pIiq8r3
# +3R8J+b3Sht/p8OeLa6K6qbmqicWfWH3mHERvOJQoUvlXfrlDqcsn6plINPYlujI
# fKVOSET/GeJEB5IL12iEgF1qeGRFzWBGflTBE3zFefHJwXECAwEAAaOB+jCB9zAd
# BgNVHQ4EFgQUX5r1blzMzHSa1N197z/b7EyALt0wMgYIKwYBBQUHAQEEJjAkMCIG
# CCsGAQUFBzABhhZodHRwOi8vb2NzcC50aGF3dGUuY29tMBIGA1UdEwEB/wQIMAYB
# Af8CAQAwPwYDVR0fBDgwNjA0oDKgMIYuaHR0cDovL2NybC50aGF3dGUuY29tL1Ro
# YXd0ZVRpbWVzdGFtcGluZ0NBLmNybDATBgNVHSUEDDAKBggrBgEFBQcDCDAOBgNV
# HQ8BAf8EBAMCAQYwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFRpbWVTdGFtcC0y
# MDQ4LTEwDQYJKoZIhvcNAQEFBQADgYEAAwmbj3nvf1kwqu9otfrjCR27T4IGXTdf
# plKfFo3qHJIJRG71betYfDDo+WmNI3MLEm9Hqa45EfgqsZuwGsOO61mWAK3ODE2y
# 0DGmCFwqevzieh1XTKhlGOl5QGIllm7HxzdqgyEIjkHq3dlXPx13SYcqFgZepjhq
# IhKjURmDfrYwggSjMIIDi6ADAgECAhAOz/Q4yP6/NW4E2GqYGxpQMA0GCSqGSIb3
# DQEBBQUAMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3Jh
# dGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBD
# QSAtIEcyMB4XDTEyMTAxODAwMDAwMFoXDTIwMTIyOTIzNTk1OVowYjELMAkGA1UE
# BhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTQwMgYDVQQDEytT
# eW1hbnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIFNpZ25lciAtIEc0MIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAomMLOUS4uyOnREm7Dv+h8GEKU5Ow
# mNutLA9KxW7/hjxTVQ8VzgQ/K/2plpbZvmF5C1vJTIZ25eBDSyKV7sIrQ8Gf2Gi0
# jkBP7oU4uRHFI/JkWPAVMm9OV6GuiKQC1yoezUvh3WPVF4kyW7BemVqonShQDhfu
# ltthO0VRHc8SVguSR/yrrvZmPUescHLnkudfzRC5xINklBm9JYDh6NIipdC6Anqh
# d5NbZcPuF3S8QYYq3AhMjJKMkS2ed0QfaNaodHfbDlsyi1aLM73ZY8hJnTrFxeoz
# C9Lxoxv0i77Zs1eLO94Ep3oisiSuLsdwxb5OgyYI+wu9qU+ZCOEQKHKqzQIDAQAB
# o4IBVzCCAVMwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAO
# BgNVHQ8BAf8EBAMCB4AwcwYIKwYBBQUHAQEEZzBlMCoGCCsGAQUFBzABhh5odHRw
# Oi8vdHMtb2NzcC53cy5zeW1hbnRlYy5jb20wNwYIKwYBBQUHMAKGK2h0dHA6Ly90
# cy1haWEud3Muc3ltYW50ZWMuY29tL3Rzcy1jYS1nMi5jZXIwPAYDVR0fBDUwMzAx
# oC+gLYYraHR0cDovL3RzLWNybC53cy5zeW1hbnRlYy5jb20vdHNzLWNhLWcyLmNy
# bDAoBgNVHREEITAfpB0wGzEZMBcGA1UEAxMQVGltZVN0YW1wLTIwNDgtMjAdBgNV
# HQ4EFgQURsZpow5KFB7VTNpSYxc/Xja8DeYwHwYDVR0jBBgwFoAUX5r1blzMzHSa
# 1N197z/b7EyALt0wDQYJKoZIhvcNAQEFBQADggEBAHg7tJEqAEzwj2IwN3ijhCcH
# bxiy3iXcoNSUA6qGTiWfmkADHN3O43nLIWgG2rYytG2/9CwmYzPkSWRtDebDZw73
# BaQ1bHyJFsbpst+y6d0gxnEPzZV03LZc3r03H0N45ni1zSgEIKOq8UvEiCmRDoDR
# EfzdXHZuT14ORUZBbg2w6jiasTraCXEQ/Bx5tIB7rGn0/Zy2DBYr8X9bCT2bW+IW
# yhOBbQAuOA2oKY8s4bL0WqkBrxWcLC9JG9siu8P+eJRRw4axgohd8D20UaF5Mysu
# e7ncIAkTcetqGVvP6KUwVyyJST+5z3/Jvz4iaGNTmr1pdKzFHTx/kuDDvBzYBHUw
# ggVZMIIEQaADAgECAhA9eNf5dklgsmF99PAeyoYqMA0GCSqGSIb3DQEBCwUAMIHK
# MQswCQYDVQQGEwJVUzEXMBUGA1UEChMOVmVyaVNpZ24sIEluYy4xHzAdBgNVBAsT
# FlZlcmlTaWduIFRydXN0IE5ldHdvcmsxOjA4BgNVBAsTMShjKSAyMDA2IFZlcmlT
# aWduLCBJbmMuIC0gRm9yIGF1dGhvcml6ZWQgdXNlIG9ubHkxRTBDBgNVBAMTPFZl
# cmlTaWduIENsYXNzIDMgUHVibGljIFByaW1hcnkgQ2VydGlmaWNhdGlvbiBBdXRo
# b3JpdHkgLSBHNTAeFw0xMzEyMTAwMDAwMDBaFw0yMzEyMDkyMzU5NTlaMH8xCzAJ
# BgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3JhdGlvbjEfMB0GA1UE
# CxMWU3ltYW50ZWMgVHJ1c3QgTmV0d29yazEwMC4GA1UEAxMnU3ltYW50ZWMgQ2xh
# c3MgMyBTSEEyNTYgQ29kZSBTaWduaW5nIENBMIIBIjANBgkqhkiG9w0BAQEFAAOC
# AQ8AMIIBCgKCAQEAl4MeABavLLHSCMTXaJNRYB5x9uJHtNtYTSNiarS/WhtR96MN
# GHdou9g2qy8hUNqe8+dfJ04LwpfICXCTqdpcDU6kDZGgtOwUzpFyVC7Oo9tE6VIb
# P0E8ykrkqsDoOatTzCHQzM9/m+bCzFhqghXuPTbPHMWXBySO8Xu+MS09bty1mUKf
# S2GVXxxw7hd924vlYYl4x2gbrxF4GpiuxFVHU9mzMtahDkZAxZeSitFTp5lbhTVX
# 0+qTYmEgCscwdyQRTWKDtrp7aIIx7mXK3/nVjbI13Iwrb2pyXGCEnPIMlF7AVlIA
# SMzT+KV93i/XE+Q4qITVRrgThsIbnepaON2b2wIDAQABo4IBgzCCAX8wLwYIKwYB
# BQUHAQEEIzAhMB8GCCsGAQUFBzABhhNodHRwOi8vczIuc3ltY2IuY29tMBIGA1Ud
# EwEB/wQIMAYBAf8CAQAwbAYDVR0gBGUwYzBhBgtghkgBhvhFAQcXAzBSMCYGCCsG
# AQUFBwIBFhpodHRwOi8vd3d3LnN5bWF1dGguY29tL2NwczAoBggrBgEFBQcCAjAc
# GhpodHRwOi8vd3d3LnN5bWF1dGguY29tL3JwYTAwBgNVHR8EKTAnMCWgI6Ahhh9o
# dHRwOi8vczEuc3ltY2IuY29tL3BjYTMtZzUuY3JsMB0GA1UdJQQWMBQGCCsGAQUF
# BwMCBggrBgEFBQcDAzAOBgNVHQ8BAf8EBAMCAQYwKQYDVR0RBCIwIKQeMBwxGjAY
# BgNVBAMTEVN5bWFudGVjUEtJLTEtNTY3MB0GA1UdDgQWBBSWO1PweTOXr32D7y4r
# zMq3hh5yZjAfBgNVHSMEGDAWgBR/02Wnwt3su/AwCfNDOfoCrzMxMzANBgkqhkiG
# 9w0BAQsFAAOCAQEAE4UaHmmpN/egvaSvfh1hU/6djF4MpnUeeBcj3f3sGgNVOftx
# lcdlWqeOMNJEWmHbcG/aIQXCLnO6SfHRk/5dyc1eA+CJnj90Htf3OIup1s+7NS8z
# WKiSVtHITTuC5nmEFvwosLFH8x2iPu6H2aZ/pFalP62ELinefLyoqqM9BAHqupOi
# DlAiKRdMh+Q6EV/WpCWJmwVrL7TJAUwnewusGQUioGAVP9rJ+01Mj/tyZ3f9J5TH
# ujUOiEn+jf0or0oSvQ2zlwXeRAwV+jYrA9zBUAHxoRFdFOXivSdLVL4rhF4PpsN0
# BQrvl8OJIrEfd/O9zUPU8UypP7WLhK9k8tAUITCCBZowggOCoAMCAQICCmEZk+QA
# AAAAABwwDQYJKoZIhvcNAQEFBQAwfzELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEpMCcGA1UEAxMgTWljcm9zb2Z0IENvZGUgVmVyaWZpY2F0aW9u
# IFJvb3QwHhcNMTEwMjIyMTkyNTE3WhcNMjEwMjIyMTkzNTE3WjCByjELMAkGA1UE
# BhMCVVMxFzAVBgNVBAoTDlZlcmlTaWduLCBJbmMuMR8wHQYDVQQLExZWZXJpU2ln
# biBUcnVzdCBOZXR3b3JrMTowOAYDVQQLEzEoYykgMjAwNiBWZXJpU2lnbiwgSW5j
# LiAtIEZvciBhdXRob3JpemVkIHVzZSBvbmx5MUUwQwYDVQQDEzxWZXJpU2lnbiBD
# bGFzcyAzIFB1YmxpYyBQcmltYXJ5IENlcnRpZmljYXRpb24gQXV0aG9yaXR5IC0g
# RzUwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCvJAgIKXo1nmAMqudL
# O07cfLw8RRy7K+D+KQL5VwijZIUVJ/XxrcgxiV0i6CqqpkKzj/i5Vbext0uz/o9+
# B1fs70PbZmIVYc9gDaTY3vjgw2IIPVQT60nKWVSFJuUrjxuf6/WhkcIzSdhDY2pS
# S9KP6HBRTdGJaXvHcPaz3BJ023tdS1bTlr8Vd6Gw9KIl8q8ckmcY5fQGBO+QueQA
# 5N06tRn/Arr0PO7gi+s3i+z016zy9vA9r911kTMZHRxAy3QkGSGT2RT+rCpSx4/V
# BEnkjWNHiDxpg8v+R70rfk/Fla4OndTRQ8Bnc+MUCH7lP59zuDMKz10/NIeWiu5T
# 6CUVAgMBAAGjgcswgcgwEQYDVR0gBAowCDAGBgRVHSAAMA8GA1UdEwEB/wQFMAMB
# Af8wCwYDVR0PBAQDAgGGMB0GA1UdDgQWBBR/02Wnwt3su/AwCfNDOfoCrzMxMzAf
# BgNVHSMEGDAWgBRi+wohW39DbhHaCVRQa/XSlnHxnjBVBgNVHR8ETjBMMEqgSKBG
# hkRodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNy
# b3NvZnRDb2RlVmVyaWZSb290LmNybDANBgkqhkiG9w0BAQUFAAOCAgEAgSqCFow0
# ZyvlA+s0e4yio1CK9FWG8R6Mjq597gMZznKVGEitYhH9IP0/RwYBWuLgb4wVLE48
# alBsCzajz3oNnEK8XPgZ1WDjaebiI0FnjGiDdiuPk6MqtX++WfupybImj8qi84Ib
# mD6RlSeXhmHuW10Ha82GqOJlgKjiFeKyviMFaroM80eTTaykjAd5OcBhEjoFDYmj
# 7J9XiYT77Mp8R2YUkdi2Dxld5rhKrLxHyHFDluYyIKXcd4b9POOLcdt7mwP8tx0y
# ZOsWUqBDo/ourVmSTnzH8jNCSDhROnw4xxskIihAHhpGHxfbGPfwJzVsuGPZzblk
# XSulXu/GKbTyx/ghzAS6V/0BtqvGZ/nn05l/9PUi+nL1/f86HEI6ofmAGKXujRzU
# Zp5FAf6q7v/7F48w9/HNKcWd7LXVSQA9hbjLu5M6J2pJwDCuZsn3Iygydvmkg1bI
# SM5alqqgzAzEf7SOl69t41Qnw5+GwNbkcwiXBdvQVGJeA0jC1Z9/p2aM0J2wT9TT
# mF9Lesl/silS0BKAxw9Uth5nzcagbBEDhNNIdecq/rA7bgo6pmt2mQWj8XdoYTMU
# Rwb8U39SvZIUXEokameMr42QqtD2eSEbkyZ8w84evYg4kq5FxhlqSVCzBfiuWTeK
# aiUDlLFZgVDouoOAtyM19Ha5Zx1ZGK0gjZQwggXUMIIEvKADAgECAhA3bEo5LxqW
# 1vtLJfCtzt0GMA0GCSqGSIb3DQEBCwUAMH8xCzAJBgNVBAYTAlVTMR0wGwYDVQQK
# ExRTeW1hbnRlYyBDb3Jwb3JhdGlvbjEfMB0GA1UECxMWU3ltYW50ZWMgVHJ1c3Qg
# TmV0d29yazEwMC4GA1UEAxMnU3ltYW50ZWMgQ2xhc3MgMyBTSEEyNTYgQ29kZSBT
# aWduaW5nIENBMB4XDTE3MTAwNTAwMDAwMFoXDTIwMTAzMDIzNTk1OVowbDELMAkG
# A1UEBhMCVVMxEzARBgNVBAgMCk5ldyBKZXJzZXkxFDASBgNVBAcMC0plcnNleSBD
# aXR5MREwDwYDVQQKDAhBdmVQb2ludDEMMAoGA1UECwwDUiZEMREwDwYDVQQDDAhB
# dmVQb2ludDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALDVR6zALn+y
# /aQjTGT1uEMQpR8ucaDiCqifToKjyT2O65HWRMTXPb8ytW5Qpoy7UgBxnq+CmfAn
# Oxwqe5FLAT/wiV7OG/tYBdRmS8UmSkLOzoB0jE43X7SeiZizHwv7XZBThDJqjZIg
# RWCb812h91DExu687M7UKnOIs9Wu91yeMBN7lteV5ZpMl+ga4l3Y/V90F8dzhdh2
# tdmpLm+k0g9AdEWZrdBrLKmeKFKsciiSzsyMOg3sJ+YQ8ufsywIXP44B16KOptz4
# mWJvpXb96qYx+gENFX3rzr0f60s9tnxZ1EAFIoEphSgnnLdGEtlR2dA78BBRWtnY
# Kuf4XhF2evaHYhiswtiWZ04ufKby+Ic8XqsfdHmxy6mBYdAL/ak3eZ5lM6LsfCL3
# 0QhyTks5FK/CiJLdtSiYB7Jd1Aitl2cxUImSYDihpvoNXaFNVpr3DhL460qCUmJ5
# LFlKpWWi5rv6KBFhesbYoFH/gC1Yjd2fS93GrOJSpsFTplDNWA60pSgAUfLJTDWB
# B825W0pMnW9XhbKjGXRV4Dbt/5xX5ogIeAdaTyXRGmd+QF6MgbZdQPwrvmD/DjYP
# Hf4FIl7ic52OyN7Go4AwzqBvbJfsUC8TxH+gYGVKFyZxzO3+kliXKNDoX6UGfqrD
# eFjfz1CvJnij8L3A2lfefl2SW/U4K4cBAgMBAAGjggFdMIIBWTAJBgNVHRMEAjAA
# MA4GA1UdDwEB/wQEAwIHgDArBgNVHR8EJDAiMCCgHqAchhpodHRwOi8vc3Yuc3lt
# Y2IuY29tL3N2LmNybDBhBgNVHSAEWjBYMFYGBmeBDAEEATBMMCMGCCsGAQUFBwIB
# FhdodHRwczovL2Quc3ltY2IuY29tL2NwczAlBggrBgEFBQcCAjAZDBdodHRwczov
# L2Quc3ltY2IuY29tL3JwYTATBgNVHSUEDDAKBggrBgEFBQcDAzBXBggrBgEFBQcB
# AQRLMEkwHwYIKwYBBQUHMAGGE2h0dHA6Ly9zdi5zeW1jZC5jb20wJgYIKwYBBQUH
# MAKGGmh0dHA6Ly9zdi5zeW1jYi5jb20vc3YuY3J0MB8GA1UdIwQYMBaAFJY7U/B5
# M5evfYPvLivMyreGHnJmMB0GA1UdDgQWBBTKXz1mZ/pkeJj8KpUzdiwuV/fNMDAN
# BgkqhkiG9w0BAQsFAAOCAQEACuccjZ4WK8gwBinBof2wrpf3YQzYpxhXU+TQendr
# uXt4ywceW9zp/QaFDWKtrtW/n4ZhhYjxgAmdYjXSbNQEdIc55mYVVUjaimPySfuM
# HAJotG4zRkbCwZdfepP525oMxvfUGuQJ82+cEmlRGxRVb8zP0Nym898JFGuwG/mv
# 2ScCPH3tB++LV2l0kVDGo/Mfi2fvUtdLIGq3nsJrlA8Ekk+CR38/wuitWxuyaQ/c
# cMnu6zUzh9W6Ijd2Q+3ZMJHpiaIncPaQllkSHPBmYvfHitoFXhvMj9TXEqboAkf3
# CHpajoWla+0cuhugQmTH9n/Ho3lv2OrwO5EguQJEsN2pcTGCBTwwggU4AgEBMIGT
# MH8xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3JhdGlvbjEf
# MB0GA1UECxMWU3ltYW50ZWMgVHJ1c3QgTmV0d29yazEwMC4GA1UEAxMnU3ltYW50
# ZWMgQ2xhc3MgMyBTSEEyNTYgQ29kZSBTaWduaW5nIENBAhA3bEo5LxqW1vtLJfCt
# zt0GMAkGBSsOAwIaBQCgcDAQBgorBgEEAYI3AgEMMQIwADAZBgkqhkiG9w0BCQMx
# DAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkq
# hkiG9w0BCQQxFgQUrnyXMRzG8EZe6PZeWRu6AMa2XOIwDQYJKoZIhvcNAQEBBQAE
# ggIAYAkyObJ9Dogl3x8+kELHmLtqj2+jceok58SPeHU2u6yIXnNmWm4DfheN2mLB
# kcbfCszNZ5rn0pmeCt7yEh6ryPYHpFRYK7IjpDUw82qAFERMmSnswjmrNN0I669P
# 6p7tde+8iKIRlyZS3f9JT6WkqenoqYGNLFZMKADh/OeLYuWSetLce7cHyetOR4u8
# lS1whGLg+lR7MeJmLkpZRQ78R/rfsu6NJqEiBjPaHpriJm3lTqHZjoPpdkgjMkMT
# Wm5L6FUqE5gkqPWE8rpEuXh9L0aSuEAZGVZsY/Hj8vRvWk0NHgmKFbVt7fvns33X
# sqPi3gis5ZDwdiR3tcw7tT2jYQdj+Gz3gHAfUTwh1/xinvD9nOJDsIxKJCzDgxUi
# sWEqVJBPpdyHDJ4kkM2p9HPsinac2w2Keo+ooUO69Zgy4zxN8VOs9/KUYQjtoOQe
# T932/V+AyQZgxbUbNHP7QbiAMFkCOVQZsBDMwkB9C2XJ6HsaFHdGpaa23GWIWJPr
# sMtuqrVHa9LElBKVIfJIEDC9y1uvriv3hrXGzHdXpl1Uu2ZQN2BPTWdq4WM9tmkb
# T/wRU1G3cNOjAlhVFUS+06ALs68iFmcLre5nyhikJMnO+dpPpXdIi7M9cP/RyVO1
# lmcOhAAU/p3TQkAi+n+VJJT1oEClOyog5c6iWNlVChF/ErihggILMIICBwYJKoZI
# hvcNAQkGMYIB+DCCAfQCAQEwcjBeMQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3lt
# YW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFudGVjIFRpbWUgU3RhbXBp
# bmcgU2VydmljZXMgQ0EgLSBHMgIQDs/0OMj+vzVuBNhqmBsaUDAJBgUrDgMCGgUA
# oF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUxDxcNMjAw
# MTE3MDQzNjUwWjAjBgkqhkiG9w0BCQQxFgQUEDWTJeJrRhyjcMwQoZYnyVNn+A4w
# DQYJKoZIhvcNAQEBBQAEggEAlg3u4OAFu1cmjYOFwohI94DVdvlQaoepp6eQDGCH
# U1qJZpXQIVOI4eYuONo4D0b+85aZoWA8G3TXGj0FNLrci7efjN4kL9e5jHoslugY
# FZwfCNRWrtozdqrluxMq/X2Tv9AhgGoR/bCjjHKOscPVI38gOJguYho22lZ5riKR
# 1qukTqcDmH5i8XPA/2+dpeb3C57Dhbg0GmUrHxbZDEkQ1ounEJ+SVFhFVDTDC6DS
# xCDKr7OgoETS3DoemlJIgh6qnS/3YHiRGMigcNpfQtlJdhv2rDHUF0DZWEuXkq1C
# V2MkF4AqC6MXLVzi/X9VrpY0RMj+6SPQJzCmtxc9jPN9TA==
# SIG # End signature block
