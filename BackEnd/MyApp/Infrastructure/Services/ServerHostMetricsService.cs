using System.Diagnostics;
using System.Runtime.InteropServices;
using MyApp.Application.Features.Admin.DTOs;
using MyApp.Application.Interfaces;
using Microsoft.Extensions.Hosting;

namespace MyApp.Infrastructure.Services;

public sealed class ServerHostMetricsService : IServerHostMetricsService
{
    private readonly IHostEnvironment _hostEnvironment;

    public ServerHostMetricsService(IHostEnvironment hostEnvironment)
    {
        _hostEnvironment = hostEnvironment;
    }

    public Task<ServerHostStatusSimpleDto> GetSimpleAsync(CancellationToken cancellationToken = default)
    {
        cancellationToken.ThrowIfCancellationRequested();
        var snapshot = CaptureProcessAndMachine();
        return Task.FromResult(new ServerHostStatusSimpleDto(
            snapshot.CapturedAtUtc,
            snapshot.MachineName,
            snapshot.ProcessorCount,
            snapshot.ProcessUptimeSeconds,
            snapshot.ProcessWorkingSetMb,
            snapshot.ProcessPrivateMemoryMb,
            snapshot.MachineTotalMemoryMb,
            snapshot.MachineAvailableMemoryMb,
            snapshot.MachineMemoryUsedPercent,
            snapshot.DotNetVersion,
            _hostEnvironment.EnvironmentName,
            snapshot.ApplicationName));
    }

    public async Task<ServerHostStatusDetailDto> GetDetailAsync(CancellationToken cancellationToken = default)
    {
        var snapshot = CaptureProcessAndMachine();
        var cpu = await SampleProcessCpuPercentAsync(cancellationToken).ConfigureAwait(false);
        var proc = Process.GetCurrentProcess();
        proc.Refresh();
        var gc = GC.GetGCMemoryInfo();

        return new ServerHostStatusDetailDto(
            snapshot.CapturedAtUtc,
            snapshot.MachineName,
            snapshot.ProcessorCount,
            snapshot.ProcessUptimeSeconds,
            snapshot.ProcessWorkingSetMb,
            snapshot.ProcessPrivateMemoryMb,
            snapshot.MachineTotalMemoryMb,
            snapshot.MachineAvailableMemoryMb,
            snapshot.MachineMemoryUsedPercent,
            snapshot.DotNetVersion,
            _hostEnvironment.EnvironmentName,
            snapshot.ApplicationName,
            proc.Id,
            RuntimeInformation.OSDescription,
            proc.Threads.Count,
            proc.HandleCount,
            GC.GetTotalMemory(false),
            gc.HeapSizeBytes,
            gc.HighMemoryLoadThresholdBytes,
            GC.CollectionCount(0),
            GC.CollectionCount(1),
            GC.CollectionCount(2),
            proc.StartTime.ToUniversalTime(),
            cpu);
    }

    private static async Task<double?> SampleProcessCpuPercentAsync(CancellationToken cancellationToken)
    {
        var proc = Process.GetCurrentProcess();
        var cpu1 = proc.TotalProcessorTime;
        var sw = Stopwatch.StartNew();
        try
        {
            await Task.Delay(120, cancellationToken).ConfigureAwait(false);
        }
        catch (OperationCanceledException)
        {
            return null;
        }

        proc.Refresh();
        var cpu2 = proc.TotalProcessorTime;
        sw.Stop();
        var wallMs = sw.Elapsed.TotalMilliseconds;
        if (wallMs < 1)
        {
            return null;
        }

        var usedMs = (cpu2 - cpu1).TotalMilliseconds;
        var logical = Math.Max(1, Environment.ProcessorCount);
        var pct = usedMs / (wallMs * logical) * 100.0;
        return Math.Clamp(pct, 0, 100);
    }

