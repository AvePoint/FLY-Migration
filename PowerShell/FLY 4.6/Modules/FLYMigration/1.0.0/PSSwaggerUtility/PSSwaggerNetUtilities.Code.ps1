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
# MIIXwwYJKoZIhvcNAQcCoIIXtDCCF7ACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUlQGTMs5iNNudH705DfnTX0VH
# cXCgghL+MIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
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
# ggUtMIIEFaADAgECAhADJszxAnLYapFIca5xiFXdMA0GCSqGSIb3DQEBCwUAMHIx
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJ
# RCBDb2RlIFNpZ25pbmcgQ0EwHhcNMjAxMTAzMDAwMDAwWhcNMjMxMTA3MjM1OTU5
# WjBqMQswCQYDVQQGEwJVUzETMBEGA1UECBMKTmV3IEplcnNleTEUMBIGA1UEBxML
# SmVyc2V5IENpdHkxFzAVBgNVBAoTDkF2ZVBvaW50LCBJbmMuMRcwFQYDVQQDEw5B
# dmVQb2ludCwgSW5jLjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANuR
# 6h0xlPIjFCv9W3tWUOmOb0P2bFEntXeDV/zbKV0/IA/U+UFzMeSXD2AX36RJBdL3
# q/R+dBxBa17kXHb1MwqeiYCAq8ySv8slzRbR1kfIiXrUMJSFBm7onZtPpM9Aoi5X
# t5DVliz5L7BrDxI350TdZfyp3XfU6UvurbIctPQSthlA5uC/f0vZnr67d0TwwXIB
# SZYNCd6tjX6xxvvyQ3BVLijbHGLoAp4sVD5lYWHrAzaVyiA/AJOHSYjVxT74Ac7i
# BWAf3I9zvmhlrQbMrMf12qZ/w5b62dCT1A8CFY/oQu2WubcCCwZ8Y/7NxogHUmgB
# sBFf2x6Te+RPHe3lcCECAwEAAaOCAcUwggHBMB8GA1UdIwQYMBaAFFrEuXsqCqOl
# 6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBTsmMLLOSss08eZmapOw82ZQSwK6jAOBgNV
# HQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAwbjA1oDOg
# MYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1jcy1nMS5j
# cmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFzc3VyZWQt
# Y3MtZzEuY3JsMEwGA1UdIARFMEMwNwYJYIZIAYb9bAMBMCowKAYIKwYBBQUHAgEW
# HGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwCAYGZ4EMAQQBMIGEBggrBgEF
# BQcBAQR4MHYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBO
# BggrBgEFBQcwAoZCaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# U0hBMkFzc3VyZWRJRENvZGVTaWduaW5nQ0EuY3J0MAwGA1UdEwEB/wQCMAAwDQYJ
# KoZIhvcNAQELBQADggEBAHjPpaZCYFO1ssI4XiJTNwrYOO84SS/W6REs8RIHEwIR
# Pq1jrrn0AcoGBc/+wowgMhWcezzHSJv0CSVJtllzJu1wj8TvaItovvqa0ynak1sr
# d6RUUgTkKwPkgp9OSKUO48LaTLGLOxYYTivp5cRjMY8Y7gsEgQN1GXomZ1/ckxFQ
# B3puNq54Dw2m0XzcRUCH/5O0+nJB1EsFL7rfrbnPTeFQZcp+/ebVWMgWfO9nxXr2
# /7SG+4JeNHZjUyzyCfWFZE2s9oYT/FqE82IGxp7//Xk6Cau7XXbBECQEWuPvUxZO
# QaNgq9Bks8pQgKCP879XE5TISfKR8mZ+TgCHJGl2QxAwggUwMIIEGKADAgECAhAE
# CRgbX9W7ZnVTQ7VvlVAIMA0GCSqGSIb3DQEBCwUAMGUxCzAJBgNVBAYTAlVTMRUw
# EwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20x
# JDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0xMzEwMjIx
# MjAwMDBaFw0yODEwMjIxMjAwMDBaMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxE
# aWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNVBAMT
# KERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0EwggEiMA0G
# CSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQD407Mcfw4Rr2d3B9MLMUkZz9D7RZmx
# OttE9X/lqJ3bMtdx6nadBS63j/qSQ8Cl+YnUNxnXtqrwnIal2CWsDnkoOn7p0WfT
# xvspJ8fTeyOU5JEjlpB3gvmhhCNmElQzUHSxKCa7JGnCwlLyFGeKiUXULaGj6Ygs
# IJWuHEqHCN8M9eJNYBi+qsSyrnAxZjNxPqxwoqvOf+l8y5Kh5TsxHM/q8grkV7tK
# tel05iv+bMt+dDk2DZDv5LVOpKnqagqrhPOsZ061xPeM0SAlI+sIZD5SlsHyDxL0
# xY4PwaLoLFH3c7y9hbFig3NBggfkOItqcyDQD2RzPJ6fpjOp/RnfJZPRAgMBAAGj
# ggHNMIIByTASBgNVHRMBAf8ECDAGAQH/AgEAMA4GA1UdDwEB/wQEAwIBhjATBgNV
# HSUEDDAKBggrBgEFBQcDAzB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0
# dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2Vy
# dHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDCBgQYD
# VR0fBHoweDA6oDigNoY0aHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# QXNzdXJlZElEUm9vdENBLmNybDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNlcnQu
# Y29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDBPBgNVHSAESDBGMDgGCmCG
# SAGG/WwAAgQwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29t
# L0NQUzAKBghghkgBhv1sAzAdBgNVHQ4EFgQUWsS5eyoKo6XqcQPAYPkt9mV1Dlgw
# HwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wDQYJKoZIhvcNAQELBQAD
# ggEBAD7sDVoks/Mi0RXILHwlKXaoHV0cLToaxO8wYdd+C2D9wz0PxK+L/e8q3yBV
# N7Dh9tGSdQ9RtG6ljlriXiSBThCk7j9xjmMOE0ut119EefM2FAaK95xGTlz/kLEb
# Bw6RFfu6r7VRwo0kriTGxycqoSkoGjpxKAI8LpGjwCUR4pwUR6F6aGivm6dcIFzZ
# cbEMj7uo+MUSaJ/PQMtARKUT8OZkDCUIQjKyNookAv4vcn4c10lFluhZHen6dGRr
# sutmQ9qzsIzV6Q3d9gEgzpkxYz0IGhizgZtPxpMQBvwHgfqL2vmCSfdibqFT+hKU
# GIUukpHqaGxEMrJmoecYpJpkUe8xggQvMIIEKwIBATCBhjByMQswCQYDVQQGEwJV
# UzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQu
# Y29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgQ29kZSBTaWdu
# aW5nIENBAhADJszxAnLYapFIca5xiFXdMAkGBSsOAwIaBQCgcDAQBgorBgEEAYI3
# AgEMMQIwADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgEL
# MQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUrnyXMRzG8EZe6PZeWRu6
# AMa2XOIwDQYJKoZIhvcNAQEBBQAEggEArO2w3dwfr5jVQ5yIwdVZnNlNdIlZlC+J
# oQJrq/6rJuH3i0ve4SwORFRzXuH0eLQC31N3Si/TfY6f4/lJeXU9zahGtEe7MiV+
# JEjtlr3oKj62Obooho9dFq04KxEpt/gZ6E9ywdUDkps8ICPwbf79koGHWCBa26Xq
# yES8DytDSVUcL3oPlr6gLeA70Kz6vU7e5YJce1FKZ37wTUcFP7r+6IMKyMNYgLH9
# r8jR7dOaEGOUYY0KmATq78XbDm9SR+h19UeDH9Z41VDqPA3f+mDqMh1XNus5NCVS
# lo0knyI3kI62x9sdQoT0/0heHElXJje1XjKU44iZowE4/ryZDfRm6aGCAgswggIH
# BgkqhkiG9w0BCQYxggH4MIIB9AIBATByMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQK
# ExRTeW1hbnRlYyBDb3Jwb3JhdGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBT
# dGFtcGluZyBTZXJ2aWNlcyBDQSAtIEcyAhAOz/Q4yP6/NW4E2GqYGxpQMAkGBSsO
# AwIaBQCgXTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEP
# Fw0yMDEyMDkwNjU0MzBaMCMGCSqGSIb3DQEJBDEWBBSP4Pe3elPfxHRmVdiFyN9f
# uFrI+DANBgkqhkiG9w0BAQEFAASCAQCIDDo2c1vD1h6QQx6uR/9C+3kHsGMr17mz
# pnqHX10i/Dg8Amc5A89YYa/d9X9Rh+/+Jl6hMTdemlaQSNJp9Ig27Nqo+Ek6VFFb
# gV/baHeykvtqZ9qq8poge5n/UGc8w/kvZCinEJQ0hhI1mrzw8Q7GC71yHEXCZmE3
# Es4YnHbpnXNLwZjxT65Jh2de3w7QVtZDLbAbF+mzzp/Ex0owjq9IGfRpdiI6Lo2N
# FPUrbnHRHt3BJJ3IkNFyjfFSlqjvMf4d1YgGRdZdsAp/0fSs3IQ8tLuZ0gWN/3kd
# ZXVb/Oi5Mo9dj2BNyYb407bqBk0cVfYJyQ9c5L5oBLoFqmM/rbrT
# SIG # End signature block
