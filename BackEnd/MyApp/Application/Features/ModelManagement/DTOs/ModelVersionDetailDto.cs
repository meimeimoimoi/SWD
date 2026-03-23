namespace MyApp.Application.Features.ModelManagement.DTOs;

public sealed class PredictedClassCountDto
{
    public string ClassName { get; set; } = "";
    public int Count { get; set; }
}

public sealed class ModelVersionUsageMetricsDto
{
    public int TotalPredictions { get; set; }
    public int PredictionsToday { get; set; }
    public int PredictionsLast7Days { get; set; }
    public double AverageConfidence { get; set; }
    public int TotalRatings { get; set; }
    public int PositiveRatings { get; set; }
    public double PositiveRatingRate { get; set; }
    public List<PredictedClassCountDto> TopPredictedClasses { get; set; } = new();
}

/// <summary>
/// Full admin view of a model: registry fields, disk file, ONNX IO metadata, usage, inference runtime.
/// </summary>
public sealed class ModelVersionDetailDto
{
    public int ModelVersionId { get; set; }
    public string ModelName { get; set; } = "";
    public string Version { get; set; } = "";
    public string? ModelType { get; set; }
    public string? Description { get; set; }
    public bool? IsActive { get; set; }
    public bool? IsDefault { get; set; }
    public DateTime? CreatedAt { get; set; }
    public string? RelativeFilePath { get; set; }

    public int TotalPredictions { get; set; }
    public int PredictionsToday { get; set; }
    public int PredictionsLast7Days { get; set; }
    public double AverageConfidence { get; set; }
    public int TotalRatings { get; set; }
    public int PositiveRatings { get; set; }
    public double PositiveRatingRate { get; set; }
    public List<PredictedClassCountDto> TopPredictedClasses { get; set; } = new();

    public bool FileExists { get; set; }
    public string? AbsolutePath { get; set; }
    public long? FileSizeBytes { get; set; }
    public DateTime? FileLastModifiedUtc { get; set; }

    public string? OnnxProducerName { get; set; }
    public string? OnnxGraphName { get; set; }
    public string? OnnxDomain { get; set; }
    public long? OnnxModelVersion { get; set; }
    public List<string> OnnxInputNames { get; set; } = new();
    public List<string> OnnxOutputNames { get; set; } = new();
    public Dictionary<string, string> OnnxInputShapeDescriptions { get; set; } = new();
    public Dictionary<string, string> OnnxOutputShapeDescriptions { get; set; } = new();
    public int? OnnxClassLabelCount { get; set; }
    public List<string> OnnxClassLabelsSample { get; set; } = new();
    public string? OnnxMetadataError { get; set; }
    public string? OnnxClassLabelsError { get; set; }

    public bool IsCurrentInferenceModel { get; set; }
    public int? CurrentlyLoadedModelVersionId { get; set; }
}
