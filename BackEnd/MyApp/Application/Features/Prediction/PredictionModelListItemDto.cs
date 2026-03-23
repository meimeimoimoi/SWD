namespace MyApp.Application.Features.Prediction;

public sealed class PredictionModelListItemDto
{
    public int ModelVersionId { get; init; }
    public string ModelName { get; init; } = string.Empty;
    public string Version { get; init; } = string.Empty;
    public bool IsDefault { get; init; }
    public string? Description { get; init; }
}
