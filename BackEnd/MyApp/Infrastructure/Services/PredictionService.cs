using System.Text.Json;
using Microsoft.Extensions.Logging;
using MyApp.Application.Features.Predictions.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Infrastructure.Services;
using MyApp.Persistence.Repositories;

namespace MyApp.Infrastructure.Services;

public class PredictionService : IPredictionService
{
    private readonly AIModelService _aiModelService;
    private readonly ImageRepository _imageRepository;
    private readonly ILogger<PredictionService> _logger;

    public PredictionService(
        AIModelService aiModelService,
        ImageRepository imageRepository,
        ILogger<PredictionService> logger)
    {
        _aiModelService = aiModelService;
        _imageRepository = imageRepository;
        _logger = logger;
    }

    public async Task<RunPredictionResponseDto> RunPredictionAsync(RunPredictionRequestDto request)
    {
        try
        {
            // G?i AI model ? t? ð?ng l?y version m?i nh?t
            var prediction = await _aiModelService.PredictAsync(request.UploadId);

            return new RunPredictionResponseDto
            {
                PredictionId = prediction.PredictionId,
                Tree = new TreeInfoDto
                {
                    TreeId = prediction.Tree?.TreeId ?? 0,
                    TreeName = prediction.Tree?.TreeName ?? "Unknown"
                },
                Illness = new IllnessInfoDto
                {
                    IllnessId = prediction.Illness?.IllnessId ?? 0,
                    IllnessName = prediction.Illness?.IllnessName ?? "Unknown"
                },
                ConfidenceScore = prediction.ConfidenceScore ?? 0,
                ProcessingTimeMs = prediction.ProcessingTimeMs ?? 0,
                CreatedAt = prediction.CreatedAt ?? DateTime.UtcNow
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error running prediction");
            throw;
        }
    }

    public async Task<PredictionDetailDto?> GetPredictionByIdAsync(int predictionId)
    {
        var prediction = await _imageRepository.GetPredictionByIdAsync(predictionId);
        if (prediction == null) return null;

        List<TopPredictionDto> topPredictions = new();
        if (!string.IsNullOrEmpty(prediction.TopNPredictions))
        {
            try
            {
                var parsed = JsonSerializer.Deserialize<List<Dictionary<string, object>>>(prediction.TopNPredictions);
                topPredictions = parsed?.Select(p => new TopPredictionDto
                {
                    Class = p.ContainsKey("className") ? p["className"].ToString() ?? "" : "",
                    Score = p.ContainsKey("confidence") ? Convert.ToDecimal(p["confidence"]) : 0
                }).ToList() ?? new();
            }
            catch { }
        }

        return new PredictionDetailDto
        {
            PredictionId = prediction.PredictionId,
            PredictedClass = prediction.PredictedClass ?? "",
            ConfidenceScore = prediction.ConfidenceScore ?? 0,
            TopNPredictions = topPredictions,
            ProcessingTimeMs = prediction.ProcessingTimeMs ?? 0,
            CreatedAt = prediction.CreatedAt ?? DateTime.UtcNow,
            Tree = prediction.Tree != null ? new TreeInfoDto { TreeId = prediction.Tree.TreeId, TreeName = prediction.Tree.TreeName } : null,
            Illness = prediction.Illness != null ? new IllnessInfoDto { IllnessId = prediction.Illness.IllnessId, IllnessName = prediction.Illness.IllnessName ?? "" } : null,
            Model = prediction.ModelVersion != null ? new ModelInfoDto { ModelVersionId = prediction.ModelVersion.ModelVersionId, ModelName = prediction.ModelVersion.ModelName, Version = prediction.ModelVersion.Version } : null
        };
    }

    public async Task<List<PredictionHistoryDto>> GetPredictionHistoryAsync(int? userId = null, DateTime? fromDate = null, DateTime? toDate = null)
    {
        var predictions = await _imageRepository.GetPredictionHistoryAsync(userId, fromDate, toDate);
        return predictions.Select(p => new PredictionHistoryDto
        {
            PredictionId = p.PredictionId,
            TreeName = p.Tree?.TreeName ?? "",
            IllnessName = p.Illness?.IllnessName ?? "",
            ConfidenceScore = p.ConfidenceScore ?? 0,
            CreatedAt = p.CreatedAt ?? DateTime.UtcNow,
            ImagePath = p.Upload?.FilePath,
            ModelName = p.ModelVersion != null ? $"{p.ModelVersion.ModelName} {p.ModelVersion.Version}" : null
        }).ToList();
    }
}
