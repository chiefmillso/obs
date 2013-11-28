using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Web;
using Microsoft.SharePoint;
using Microsoft.SharePoint.Administration;
using System.Reflection;
using System.Diagnostics;
using System.Text.RegularExpressions;
using System.Web.Script.Serialization;

namespace OBS.Community.SolutionStatus
{
    [Guid("a2a3ca1e-5c37-45e4-b66f-acdff9c0c38d")]
    public class Handler : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            ProcessRequest(new HttpContextWrapper(context));
        }

        public void ProcessRequest(HttpContextBase context)
        {
            try
            {
                var response = context.Response;
                response.ContentType = "application/json";
                response.ContentEncoding = Encoding.UTF8;
                response.Cache.SetCacheability(HttpCacheability.NoCache);

                var result = new Result();

                string solutionId = GetSolutionId(context);
                bool isDownload = IsDownload(context);
                if (string.IsNullOrEmpty(solutionId))
                {
                    result.Error = true;
                    result.ErrorMessage = "Invalid SolutionId";
                }
                else
                {
                    try
                    {
                        if (isDownload)
                        {
                            DownloadFile(solutionId, file =>
                            {
                                response.ClearContent();
                                response.AddHeader("content-disposition", "attachment; filename="+solutionId);
                                response.WriteFile(file.FullName);
                                response.Flush();
                                context.ApplicationInstance.CompleteRequest();
                            });
                            return;
                        }
                        result = GetVersion(solutionId);
                    }
                    catch (Exception ex)
                    {
                        result.Error = true;
                        result.ErrorMessage = ex.Message;
                    }
                }
                response.Write(result.ToJson());
                response.Flush();
            }
            catch (Exception ex)
            {
                Debug.WriteLine(ex);
                throw;
            }
        }

        private static void DownloadFile(string solutionId, Action<FileInfo> process)
        {
            SPSolution solution = SPFarm.Local.Solutions[solutionId];

            var tempPath = Path.GetTempPath();
            var cabPath = Path.Combine(tempPath, solution.SolutionId.ToString().Replace("-", ""));
            var tempFile = Path.GetTempFileName();
            var target = Path.Combine(tempPath, tempFile);
            var fileInfo = new FileInfo(target);
            try
            {
                var solutionFile = solution.SolutionFile;
                solutionFile.SaveAs(target);
                fileInfo.Refresh();

                process(fileInfo);
            }
            finally
            {
                fileInfo.Refresh();
                if (fileInfo.Exists)
                    fileInfo.Delete();
            }
        }

        private static Result GetVersion(string solutionId)
        {
            SPSolution solution = SPFarm.Local.Solutions[solutionId];

            var version = GetVersionFromProperties(solution);
            if (!string.IsNullOrEmpty(version))
                return new Result() { Version = version };

            var tempPath = Path.GetTempPath();
            var cabPath = Path.Combine(tempPath, solution.SolutionId.ToString().Replace("-", ""));
            var tempFile = Path.GetTempFileName();
            var target = Path.Combine(tempPath, tempFile);
            var fileInfo = new FileInfo(target);
            try
            {
                var solutionFile = solution.SolutionFile;
                solutionFile.SaveAs(target);
                fileInfo.Refresh();
                var result = GetVersion(fileInfo, solutionId, cabPath);
                if (!string.IsNullOrEmpty(result.Version))
                    SetVersionProperties(solution, result.Version);
                return result;
            }
            finally
            {
                fileInfo.Refresh();
                if (fileInfo.Exists)
                    fileInfo.Delete();
            }
        }

        const string Key = "AssemblyFileVersion";

        private static void SetVersionProperties(SPSolution solution, string version)
        {
            var web = SPContext.Current.Web;
            try
            {
                web.AllowUnsafeUpdates = true;
                solution.Properties[Key] = string.Format("{0};{1}", solution.Version, version);
                solution.Update();
            }
            finally
            {
                web.AllowUnsafeUpdates = false;
            }
        }

        private static string GetVersionFromProperties(SPSolution solution)
        {
            var version = solution.Version.ToString();
            if (!solution.Properties.ContainsKey(Key))
                return string.Empty;
            var pair = solution.Properties[Key] as string;
            if (string.IsNullOrEmpty(pair))
                return string.Empty;
            var pieces = pair.Split(';');
            if (pieces[0] == version)
                return pieces[1];
            return string.Empty;
        }

        // Unsupported Code
        private static Result GetVersion(FileInfo file, string solutionId, string tempPath)
        {
            var directoryInfo = new DirectoryInfo(tempPath);
            if (!directoryInfo.Exists)
                directoryInfo.Create();

            try
            {
                var result = new Result();
                var farmType = typeof(SPFarm);
                var property = farmType.GetProperty("RequestNoAuth", BindingFlags.NonPublic | BindingFlags.Static);
                var request = property.GetValue(null, null);
                var requestType = request.GetType();
                var disposable = request as IDisposable;
                if (disposable != null)
                {
                    using (disposable)
                    {
                        var method = requestType.GetMethod("ExtractFilesFromCabinet");
                        string bstrTempDirectory = tempPath;
                        string bstrCabFileLocation = file.FullName;
                        var parameters = new object[] { bstrTempDirectory, bstrCabFileLocation };
                        method.Invoke(request, parameters);
                        var version = GetVersionNumber(directoryInfo, solutionId);
                        result.Version = version;
                    }
                }
                return result;
            }
            finally
            {
                directoryInfo.Delete(true);
            }
        }

        private static string GetVersionNumber(DirectoryInfo directoryInfo, string solutionId)
        {
            var versionFile = directoryInfo.GetFiles("version.txt", SearchOption.TopDirectoryOnly).FirstOrDefault();
            if (versionFile != null)
            {
                using (var reader = versionFile.OpenText())
                {
                    var line = reader.ReadToEnd();
                    if (!string.IsNullOrEmpty(line))
                    {
                        return line.Trim();
                    }
                }
            }

            var names = GetNames(solutionId);
            var gac = directoryInfo.GetDirectories("GAC", SearchOption.TopDirectoryOnly).FirstOrDefault();
            foreach (var name in names)
            {
                try
                {
                    var files = directoryInfo.GetFiles(name, SearchOption.TopDirectoryOnly);
                    if (gac != null && gac.Exists)
                        files = files.Union(gac.GetFiles(name, SearchOption.TopDirectoryOnly)).ToArray();
                    var assemblyFile = files.OrderByDescending(x => x.LastWriteTime).FirstOrDefault();
                    var version = GetVersionNumber(assemblyFile);
                    if (!string.IsNullOrEmpty(version))
                        return version;
                }
                catch (Exception ex)
                {
                    Debug.WriteLine("Swallow Exception: " + ex);
                }
            }

            return string.Empty;
        }

        private static IEnumerable<string> GetNames(string solutionId)
        {
            var fileName = Path.GetFileNameWithoutExtension(solutionId);

            if (string.IsNullOrEmpty(fileName))
                yield break;

            var parsed = Inflector.Inflector.Humanize(Inflector.Inflector.Underscore(Inflector.Inflector.Uncapitalize(fileName)));
            yield return parsed + ".dll";

            var alphaOnly = Regex.Replace(parsed, "([1-9])", "");
            yield return alphaOnly + ".dll";

            yield return "*.dll";
        }

        private static string GetVersionNumber(FileInfo assemblyFile)
        {
            if (assemblyFile != null)
            {
                var version = FileVersionInfo.GetVersionInfo(assemblyFile.FullName);
                return version.FileVersion;
            }
            return string.Empty;
        }

        private static string GetSolutionId(HttpContextBase context)
        {
            const string key = "solutionId";
            var queryString = context.Request.QueryString;
            return queryString[key];
        }

        private static bool IsDownload(HttpContextBase context)
        {
            const string key = "operation";
            var queryString = context.Request.QueryString;
            var value = queryString[key];
            bool result;
            if (bool.TryParse(value, out result))
                return result;
            return false;
        }

        public bool IsReusable
        {
            get { return true; }
        }

        public class Result
        {
            public string Version { get; set; }
            public string ErrorMessage { get; set; }
            public bool Error { get; set; }

            public string ToJson()
            {
                return new JavaScriptSerializer().Serialize(this);
            }
        }
    }
}