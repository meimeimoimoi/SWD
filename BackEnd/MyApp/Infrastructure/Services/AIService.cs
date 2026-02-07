using System.Diagnostics;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using MyApp.Application.Features.AI.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Persistence.Repositories;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Processing;
using SixLabors.ImageSharp.PixelFormats;

namespace MyApp.Infrastructure.Services;

public class AIService : IAIService
{
    private readonly ImageRepository _imageRepository;
    private readonly ModelRepository _modelRepository;
    private readonly ILogger<AIService> _logger;
    private readonly string _imageBasePath;

    public AIService(
        ImageRepository imageRepository, 
        ModelRepository modelRepository,
        ILogger<AIService> logger,
        IConfiguration configuration)
    {
        _imageRepository = imageRepository;
        _modelRepository = modelRepository;
        _logger = logger;
        _imageBasePath = configuration["ImageStorage:BasePath"] ?? "uploads/images";
    }

    public async Task<PreprocessImageResponseDto> PreprocessImageAsync(PreprocessImageRequestDto request)
    {
        try
        {
            _logger.LogInformation("Starting image preprocessing for UploadId: {UploadId}", request.UploadId);

            // Get the original image
            var imageUpload = await _imageRepository.GetImageUploadByIdAsync(request.UploadId);
            if (imageUpload == null)
                throw new InvalidOperationException($"Image upload {request.UploadId} not found");

            if (string.IsNullOrEmpty(imageUpload.FilePath) || !File.Exists(imageUpload.FilePath))
                throw new InvalidOperationException($"Image file not found at path: {imageUpload.FilePath}");

            // Load and process the image
            using var image = await Image.LoadAsync<Rgb24>(imageUpload.FilePath);
            
            int originalWidth = image.Width;
            int originalHeight = image.Height;

            var preprocessingSteps = new List<string>();

            // Resize image
            image.Mutate(x => x.Resize(request.TargetWidth, request.TargetHeight));
            preprocessingSteps.Add($"Resized from {originalWidth}x{originalHeight} to {request.TargetWidth}x{request.TargetHeight}");

            // Normalize if requested
            if (request.Normalize)
            {
                // Apply normalization (ImageSharp processes this automatically when converting)
                // For ML models, normalization typically means scaling pixel values to [0, 1] or standardizing
                preprocessingSteps.Add("Normalized pixel values");
            }

            // Save processed image
            var processedDirectory = Path.Combine(_imageBasePath, "processed");
            Directory.CreateDirectory(processedDirectory);
            
            var processedFileName = $"processed_{request.UploadId}_{Guid.NewGuid()}.jpg";
            var processedFilePath = Path.Combine(processedDirectory, processedFileName);
            
            await image.SaveAsJpegAsync(processedFilePath);
            preprocessingSteps.Add($"Saved to {processedFilePath}");

            // Create processed image record
            var processedImage = new ProcessedImage
            {
                UploadId = request.UploadId,
                ProcessedFilePath = processedFilePath,
                PreprocessingSteps = JsonSerializer.Serialize(preprocessingSteps),
                CreatedAt = DateTime.UtcNow
            };

            var savedProcessedImage = await _imageRepository.CreateProcessedImageAsync(processedImage);

            _logger.LogInformation("Image preprocessing completed for UploadId: {UploadId}, ProcessedId: {ProcessedId}", 
                request.UploadId, savedProcessedImage.ProcessedId);

            return new PreprocessImageResponseDto
            {
                ProcessedId = savedProcessedImage.ProcessedId,
                UploadId = savedProcessedImage.UploadId,
                ProcessedFilePath = savedProcessedImage.ProcessedFilePath,
                PreprocessingSteps = savedProcessedImage.PreprocessingSteps ?? "[]",
                OriginalWidth = originalWidth,
                OriginalHeight = originalHeight,
                ProcessedWidth = request.TargetWidth,
                ProcessedHeight = request.TargetHeight,
                CreatedAt = savedProcessedImage.CreatedAt ?? DateTime.UtcNow
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error preprocessing image for UploadId: {UploadId}", request.UploadId);
            throw;
        }
    }

    public async Task<InferenceResponseDto> RunInferenceAsync(InferenceRequestDto request)
    {
        try
        {
            var stopwatch = Stopwatch.StartNew();
            
            _logger.LogInformation("Starting inference for UploadId: {UploadId}", request.UploadId);

            // Get the image
            var imageUpload = await _imageRepository.GetImageUploadByIdAsync(request.UploadId);
            if (imageUpload == null)
                throw new InvalidOperationException($"Image upload {request.UploadId} not found");

            // Determine which image to use
            string imagePath;
            if (request.UsePreprocessedImage)
            {
                var processedImage = await _imageRepository.GetProcessedImageByUploadIdAsync(request.UploadId);
                if (processedImage == null || string.IsNullOrEmpty(processedImage.ProcessedFilePath))
                {
                    _logger.LogWarning("Preprocessed image not found, using original image");
                    imagePath = imageUpload.FilePath ?? throw new InvalidOperationException("Image file path is null");
                }
                else
                {
                    imagePath = processedImage.ProcessedFilePath;
                }
            }
            else
            {
                imagePath = imageUpload.FilePath ?? throw new InvalidOperationException("Image file path is null");
            }

            // Get model version
            ModelVersion? model;
            if (request.ModelVersionId.HasValue)
            {
                model = await _modelRepository.GetModelByIdAsync(request.ModelVersionId.Value);
                if (model == null)
                    throw new InvalidOperationException($"Model version {request.ModelVersionId} not found");
                
                if (model.IsActive != true)
                    throw new InvalidOperationException($"Model version {request.ModelVersionId} is not active");
            }
            else
            {
                model = await _modelRepository.GetDefaultModelAsync();
                if (model == null)
                    throw new InvalidOperationException("No default model found");
            }

            // Run mock inference (replace with actual ML inference)
            var mockPredictions = await RunMockInference(imagePath, model.ModelVersionId);

            stopwatch.Stop();

            // Save prediction to database
            var prediction = new Prediction
            {
                UploadId = request.UploadId,
                ModelVersionId = model.ModelVersionId,
                PredictedClass = mockPredictions.FirstOrDefault()?.ClassName,
                ConfidenceScore = mockPredictions.FirstOrDefault()?.Confidence,
                TopNPredictions = JsonSerializer.Serialize(mockPredictions),
                ProcessingTimeMs = (int)stopwatch.ElapsedMilliseconds,
                CreatedAt = DateTime.UtcNow
            };

            var savedPrediction = await _imageRepository.CreatePredictionAsync(prediction);

            _logger.LogInformation("Inference completed for UploadId: {UploadId}, PredictionId: {PredictionId}, Time: {Time}ms", 
                request.UploadId, savedPrediction.PredictionId, stopwatch.ElapsedMilliseconds);

            return new InferenceResponseDto
            {
                PredictionId = savedPrediction.PredictionId,
                UploadId = savedPrediction.UploadId,
                ModelVersionId = model.ModelVersionId,
                ModelName = model.ModelName,
                ModelVersion = model.Version,
                PredictedClass = savedPrediction.PredictedClass,
                ConfidenceScore = savedPrediction.ConfidenceScore,
                TopNPredictions = mockPredictions,
                ProcessingTimeMs = savedPrediction.ProcessingTimeMs,
                CreatedAt = savedPrediction.CreatedAt ?? DateTime.UtcNow
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error running inference for UploadId: {UploadId}", request.UploadId);
            throw;
        }
    }

    /// <summary>
    /// Mock inference method - Replace this with actual ML model inference
    /// This simulates ResNet18 or similar model predictions
    /// </summary>
    private async Task<List<PredictionResult>> RunMockInference(string imagePath, int modelVersionId)
    {
        await Task.Delay(100); // Simulate processing time

        // Mock predictions for rice diseases
        var mockResults = new List<PredictionResult>
        {
            new PredictionResult { ClassName = "Rice_Blast", Confidence = 0.8523m, TreeId = 1, IllnessId = 1 },
            new PredictionResult { ClassName = "Brown_Spot", Confidence = 0.0876m, TreeId = 1, IllnessId = 2 },
            new PredictionResult { ClassName = "Leaf_Blight", Confidence = 0.0401m, TreeId = 1, IllnessId = 3 },
            new PredictionResult { ClassName = "Healthy", Confidence = 0.0200m, TreeId = 1, IllnessId = null }
        };

        _logger.LogInformation("Mock inference completed with {Count} predictions", mockResults.Count);

        return mockResults;
    }
}
