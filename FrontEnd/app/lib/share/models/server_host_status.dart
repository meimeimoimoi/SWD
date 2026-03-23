class ServerHostStatusSimple {
  final DateTime? capturedAtUtc;
  final String machineName;
  final int processorCount;
  final double processUptimeSeconds;
  final double processWorkingSetMb;
  final double processPrivateMemoryMb;
  final double? machineTotalMemoryMb;
  final double? machineAvailableMemoryMb;
  final double? machineMemoryUsedPercent;
  final String dotNetVersion;
  final String environmentName;
  final String applicationName;

  ServerHostStatusSimple({
    this.capturedAtUtc,
    required this.machineName,
    required this.processorCount,
    required this.processUptimeSeconds,
    required this.processWorkingSetMb,
    required this.processPrivateMemoryMb,
    this.machineTotalMemoryMb,
    this.machineAvailableMemoryMb,
    this.machineMemoryUsedPercent,
    required this.dotNetVersion,
    required this.environmentName,
    required this.applicationName,
  });

  factory ServerHostStatusSimple.fromJson(Map<String, dynamic> json) {
    return ServerHostStatusSimple(
      capturedAtUtc: json['capturedAtUtc'] != null
          ? DateTime.tryParse(json['capturedAtUtc'].toString())
          : null,
      machineName: json['machineName']?.toString() ?? '—',
      processorCount: (json['processorCount'] as num?)?.toInt() ?? 0,
      processUptimeSeconds:
          (json['processUptimeSeconds'] as num?)?.toDouble() ?? 0,
      processWorkingSetMb:
          (json['processWorkingSetMb'] as num?)?.toDouble() ?? 0,
      processPrivateMemoryMb:
          (json['processPrivateMemoryMb'] as num?)?.toDouble() ?? 0,
      machineTotalMemoryMb:
          (json['machineTotalMemoryMb'] as num?)?.toDouble(),
      machineAvailableMemoryMb:
          (json['machineAvailableMemoryMb'] as num?)?.toDouble(),
      machineMemoryUsedPercent:
          (json['machineMemoryUsedPercent'] as num?)?.toDouble(),
      dotNetVersion: json['dotNetVersion']?.toString() ?? '—',
      environmentName: json['environmentName']?.toString() ?? '—',
      applicationName: json['applicationName']?.toString() ?? '—',
    );
  }
}

class ServerHostStatusDetail extends ServerHostStatusSimple {
  final int processId;
  final String osDescription;
  final int threadCount;
  final int handleCount;
  final int gcTotalMemoryBytes;
  final int gcHeapSizeBytes;
  final int gcHighMemoryLoadThresholdBytes;
  final int gcGen0Collections;
  final int gcGen1Collections;
  final int gcGen2Collections;
  final DateTime? processStartTimeUtc;
  final double? estimatedProcessCpuPercent;

  ServerHostStatusDetail({
    super.capturedAtUtc,
    required super.machineName,
    required super.processorCount,
    required super.processUptimeSeconds,
    required super.processWorkingSetMb,
    required super.processPrivateMemoryMb,
    super.machineTotalMemoryMb,
    super.machineAvailableMemoryMb,
    super.machineMemoryUsedPercent,
    required super.dotNetVersion,
    required super.environmentName,
    required super.applicationName,
    required this.processId,
    required this.osDescription,
    required this.threadCount,
    required this.handleCount,
    required this.gcTotalMemoryBytes,
    required this.gcHeapSizeBytes,
    required this.gcHighMemoryLoadThresholdBytes,
    required this.gcGen0Collections,
    required this.gcGen1Collections,
    required this.gcGen2Collections,
    this.processStartTimeUtc,
    this.estimatedProcessCpuPercent,
  });

  factory ServerHostStatusDetail.fromJson(Map<String, dynamic> json) {
    final base = ServerHostStatusSimple.fromJson(json);
    return ServerHostStatusDetail(
      capturedAtUtc: base.capturedAtUtc,
      machineName: base.machineName,
      processorCount: base.processorCount,
      processUptimeSeconds: base.processUptimeSeconds,
      processWorkingSetMb: base.processWorkingSetMb,
      processPrivateMemoryMb: base.processPrivateMemoryMb,
      machineTotalMemoryMb: base.machineTotalMemoryMb,
      machineAvailableMemoryMb: base.machineAvailableMemoryMb,
      machineMemoryUsedPercent: base.machineMemoryUsedPercent,
      dotNetVersion: base.dotNetVersion,
      environmentName: base.environmentName,
      applicationName: base.applicationName,
      processId: (json['processId'] as num?)?.toInt() ?? 0,
      osDescription: json['osDescription']?.toString() ?? '—',
      threadCount: (json['threadCount'] as num?)?.toInt() ?? 0,
      handleCount: (json['handleCount'] as num?)?.toInt() ?? 0,
      gcTotalMemoryBytes:
          (json['gcTotalMemoryBytes'] as num?)?.toInt() ?? 0,
      gcHeapSizeBytes: (json['gcHeapSizeBytes'] as num?)?.toInt() ?? 0,
      gcHighMemoryLoadThresholdBytes:
          (json['gcHighMemoryLoadThresholdBytes'] as num?)?.toInt() ?? 0,
      gcGen0Collections: (json['gcGen0Collections'] as num?)?.toInt() ?? 0,
      gcGen1Collections: (json['gcGen1Collections'] as num?)?.toInt() ?? 0,
      gcGen2Collections: (json['gcGen2Collections'] as num?)?.toInt() ?? 0,
      processStartTimeUtc: json['processStartTimeUtc'] != null
          ? DateTime.tryParse(json['processStartTimeUtc'].toString())
          : null,
      estimatedProcessCpuPercent:
          (json['estimatedProcessCpuPercent'] as num?)?.toDouble(),
    );
  }
}
