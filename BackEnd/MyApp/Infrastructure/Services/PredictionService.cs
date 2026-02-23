using MyApp.Application.Features.Predictions.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Persistence.Context;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;

namespace MyApp.Infrastructure.Services;

public class PredictionService : IPredictionService
{
    private readonly AppDbContext _context;
    private readonly HttpClient _httpClient;
    private readonly string _aiServiceUrl;

    public PredictionService(AppDbContext context, IHttpClientFactory httpClientFactory, IConfiguration configuration)
    {
        _context = context;
        _httpClient = httpClientFactory.CreateClient();
        _aiServiceUrl = configuration["AiService:Url"] ?? throw new Exception("AI Service URL not configured");
    }

    public async Task<PredictionResponseDto> RunPredictionAsync(PredictionRequestDto request)
    {
        var startTime = DateTime.UtcNow;

        // Get image upload
        var upload = await _context.ImageUploads.FindAsync(request.UploadId)
            ?? throw new Exception("Image not found");

        // Get default active model
        var model = await _context.ModelVersions
            .FirstOrDefaultAsync(m => m.IsDefault == true && m.IsActive == true)
            ?? throw new Exception("No active default model found");

        // Call AI service
        var aiResponse = await CallAiServiceAsync(upload.FilePath!, model.ModelVersionId);
        
        var processingTime = (int)(DateTime.UtcNow - startTime).TotalMilliseconds;

        // Get illness from predicted class
        var illness = await _context.TreeIllnesses
            .FirstOrDefaultAsync(i => i.ScientificName == aiResponse.PredictedClass || i.IllnessName == aiResponse.PredictedClass);

        // Get tree
        var tree = await _context.Trees.FirstOrDefaultAsync();

        // Save prediction
        var prediction = new Domain.Entities.Prediction
        {
            UploadId = request.UploadId,
            ModelVersionId = model.ModelVersionId,
            TreeId = tree?.TreeId,
            IllnessId = illness?.IllnessId,
            PredictedClass = aiResponse.PredictedClass,
            ConfidenceScore = aiResponse.ConfidenceScore,
            TopNPredictions = JsonSerializer.Serialize(aiResponse.TopNPredictions),
            ProcessingTimeMs = processingTime,
            CreatedAt = DateTime.UtcNow
        };

        _context.Predictions.Add(prediction);
        await _context.SaveChangesAsync();

        return new PredictionResponseDto
        {
            PredictionId = prediction.PredictionId,
            Tree = new TreeDto { TreeId = tree?.TreeId ?? 0, TreeName = tree?.TreeName ?? "Unknown" },
            Illness = new IllnessDto { IllnessId = illness?.IllnessId ?? 0, IllnessName = illness?.IllnessName ?? "Unknown" },
            ConfidenceScore = aiResponse.ConfidenceScore,
            ProcessingTimeMs = processingTime,
            CreatedAt = prediction.CreatedAt.Value
        };
    }

    public async Task<PredictionDetailDto?> GetPredictionByIdAsync(int id)
    {
        var prediction = await _context.Predictions
            .Include(p => p.Illness)
            .Include(p => p.Tree)
            .FirstOrDefaultAsync(p => p.PredictionId == id);

        if (prediction == null) return null;

        var topPredictions = string.IsNullOrEmpty(prediction.TopNPredictions)
            ? new List<TopPredictionDto>()
            : JsonSerializer.Deserialize<List<TopPredictionDto>>(prediction.TopNPredictions) ?? new List<TopPredictionDto>();

        return new PredictionDetailDto
        {
            PredictionId = prediction.PredictionId,
            PredictedClass = prediction.PredictedClass ?? "",
            ConfidenceScore = prediction.ConfidenceScore ?? 0,
            TopNPredictions = topPredictions
        };
    }

    public async Task<List<PredictionHistoryDto>> GetPredictionHistoryAsync()
    {
        return await _context.Predictions
            .Include(p => p.Tree)
            .Include(p => p.Illness)
            .OrderByDescending(p => p.CreatedAt)
            .Select(p => new PredictionHistoryDto
            {
                PredictionId = p.PredictionId,
                TreeName = p.Tree != null ? p.Tree.TreeName! : "Unknown",
                IllnessName = p.Illness != null ? p.Illness.IllnessName! : "Unknown",
                ConfidenceScore = p.ConfidenceScore ?? 0,
                CreatedAt = p.CreatedAt ?? DateTime.UtcNow
            })
            .ToListAsync();
    }

    private async Task<AiPredictionResult> CallAiServiceAsync(string imagePath, int modelVersionId)
    {
        var formData = new MultipartFormDataContent();
        
        // Read image file
        var imageBytes = await File.ReadAllBytesAsync(imagePath);
        var imageContent = new ByteArrayContent(imageBytes);
        formData.Add(imageContent, "image", Path.GetFileName(imagePath));

        // Call AI service
        var response = await _httpClient.PostAsync($"{_aiServiceUrl}/predict", formData);
        response.EnsureSuccessStatusCode();

        var result = await response.Content.ReadFromJsonAsync<AiPredictionResult>()
            ?? throw new Exception("Invalid AI service response");

        return result;
    }

    private class AiPredictionResult
    {
        public string PredictedClass { get; set; } = null!;
        public decimal ConfidenceScore { get; set; }
        public List<TopPredictionDto> TopNPredictions { get; set; } = new();
    }
}
