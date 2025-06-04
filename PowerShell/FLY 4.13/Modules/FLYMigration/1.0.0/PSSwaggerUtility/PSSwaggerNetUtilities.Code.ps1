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
//*  Copyright © 2017-2024 AvePoint® Inc. All Rights Reserved.
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
# MIIoGAYJKoZIhvcNAQcCoIIoCTCCKAUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAEddx2utJd4J7d
# k3l320OntKcEdKHMh143zUrlW6JKK6CCDZowggawMIIEmKADAgECAhAIrUCyYNKc
# TJ9ezam9k67ZMA0GCSqGSIb3DQEBDAUAMGIxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xITAfBgNV
# BAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBHNDAeFw0yMTA0MjkwMDAwMDBaFw0z
# NjA0MjgyMzU5NTlaMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcg
# UlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAw
# ggIKAoICAQDVtC9C0CiteLdd1TlZG7GIQvUzjOs9gZdwxbvEhSYwn6SOaNhc9es0
# JAfhS0/TeEP0F9ce2vnS1WcaUk8OoVf8iJnBkcyBAz5NcCRks43iCH00fUyAVxJr
# Q5qZ8sU7H/Lvy0daE6ZMswEgJfMQ04uy+wjwiuCdCcBlp/qYgEk1hz1RGeiQIXhF
# LqGfLOEYwhrMxe6TSXBCMo/7xuoc82VokaJNTIIRSFJo3hC9FFdd6BgTZcV/sk+F
# LEikVoQ11vkunKoAFdE3/hoGlMJ8yOobMubKwvSnowMOdKWvObarYBLj6Na59zHh
# 3K3kGKDYwSNHR7OhD26jq22YBoMbt2pnLdK9RBqSEIGPsDsJ18ebMlrC/2pgVItJ
# wZPt4bRc4G/rJvmM1bL5OBDm6s6R9b7T+2+TYTRcvJNFKIM2KmYoX7BzzosmJQay
# g9Rc9hUZTO1i4F4z8ujo7AqnsAMrkbI2eb73rQgedaZlzLvjSFDzd5Ea/ttQokbI
# YViY9XwCFjyDKK05huzUtw1T0PhH5nUwjewwk3YUpltLXXRhTT8SkXbev1jLchAp
# QfDVxW0mdmgRQRNYmtwmKwH0iU1Z23jPgUo+QEdfyYFQc4UQIyFZYIpkVMHMIRro
# OBl8ZhzNeDhFMJlP/2NPTLuqDQhTQXxYPUez+rbsjDIJAsxsPAxWEQIDAQABo4IB
# WTCCAVUwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQUaDfg67Y7+F8Rhvv+
# YXsIiGX0TkIwHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5nP+e6mK4cD08wDgYDVR0P
# AQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHcGCCsGAQUFBwEBBGswaTAk
# BggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMEEGCCsGAQUFBzAC
# hjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9v
# dEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsMy5kaWdpY2VydC5j
# b20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAcBgNVHSAEFTATMAcGBWeBDAED
# MAgGBmeBDAEEATANBgkqhkiG9w0BAQwFAAOCAgEAOiNEPY0Idu6PvDqZ01bgAhql
# +Eg08yy25nRm95RysQDKr2wwJxMSnpBEn0v9nqN8JtU3vDpdSG2V1T9J9Ce7FoFF
# UP2cvbaF4HZ+N3HLIvdaqpDP9ZNq4+sg0dVQeYiaiorBtr2hSBh+3NiAGhEZGM1h
# mYFW9snjdufE5BtfQ/g+lP92OT2e1JnPSt0o618moZVYSNUa/tcnP/2Q0XaG3Ryw
# YFzzDaju4ImhvTnhOE7abrs2nfvlIVNaw8rpavGiPttDuDPITzgUkpn13c5Ubdld
# AhQfQDN8A+KVssIhdXNSy0bYxDQcoqVLjc1vdjcshT8azibpGL6QB7BDf5WIIIJw
# 8MzK7/0pNVwfiThV9zeKiwmhywvpMRr/LhlcOXHhvpynCgbWJme3kuZOX956rEnP
# LqR0kq3bPKSchh/jwVYbKyP/j7XqiHtwa+aguv06P0WmxOgWkVKLQcBIhEuWTatE
# QOON8BUozu3xGFYHKi8QxAwIZDwzj64ojDzLj4gLDb879M4ee47vtevLt/B3E+bn
# KD+sEq6lLyJsQfmCXBVmzGwOysWGw/YmMwwHS6DTBwJqakAwSEs0qFEgu60bhQji
# WQ1tygVQK+pKHJ6l/aCnHwZ05/LWUpD9r4VIIflXO7ScA+2GRfS0YW6/aOImYIbq
# yK+p/pQd52MbOoZWeE4wggbiMIIEyqADAgECAhAPc9sqd/BkUUsWn0FQMB0UMA0G
# CSqGSIb3DQEBCwUAMGkxCzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwg
# SW5jLjFBMD8GA1UEAxM4RGlnaUNlcnQgVHJ1c3RlZCBHNCBDb2RlIFNpZ25pbmcg
# UlNBNDA5NiBTSEEzODQgMjAyMSBDQTEwHhcNMjMxMTAzMDAwMDAwWhcNMjYxMTE0
# MjM1OTU5WjBqMQswCQYDVQQGEwJVUzETMBEGA1UECBMKTmV3IEplcnNleTEUMBIG
# A1UEBxMLSmVyc2V5IENpdHkxFzAVBgNVBAoTDkF2ZVBvaW50LCBJbmMuMRcwFQYD
# VQQDEw5BdmVQb2ludCwgSW5jLjCCAaIwDQYJKoZIhvcNAQEBBQADggGPADCCAYoC
# ggGBAOEW7Ii2pvR9/732eojqygVHkWY2HMdaefS7g4Z4EOt6ABrXYcTFvIMax1DN
# 7ZCbfarSe6B0jsXnrNbhTZKJiphzbLAIs4NOi4EMxdWzDbc8oZqByMX77NxSiaR3
# PhqFGI99Utr9NUIBsruS6AccQ6CkP2nNejixv6BrsGJbUDrgz6A66x7V4WhYa6df
# qmMU8EucSyjcZB2A4h21H+jURe95N1SZThOw6vfFKn5JPnKvGTCuH0u19xi8d90j
# ZItOntrR92wzFG2jSd4Z3DeKyvIDWxGGqaDqloA7thXNGN/URNqTZfeXdsF6uUU2
# IojpWh8gYBTnu9i8cM9PVDOB420h5JaV+1XLO8m10LtnYBSWZWgUHpcTq7Suwbah
# 0/yiur0ltzR13dQ0wk2Xe1i/G8PlKw4IlyqESqizT3YxUGlqwcojIAYwaGBtATTf
# kCKq32rornXSmCqfrQICoA8dR7pry8hl/JloSD/+riT62F8r8mQTlLUw5xNiqBqE
# kIQvuQIDAQABo4ICAzCCAf8wHwYDVR0jBBgwFoAUaDfg67Y7+F8Rhvv+YXsIiGX0
# TkIwHQYDVR0OBBYEFJxiV1oIFotUW4UTNkwFNyJScORPMD4GA1UdIAQ3MDUwMwYG
# Z4EMAQQBMCkwJwYIKwYBBQUHAgEWG2h0dHA6Ly93d3cuZGlnaWNlcnQuY29tL0NQ
# UzAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwgbUGA1UdHwSB
# rTCBqjBToFGgT4ZNaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0VHJ1
# c3RlZEc0Q29kZVNpZ25pbmdSU0E0MDk2U0hBMzg0MjAyMUNBMS5jcmwwU6BRoE+G
# TWh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFRydXN0ZWRHNENvZGVT
# aWduaW5nUlNBNDA5NlNIQTM4NDIwMjFDQTEuY3JsMIGUBggrBgEFBQcBAQSBhzCB
# hDAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tMFwGCCsGAQUF
# BzAChlBodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVk
# RzRDb2RlU2lnbmluZ1JTQTQwOTZTSEEzODQyMDIxQ0ExLmNydDAJBgNVHRMEAjAA
# MA0GCSqGSIb3DQEBCwUAA4ICAQDE9SZRwvtvpHrw4OjJ1AKL0aabKlOUkxidOjEC
# wrWr4yFKJdHWHpouUFTye7M8gQS4FQDQqD4ys7a1joCQVd+WEiQIyy0TzJXxT7US
# tkhg8lD41cT7i857dgnSrX7Prp0Es/xFBhEKR0fMs3Sj20+qcnJNTB4TA9CPnUd4
# UL1Ve/bqsr5lVZgoPp6wbs0lXjsTEfzrio++T4ssc42eTxfv6YZgTmdrPEQNqLUa
# hQuQ0x5j8lVBBtt5PrC7TikkVB/GBZ+01EJrUQvcX3arZky1tviINBQ3EXRhyGkx
# zSz6Vk9NxwJVkdavIUkdDuUuqNVqp2a3Zsv2L3mwlr0UnKMgpBiPnxgC9u6e5tjR
# +plDe3fmD20XQTt/p61FueC7w92HC6YizDrynRX58h6KuRv2j/u2yZU3nipaiGlz
# 8jURf2ySxZXI2QG228Nfsg4y1Z61tPfYb4kcqTfVcaxh7azpP6BU33dkIyC7dmv4
# q3PueRcSyweKjqlQqeswnTeBS3+met1BbjkMdJJzqbIu5WONTBIHHH1RGsQYPn8i
# ms3pE0GhGl9c1r1BpufehQwSjCZRc/vHrHUOQyNimVKoOtls5UAxU5FXO3PKaHPO
# M6dFS1b+EF6drXV0M9/KdJVyyP4EK6CJQVt7RrQBRSSdQCKCYJ63VUF5amRuzY0s
# EqLoRTGCGdQwghnQAgEBMH0waTELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDkRpZ2lD
# ZXJ0LCBJbmMuMUEwPwYDVQQDEzhEaWdpQ2VydCBUcnVzdGVkIEc0IENvZGUgU2ln
# bmluZyBSU0E0MDk2IFNIQTM4NCAyMDIxIENBMQIQD3PbKnfwZFFLFp9BUDAdFDAN
# BglghkgBZQMEAgEFAKB8MBAGCisGAQQBgjcCAQwxAjAAMBkGCSqGSIb3DQEJAzEM
# BgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqG
# SIb3DQEJBDEiBCCGFrVqBWTjW46Eonhp2khMN6WrBJyp3FxRfXgyK+ED8DANBgkq
# hkiG9w0BAQEFAASCAYCwRpPJtinnBZ1LWHW2rWwTrjh4NovPqvfbeXRq3M8oaQGz
# wy6Mub3XNsIT1ekTjwjC8ivPxTEjzSBw0ud9npzFzYPZ62FaosmdRromBLeeSN7o
# dvnqTKa0WFvS6Jv9A5VCv9NLCawtj6PTnXbwYiBiGv/HC2l642YoGKNIIeeujFSM
# f6MSAU1Roxe9AmSHlApBzjr7wxs+FHY7/aVNkHxs2i7GXJPiRPQh25d3FhjClLI4
# COxoM/nJSbBpWo7Dw3/SWTDlc9A2fEuZsC3ejKnrU0NRS9hUih+xt2YJX7q/yu6f
# 64MkA+GJzgT5gigsegUJTF8X6eXoSjD+DWkHjaf2DOin5Kr+gZx1fNCb1JpxMngH
# 6Oop2E2SewePPD5PZSxyuJ2+mGGiTR1hBx3PIs5Zodn3sJH45tTA3OkVOyfWu9HO
# Lj5gQ1WriwbA+oWjGTwreNTFA8ftMGqNeY2pYP5qd8HHHzjC6bAwju+r7RbNt9ya
# w7ee29czFZByfrYoshahghcqMIIXJgYKKwYBBAGCNwMDATGCFxYwghcSBgkqhkiG
# 9w0BBwKgghcDMIIW/wIBAzEPMA0GCWCGSAFlAwQCAQUAMGgGCyqGSIb3DQEJEAEE
# oFkEVzBVAgEBBglghkgBhv1sBwEwITAJBgUrDgMCGgUABBR29huD+VoFMPe+Lvmq
# JPD2vOktCQIRAKYt64w+9iZ8j2aUsGQ4zOcYDzIwMjQxMjA0MDQzNzUwWqCCEwMw
# gga8MIIEpKADAgECAhALrma8Wrp/lYfG+ekE4zMEMA0GCSqGSIb3DQEBCwUAMGMx
# CzAJBgNVBAYTAlVTMRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMy
# RGlnaUNlcnQgVHJ1c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcg
# Q0EwHhcNMjQwOTI2MDAwMDAwWhcNMzUxMTI1MjM1OTU5WjBCMQswCQYDVQQGEwJV
# UzERMA8GA1UEChMIRGlnaUNlcnQxIDAeBgNVBAMTF0RpZ2lDZXJ0IFRpbWVzdGFt
# cCAyMDI0MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAvmpzn/aVIauW
# MLpbbeZZo7Xo/ZEfGMSIO2qZ46XB/QowIEMSvgjEdEZ3v4vrrTHleW1JWGErrjOL
# 0J4L0HqVR1czSzvUQ5xF7z4IQmn7dHY7yijvoQ7ujm0u6yXF2v1CrzZopykD07/9
# fpAT4BxpT9vJoJqAsP8YuhRvflJ9YeHjes4fduksTHulntq9WelRWY++TFPxzZrb
# ILRYynyEy7rS1lHQKFpXvo2GePfsMRhNf1F41nyEg5h7iOXv+vjX0K8RhUisfqw3
# TTLHj1uhS66YX2LZPxS4oaf33rp9HlfqSBePejlYeEdU740GKQM7SaVSH3TbBL8R
# 6HwX9QVpGnXPlKdE4fBIn5BBFnV+KwPxRNUNK6lYk2y1WSKour4hJN0SMkoaNV8h
# yyADiX1xuTxKaXN12HgR+8WulU2d6zhzXomJ2PleI9V2yfmfXSPGYanGgxzqI+Sh
# oOGLomMd3mJt92nm7Mheng/TBeSA2z4I78JpwGpTRHiT7yHqBiV2ngUIyCtd0pZ8
# zg3S7bk4QC4RrcnKJ3FbjyPAGogmoiZ33c1HG93Vp6lJ415ERcC7bFQMRbxqrMVA
# Niav1k425zYyFMyLNyE1QulQSgDpW9rtvVcIH7WvG9sqYup9j8z9J1XqbBZPJ5XL
# ln8mS8wWmdDLnBHXgYly/p1DhoQo5fkCAwEAAaOCAYswggGHMA4GA1UdDwEB/wQE
# AwIHgDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMCAGA1Ud
# IAQZMBcwCAYGZ4EMAQQCMAsGCWCGSAGG/WwHATAfBgNVHSMEGDAWgBS6FtltTYUv
# cyl2mi91jGogj57IbzAdBgNVHQ4EFgQUn1csA3cOKBWQZqVjXu5Pkh92oFswWgYD
# VR0fBFMwUTBPoE2gS4ZJaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0
# VHJ1c3RlZEc0UlNBNDA5NlNIQTI1NlRpbWVTdGFtcGluZ0NBLmNybDCBkAYIKwYB
# BQUHAQEEgYMwgYAwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNv
# bTBYBggrBgEFBQcwAoZMaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lD
# ZXJ0VHJ1c3RlZEc0UlNBNDA5NlNIQTI1NlRpbWVTdGFtcGluZ0NBLmNydDANBgkq
# hkiG9w0BAQsFAAOCAgEAPa0eH3aZW+M4hBJH2UOR9hHbm04IHdEoT8/T3HuBSyZe
# q3jSi5GXeWP7xCKhVireKCnCs+8GZl2uVYFvQe+pPTScVJeCZSsMo1JCoZN2mMew
# /L4tpqVNbSpWO9QGFwfMEy60HofN6V51sMLMXNTLfhVqs+e8haupWiArSozyAmGH
# /6oMQAh078qRh6wvJNU6gnh5OruCP1QUAvVSu4kqVOcJVozZR5RRb/zPd++PGE3q
# F1P3xWvYViUJLsxtvge/mzA75oBfFZSbdakHJe2BVDGIGVNVjOp8sNt70+kEoMF+
# T6tptMUNlehSR7vM+C13v9+9ZOUKzfRUAYSyyEmYtsnpltD/GWX8eM70ls1V6QG/
# ZOB6b6Yum1HvIiulqJ1Elesj5TMHq8CWT/xrW7twipXTJ5/i5pkU5E16RSBAdOp1
# 2aw8IQhhA/vEbFkEiF2abhuFixUDobZaA0VhqAsMHOmaT3XThZDNi5U2zHKhUs5u
# HHdG6BoQau75KiNbh0c+hatSF+02kULkftARjsyEpHKsF7u5zKRbt5oK5YGwFvgc
# 4pEVUNytmB3BpIiowOIIuDgP5M9WArHYSAR16gc0dP2XdkMEP5eBsX7bf/MGN4K3
# HP50v/01ZHo/Z5lGLvNwQ7XHBx1yomzLP8lx4Q1zZKDyHcp4VQJLu2kWTsKsOqQw
# ggauMIIElqADAgECAhAHNje3JFR82Ees/ShmKl5bMA0GCSqGSIb3DQEBCwUAMGIx
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xITAfBgNVBAMTGERpZ2lDZXJ0IFRydXN0ZWQgUm9vdCBH
# NDAeFw0yMjAzMjMwMDAwMDBaFw0zNzAzMjIyMzU5NTlaMGMxCzAJBgNVBAYTAlVT
# MRcwFQYDVQQKEw5EaWdpQ2VydCwgSW5jLjE7MDkGA1UEAxMyRGlnaUNlcnQgVHJ1
# c3RlZCBHNCBSU0E0MDk2IFNIQTI1NiBUaW1lU3RhbXBpbmcgQ0EwggIiMA0GCSqG
# SIb3DQEBAQUAA4ICDwAwggIKAoICAQDGhjUGSbPBPXJJUVXHJQPE8pE3qZdRodbS
# g9GeTKJtoLDMg/la9hGhRBVCX6SI82j6ffOciQt/nR+eDzMfUBMLJnOWbfhXqAJ9
# /UO0hNoR8XOxs+4rgISKIhjf69o9xBd/qxkrPkLcZ47qUT3w1lbU5ygt69OxtXXn
# HwZljZQp09nsad/ZkIdGAHvbREGJ3HxqV3rwN3mfXazL6IRktFLydkf3YYMZ3V+0
# VAshaG43IbtArF+y3kp9zvU5EmfvDqVjbOSmxR3NNg1c1eYbqMFkdECnwHLFuk4f
# sbVYTXn+149zk6wsOeKlSNbwsDETqVcplicu9Yemj052FVUmcJgmf6AaRyBD40Nj
# gHt1biclkJg6OBGz9vae5jtb7IHeIhTZgirHkr+g3uM+onP65x9abJTyUpURK1h0
# QCirc0PO30qhHGs4xSnzyqqWc0Jon7ZGs506o9UD4L/wojzKQtwYSH8UNM/STKvv
# mz3+DrhkKvp1KCRB7UK/BZxmSVJQ9FHzNklNiyDSLFc1eSuo80VgvCONWPfcYd6T
# /jnA+bIwpUzX6ZhKWD7TA4j+s4/TXkt2ElGTyYwMO1uKIqjBJgj5FBASA31fI7tk
# 42PgpuE+9sJ0sj8eCXbsq11GdeJgo1gJASgADoRU7s7pXcheMBK9Rp6103a50g5r
# mQzSM7TNsQIDAQABo4IBXTCCAVkwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4E
# FgQUuhbZbU2FL3MpdpovdYxqII+eyG8wHwYDVR0jBBgwFoAU7NfjgtJxXWRM3y5n
# P+e6mK4cD08wDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMIMHcG
# CCsGAQUFBwEBBGswaTAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQu
# Y29tMEEGCCsGAQUFBzAChjVodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGln
# aUNlcnRUcnVzdGVkUm9vdEc0LmNydDBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8v
# Y3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRUcnVzdGVkUm9vdEc0LmNybDAgBgNV
# HSAEGTAXMAgGBmeBDAEEAjALBglghkgBhv1sBwEwDQYJKoZIhvcNAQELBQADggIB
# AH1ZjsCTtm+YqUQiAX5m1tghQuGwGC4QTRPPMFPOvxj7x1Bd4ksp+3CKDaopafxp
# wc8dB+k+YMjYC+VcW9dth/qEICU0MWfNthKWb8RQTGIdDAiCqBa9qVbPFXONASIl
# zpVpP0d3+3J0FNf/q0+KLHqrhc1DX+1gtqpPkWaeLJ7giqzl/Yy8ZCaHbJK9nXzQ
# cAp876i8dU+6WvepELJd6f8oVInw1YpxdmXazPByoyP6wCeCRK6ZJxurJB4mwbfe
# Kuv2nrF5mYGjVoarCkXJ38SNoOeY+/umnXKvxMfBwWpx2cYTgAnEtp/Nh4cku0+j
# Sbl3ZpHxcpzpSwJSpzd+k1OsOx0ISQ+UzTl63f8lY5knLD0/a6fxZsNBzU+2QJsh
# IUDQtxMkzdwdeDrknq3lNHGS1yZr5Dhzq6YBT70/O3itTK37xJV77QpfMzmHQXh6
# OOmc4d0j/R0o08f56PGYX/sr2H7yRp11LB4nLCbbbxV7HhmLNriT1ObyF5lZynDw
# N7+YAN8gFk8n+2BnFqFmut1VwDophrCYoCvtlUG3OtUVmDG0YgkPCr2B2RP+v6TR
# 81fZvAT6gt4y3wSJ8ADNXcL50CN/AAvkdgIm2fBldkKmKYcJRyvmfxqkhQ/8mJb2
# VVQrH4D6wPIOK+XW+6kvRBVK5xMOHds3OBqhK/bt1nz8MIIFjTCCBHWgAwIBAgIQ
# DpsYjvnQLefv21DiCEAYWjANBgkqhkiG9w0BAQwFADBlMQswCQYDVQQGEwJVUzEV
# MBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29t
# MSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcNMjIwODAx
# MDAwMDAwWhcNMzExMTA5MjM1OTU5WjBiMQswCQYDVQQGEwJVUzEVMBMGA1UEChMM
# RGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSEwHwYDVQQD
# ExhEaWdpQ2VydCBUcnVzdGVkIFJvb3QgRzQwggIiMA0GCSqGSIb3DQEBAQUAA4IC
# DwAwggIKAoICAQC/5pBzaN675F1KPDAiMGkz7MKnJS7JIT3yithZwuEppz1Yq3aa
# za57G4QNxDAf8xukOBbrVsaXbR2rsnnyyhHS5F/WBTxSD1Ifxp4VpX6+n6lXFllV
# cq9ok3DCsrp1mWpzMpTREEQQLt+C8weE5nQ7bXHiLQwb7iDVySAdYyktzuxeTsiT
# +CFhmzTrBcZe7FsavOvJz82sNEBfsXpm7nfISKhmV1efVFiODCu3T6cw2Vbuyntd
# 463JT17lNecxy9qTXtyOj4DatpGYQJB5w3jHtrHEtWoYOAMQjdjUN6QuBX2I9YI+
# EJFwq1WCQTLX2wRzKm6RAXwhTNS8rhsDdV14Ztk6MUSaM0C/CNdaSaTC5qmgZ92k
# J7yhTzm1EVgX9yRcRo9k98FpiHaYdj1ZXUJ2h4mXaXpI8OCiEhtmmnTK3kse5w5j
# rubU75KSOp493ADkRSWJtppEGSt+wJS00mFt6zPZxd9LBADMfRyVw4/3IbKyEbe7
# f/LVjHAsQWCqsWMYRJUadmJ+9oCw++hkpjPRiQfhvbfmQ6QYuKZ3AeEPlAwhHbJU
# KSWJbOUOUlFHdL4mrLZBdd56rF+NP8m800ERElvlEFDrMcXKchYiCd98THU/Y+wh
# X8QgUWtvsauGi0/C1kVfnSD8oR7FwI+isX4KJpn15GkvmB0t9dmpsh3lGwIDAQAB
# o4IBOjCCATYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQU7NfjgtJxXWRM3y5n
# P+e6mK4cD08wHwYDVR0jBBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wDgYDVR0P
# AQH/BAQDAgGGMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDovL29j
# c3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MEUGA1UdHwQ+MDww
# OqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJ
# RFJvb3RDQS5jcmwwEQYDVR0gBAowCDAGBgRVHSAAMA0GCSqGSIb3DQEBDAUAA4IB
# AQBwoL9DXFXnOF+go3QbPbYW1/e/Vwe9mqyhhyzshV6pGrsi+IcaaVQi7aSId229
# GhT0E0p6Ly23OO/0/4C5+KH38nLeJLxSA8hO0Cre+i1Wz/n096wwepqLsl7Uz9FD
# RJtDIeuWcqFItJnLnU+nBgMTdydE1Od/6Fmo8L8vC6bp8jQ87PcDx4eo0kxAGTVG
# amlUsLihVo7spNU96LHc/RzY9HdaXFSMb++hUD38dglohJ9vytsgjTVgHAIDyyCw
# rFigDkBjxZgiwbJZ9VVrzyerbHbObyMt9H5xaiNrIv8SuFQtJ37YOtnwtoeW/VvR
# XKwYw02fc7cBqZ9Xql4o4rmUMYIDdjCCA3ICAQEwdzBjMQswCQYDVQQGEwJVUzEX
# MBUGA1UEChMORGlnaUNlcnQsIEluYy4xOzA5BgNVBAMTMkRpZ2lDZXJ0IFRydXN0
# ZWQgRzQgUlNBNDA5NiBTSEEyNTYgVGltZVN0YW1waW5nIENBAhALrma8Wrp/lYfG
# +ekE4zMEMA0GCWCGSAFlAwQCAQUAoIHRMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0B
# CRABBDAcBgkqhkiG9w0BCQUxDxcNMjQxMjA0MDQzNzUwWjArBgsqhkiG9w0BCRAC
# DDEcMBowGDAWBBTb04XuYtvSPnvk9nFIUIck1YZbRTAvBgkqhkiG9w0BCQQxIgQg
# AElAlvkZX+PUe8sAzZ5ooYNzsxBJB+7yYNefc6flhTEwNwYLKoZIhvcNAQkQAi8x
# KDAmMCQwIgQgdnafqPJjLx9DCzojMK7WVnX+13PbBdZluQWTmEOPmtswDQYJKoZI
# hvcNAQEBBQAEggIABpDfBiBg1Sh9a7y6CZn3qgLnWbcTTPXv0gF7SFX8Rre2eduS
# hF/Owx6xsIJUtwHgSvOy9kvWdekHcdpx6kVbmmtCK7pRkbLzlrfs+EXX1Otqnxjg
# RBKSncOLLgr83CWz+LYb987i7RWN4RV1aVZ4mL9UFjCVGiBgCR1HY8XUf71IHuJ3
# /Fbc6c99LH0g0NNa20965wcaXpuxG6HywCO0TSdVuNnirYqqjaEf++YPJ7iUDiRb
# eXMC5etiA38BOZXHUvmMX9//0LbNFemQOvXXO0ZtPao0hTaUEUjr4ubuTvN/c9vF
# nxn17NJ3J5fSa85ZIHwBAoT7cwbYHvmUjv2yjL3tRSfE3NKM9J0p18ZxiY1ooa+5
# jZ9GAUzDvG1hZf3wupnzBvBfwmpj059xvpoCSMthYIDgBT66w4reJ1s2hhCPy9t4
# byMpnGTxbuU554MqEprBDXWYhP6WkYg2RguHdvBEMzrqsm0GhfV5C7f0cFPE1nlH
# 4X4YuHPiuNEeXo89+IuYKGZmUruTqehLy/1vPfrNs9TPaARwjUsoAJ9bCXjl3IXW
# JPwvNXPniX5k2nBZCrycnboKY7BDSFhnitzncpXtZiOi3b0/vp0y4c3ghLl9+DAJ
# P5Gln8AQTrq6CDFWkdxg3Sy1XOnGgYoMdHoShy6JNegMTuIA0sJizqWaB9M=
# SIG # End signature block