    private static Snapshot CaptureProcessAndMachine()
    {
        var proc = Process.GetCurrentProcess();
        proc.Refresh();
        var now = DateTime.UtcNow;
        var uptime = (now - proc.StartTime.ToUniversalTime()).TotalSeconds;
        var (totalMb, availMb, usedPct) = TryGetMachineMemoryMb();

        double? memUsedPct = usedPct;
        if (memUsedPct == null && totalMb is > 0 && availMb != null)
        {
            memUsedPct = (1.0 - availMb.Value / totalMb.Value) * 100.0;
        }

        return new Snapshot(
            now,
            Environment.MachineName,
            Environment.ProcessorCount,
            Math.Max(0, uptime),
            proc.WorkingSet64 / 1024.0 / 1024.0,
            proc.PrivateMemorySize64 / 1024.0 / 1024.0,
            totalMb,
            availMb,
            memUsedPct,
            Environment.Version.ToString(),
            AppDomain.CurrentDomain.FriendlyName);
    }

    private static (double? TotalMb, double? AvailableMb, double? UsedPercent) TryGetMachineMemoryMb()
    {
        if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
        {
            return TryReadLinuxMemInfo();
        }

        if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
        {
            return TryReadWindowsMemory();
        }

        return (null, null, null);
    }

    private static (double? TotalMb, double? AvailableMb, double? UsedPercent) TryReadLinuxMemInfo()
    {
        try
        {
            var path = "/proc/meminfo";
            if (!File.Exists(path))
            {
                return (null, null, null);
            }

            double? memTotalKb = null;
            double? memAvailKb = null;
            foreach (var line in File.ReadLines(path))
            {
                if (line.StartsWith("MemTotal:", StringComparison.Ordinal))
                {
                    memTotalKb = ParseMeminfoKb(line);
                }
                else if (line.StartsWith("MemAvailable:", StringComparison.Ordinal))
                {
                    memAvailKb = ParseMeminfoKb(line);
                }

                if (memTotalKb != null && memAvailKb != null)
                {
                    break;
                }
            }

            if (memTotalKb is not > 0)
            {
                return (null, null, null);
            }

            var totalMb = memTotalKb.Value / 1024.0;
            var availMb = memAvailKb / 1024.0;
            var usedPct = memAvailKb != null
                ? (1.0 - memAvailKb.Value / memTotalKb.Value) * 100.0
                : (double?)null;
            return (totalMb, availMb, usedPct);
        }
        catch
        {
            return (null, null, null);
        }
    }

    private static double? ParseMeminfoKb(string line)
    {
        var parts = line.Split(' ', StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length < 2)
        {
            return null;
        }

        return double.TryParse(parts[1], out var kb) ? kb : null;
    }

    private static (double? TotalMb, double? AvailableMb, double? UsedPercent) TryReadWindowsMemory()
    {
        try
        {
            var stat = new MemoryStatusEx { Length = (uint)Marshal.SizeOf<MemoryStatusEx>() };
            if (!GlobalMemoryStatusEx(ref stat))
            {
                return (null, null, null);
            }

            var totalMb = stat.TotalPhys / 1024.0 / 1024.0;
            var availMb = stat.AvailPhys / 1024.0 / 1024.0;
            var usedPct = stat.TotalPhys > 0
                ? (1.0 - (double)stat.AvailPhys / stat.TotalPhys) * 100.0
                : (double?)null;
            return (totalMb, availMb, usedPct);
        }
        catch
        {
            return (null, null, null);
        }
    }

    private readonly record struct Snapshot(
        DateTime CapturedAtUtc,
        string MachineName,
        int ProcessorCount,
        double ProcessUptimeSeconds,
        double ProcessWorkingSetMb,
        double ProcessPrivateMemoryMb,
        double? MachineTotalMemoryMb,
        double? MachineAvailableMemoryMb,
        double? MachineMemoryUsedPercent,
        string DotNetVersion,
        string ApplicationName);

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    private struct MemoryStatusEx
    {
        public uint Length;
        public uint MemoryLoad;
        public ulong TotalPhys;
        public ulong AvailPhys;
        public ulong TotalPageFile;
        public ulong AvailPageFile;
        public ulong TotalVirtual;
        public ulong AvailVirtual;
        public ulong AvailExtendedVirtual;
    }

    [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    private static extern bool GlobalMemoryStatusEx(ref MemoryStatusEx lpBuffer);
}
