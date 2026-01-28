using System.Diagnostics;
using SWD.Business.DTOs;
using SWD.Business.Interface;
using SWD.Business.ML;

namespace SWD.Business.Services;

/// <summary>
/// Service for detecting rice diseases using ResNet18 model
/// </summary>
public class DiseaseDetectionService : IDiseaseDetectionService
{
    private readonly ResNet18Predictor? _predictor;
    private readonly string _modelPath;

    public DiseaseDetectionService(string modelPath)
    {
        _modelPath = modelPath;
        
        // Initialize predictor if model exists
        if (File.Exists(modelPath))
        {
            try
            {
                _predictor = new ResNet18Predictor(modelPath);
                Console.WriteLine($"✅ ResNet18 model loaded successfully from: {modelPath}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Failed to load ResNet18 model: {ex.Message}");
            }
        }
        else
        {
            Console.WriteLine($"⚠️  Model file not found at: {modelPath}");
            Console.WriteLine($"   Please place your ResNet18 model file at this location.");
        }
    }

    /// <summary>
    /// Predict disease from image bytes
    /// </summary>
    public async Task<DiseasePredictionResponseDTO> PredictDiseaseAsync(byte[] imageBytes)
    {
        if (_predictor == null)
        {
            throw new InvalidOperationException(
                $"Model not loaded. Please ensure the model file exists at: {_modelPath}");
        }

        if (!ImagePreprocessor.IsValidImage(imageBytes))
        {
            throw new ArgumentException("Invalid image format");
        }

        var stopwatch = Stopwatch.StartNew();

        // Preprocess image
        var preprocessedImage = await Task.Run(() => 
            ImagePreprocessor.PreprocessImage(imageBytes));

        // Predict
        var prediction = await Task.Run(() => 
            _predictor.Predict(preprocessedImage));

        stopwatch.Stop();

        return new DiseasePredictionResponseDTO
        {
            PredictedDisease = prediction.PredictedLabel,
            Confidence = prediction.Confidence,
            AllPredictions = prediction.AllPredictions.Select(p => new DiseasePredictionItemDTO
            {
                Label = p.Label,
                Confidence = p.Confidence
            }).ToList(),
            ProcessingTimeMs = stopwatch.ElapsedMilliseconds,
            PredictedAt = DateTime.UtcNow
        };
    }

    /// <summary>
    /// Predict disease from base64 encoded image
    /// </summary>
    public async Task<DiseasePredictionResponseDTO> PredictDiseaseFromBase64Async(string base64Image)
    {
        // Remove data:image/...;base64, prefix if exists
        var base64Data = base64Image.Contains(',') 
            ? base64Image.Split(',')[1] 
            : base64Image;

        try
        {
            var imageBytes = Convert.FromBase64String(base64Data);
            return await PredictDiseaseAsync(imageBytes);
        }
        catch (FormatException)
        {
            throw new ArgumentException("Invalid base64 string format");
        }
    }

    /// <summary>
    /// Check if the model is loaded and ready
    /// </summary>
    public bool IsModelReady()
    {
        return _predictor != null;
    }
}
