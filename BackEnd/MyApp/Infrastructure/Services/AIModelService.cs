using System.Net.Http.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using MyApp.Domain.Entities;
using MyApp.Persistence.Repositories;

namespace MyApp.Infrastructure.Services;

public class AIModelService
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _configuration;
    private readonly ModelRepository _modelRepository;
    private readonly ImageRepository _imageRepository;
    private readonly ILogger<AIModelService> _logger;

    public AIModelService(
        HttpClient httpClient,
        IConfiguration configuration,
        ModelRepository modelRepository,
        ImageRepository imageRepository,
        ILogger<AIModelService> logger)
    {
        _httpClient = httpClient;
        _configuration = configuration;
        _modelRepository = modelRepository;
        _imageRepository = imageRepository;
        _logger = logger;
    }

    public async Task<Prediction> PredictAsync(int uploadId)
    {
        // Lay thong tin anh va model
        var upload = await GetUploadOrThrow(uploadId);
        var model = await GetLatestModelOrThrow();

        // Goi AI model de predict
        var result = await CallAIModel(upload.FilePath, model.Version);

        // Luu ket qua vao database
        return await SavePrediction(uploadId, model.ModelVersionId, result);
    }

    // Lay thong tin upload tu database
    private async Task<ImageUpload> GetUploadOrThrow(int uploadId)
    {
        var upload = await _imageRepository.GetImageUploadByIdAsync(uploadId);
        if (upload == null)
            throw new Exception($"Upload {uploadId} not found");
        return upload;
    }

    // Lay model version moi nhat
    private async Task<ModelVersion> GetLatestModelOrThrow()
    {
        var model = await _modelRepository.GetLatestActiveModelAsync();
        if (model == null)
            throw new Exception("No active model found");

        _logger.LogInformation("Using model: {Model} v{Version}", model.ModelName, model.Version);
        return model;
    }

    // Goi AI model o server khac
    private async Task<AIResponse> CallAIModel(string imagePath, string modelVersion)
    {
        var modelUrl = _configuration["AIModel:Url"];
        var useMock = string.IsNullOrEmpty(modelUrl) || _configuration["AIModel:UseMock"] == "true";

        if (useMock)
        {
            _logger.LogWarning("Using MOCK data - Model URL not configured");
            return GenerateMockResult();
        }

        try
        {
            _logger.LogInformation("Calling AI model at {Url}", modelUrl);

            var response = await _httpClient.PostAsJsonAsync(modelUrl, new
            {
                imagePath,
                modelVersion
            });

            response.EnsureSuccessStatusCode();
            var result = await response.Content.ReadFromJsonAsync<AIResponse>();

            if (result == null)
                throw new Exception("Empty response from AI model");

            _logger.LogInformation("AI model responded: {Class} ({Confidence})",
                result.PredictedClass, result.ConfidenceScore);

            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error calling AI model, using mock data");
            return GenerateMockResult();
        }
    }

    // Luu ket qua prediction vao database
    private async Task<Prediction> SavePrediction(int uploadId, int modelVersionId, AIResponse result)
    {
        var prediction = new Prediction
        {
            UploadId = uploadId,
            ModelVersionId = modelVersionId,
            TreeId = result.TreeId,
            IllnessId = result.IllnessId,
            PredictedClass = result.PredictedClass,
            ConfidenceScore = result.ConfidenceScore,
            TopNPredictions = System.Text.Json.JsonSerializer.Serialize(result.TopPredictions),
            ProcessingTimeMs = result.ProcessingTimeMs,
            CreatedAt = DateTime.UtcNow
        };

        return await _imageRepository.CreatePredictionAsync(prediction);
    }

    // Mock data tam thoi khi chua co model that
    private static AIResponse GenerateMockResult()
    {
        var random = new Random();
        var diseases = new[]
        {
            new { TreeId = 1, IllnessId = 1, Class = "Rice_Blast" },
            new { TreeId = 1, IllnessId = 2, Class = "Brown_Spot" },
            new { TreeId = 2, IllnessId = 3, Class = "Corn_Rust" }
        };

        var selected = diseases[random.Next(diseases.Length)];
        var confidence = (decimal)(0.7 + random.NextDouble() * 0.25);

        return new AIResponse
        {
            TreeId = selected.TreeId,
            IllnessId = selected.IllnessId,
            PredictedClass = selected.Class,
            ConfidenceScore = Math.Round(confidence, 4),
            TopPredictions = new List<TopPrediction>
            {
                new() { ClassName = selected.Class, Confidence = Math.Round(confidence, 4) },
                new() { ClassName = "Healthy", Confidence = Math.Round(1 - confidence, 4) }
            },
            ProcessingTimeMs = random.Next(300, 800)
        };
    }

    // Response format tu AI model server
    private class AIResponse
    {
        public int TreeId { get; set; }
        public int IllnessId { get; set; }
        public string PredictedClass { get; set; } = null!;
        public decimal ConfidenceScore { get; set; }
        public List<TopPrediction> TopPredictions { get; set; } = new();
        public int ProcessingTimeMs { get; set; }
    }

    private class TopPrediction
    {
        public string ClassName { get; set; } = null!;
        public decimal Confidence { get; set; }
    }
}
