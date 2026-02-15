using System.Text.Json;
using Microsoft.Extensions.Logging;
using MyApp.Application.Features.Predictions.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Persistence.Repositories;

namespace MyApp.Infrastructure.Services;

public class PredictionService : IPredictionService
{
    private readonly ImageRepository _imageRepository;
    private readonly IAIService _aiService;
    private readonly ILogger<PredictionService> _logger;

    public PredictionService(
        ImageRepository imageRepository,
        IAIService aiService,
        ILogger<PredictionService> logger)
    {
        _imageRepository = imageRepository;
        _aiService = aiService;
        _logger = logger;
    }

    public async Task<RunPredictionResponseDto> RunPredictionAsync(RunPredictionRequestDto request)
    {
        try
        {
            _logger.LogInformation("Running prediction for UploadId: {UploadId}", request.UploadId);

            // Ch?y inference qua AIService
            var inferenceRequest = new Application.Features.AI.DTOs.InferenceRequestDto
            {
                UploadId = request.UploadId,
                ModelVersionId = request.ModelVersionId,
                UsePreprocessedImage = request.UsePreprocessedImage
            };

            var inferenceResult = await _aiService.RunInferenceAsync(inferenceRequest);

            // L?y prediction v?a t?o ð? return response chu?n
            var prediction = await _imageRepository.GetPredictionByIdAsync(inferenceResult.PredictionId);
            
            if (prediction == null)
                throw new InvalidOperationException($"Prediction {inferenceResult.PredictionId} not found after creation");

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
            _logger.LogError(ex, "Error running prediction for UploadId: {UploadId}", request.UploadId);
            throw;
        }
    }

    public async Task<PredictionDetailDto?> GetPredictionByIdAsync(int predictionId)
    {
        try
        {
            var prediction = await _imageRepository.GetPredictionByIdAsync(predictionId);
            
            if (prediction == null)
                return null;

            // Parse TopNPredictions JSON
            List<TopPredictionDto> topPredictions = new();
            if (!string.IsNullOrEmpty(prediction.TopNPredictions))
            {
                try
                {
                    var jsonPredictions = JsonSerializer.Deserialize<List<Application.Features.AI.DTOs.PredictionResult>>(prediction.TopNPredictions);
                    if (jsonPredictions != null)
                    {
                        topPredictions = jsonPredictions.Select(p => new TopPredictionDto
                        {
                            Class = p.ClassName,
                            Score = p.Confidence
                        }).ToList();
                    }
                }
                catch (JsonException ex)
                {
                    _logger.LogWarning(ex, "Failed to parse TopNPredictions JSON for PredictionId: {PredictionId}", predictionId);
                }
            }

            return new PredictionDetailDto
            {
                PredictionId = prediction.PredictionId,
                PredictedClass = prediction.PredictedClass ?? "Unknown",
                ConfidenceScore = prediction.ConfidenceScore ?? 0,
                TopNPredictions = topPredictions,
                ProcessingTimeMs = prediction.ProcessingTimeMs ?? 0,
                CreatedAt = prediction.CreatedAt ?? DateTime.UtcNow,
                Tree = prediction.Tree != null ? new TreeInfoDto
                {
                    TreeId = prediction.Tree.TreeId,
                    TreeName = prediction.Tree.TreeName
                } : null,
                Illness = prediction.Illness != null ? new IllnessInfoDto
                {
                    IllnessId = prediction.Illness.IllnessId,
                    IllnessName = prediction.Illness.IllnessName ?? "Unknown"
                } : null,
                Model = prediction.ModelVersion != null ? new ModelInfoDto
                {
                    ModelVersionId = prediction.ModelVersion.ModelVersionId,
                    ModelName = prediction.ModelVersion.ModelName,
                    Version = prediction.ModelVersion.Version
                } : null
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting prediction by ID: {PredictionId}", predictionId);
            throw;
        }
    }

    public async Task<List<PredictionHistoryDto>> GetPredictionHistoryAsync(int? userId = null, DateTime? fromDate = null, DateTime? toDate = null)
    {
        try
        {
            var predictions = await _imageRepository.GetPredictionHistoryAsync(userId, fromDate, toDate);

            return predictions.Select(p => new PredictionHistoryDto
            {
                PredictionId = p.PredictionId,
                TreeName = p.Tree?.TreeName ?? "Unknown",
                IllnessName = p.Illness?.IllnessName ?? "Unknown",
                ConfidenceScore = p.ConfidenceScore ?? 0,
                CreatedAt = p.CreatedAt ?? DateTime.UtcNow,
                ImagePath = p.Upload?.FilePath,
                ModelName = p.ModelVersion != null ? $"{p.ModelVersion.ModelName} {p.ModelVersion.Version}" : null
            }).ToList();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting prediction history");
            throw;
        }
    }
}
