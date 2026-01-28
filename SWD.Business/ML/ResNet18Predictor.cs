using Microsoft.ML;
using Microsoft.ML.Data;
using System.Drawing;

namespace SWD.Business.ML;

/// <summary>
/// ResNet18 model predictor for rice disease detection
/// </summary>
public class ResNet18Predictor
{
    private readonly PredictionEngine<ImageInput, ImagePrediction>? _predictionEngine;
    private readonly MLContext _mlContext;
    private readonly string[] _labels;

    public ResNet18Predictor(string modelPath)
    {
        _mlContext = new MLContext();
        
        // Define disease labels (customize based on your model)
        _labels = new[]
        {
            "Healthy",
            "Bacterial Leaf Blight",
            "Brown Spot",
            "Leaf Smut",
            "Blast"
        };

        if (File.Exists(modelPath))
        {
            // Load the trained model
            var model = _mlContext.Model.Load(modelPath, out var modelInputSchema);
            _predictionEngine = _mlContext.Model.CreatePredictionEngine<ImageInput, ImagePrediction>(model);
        }
        else
        {
            Console.WriteLine($"Model file not found at: {modelPath}");
        }
    }

    /// <summary>
    /// Predict disease from image bytes
    /// </summary>
    public PredictionResult Predict(byte[] imageBytes)
    {
        if (_predictionEngine == null)
        {
            throw new InvalidOperationException("Model not loaded. Please ensure the model file exists.");
        }

        var input = new ImageInput { ImageData = imageBytes };
        var prediction = _predictionEngine.Predict(input);

        // Find the predicted class with highest score
        var maxScore = prediction.Score.Max();
        var predictedIndex = Array.IndexOf(prediction.Score, maxScore);
        var predictedLabel = predictedIndex >= 0 && predictedIndex < _labels.Length 
            ? _labels[predictedIndex] 
            : "Unknown";

        return new PredictionResult
        {
            PredictedLabel = predictedLabel,
            Confidence = maxScore * 100,
            AllPredictions = _labels.Select((label, index) => new ClassPrediction
            {
                Label = label,
                Confidence = prediction.Score[index] * 100
            }).OrderByDescending(x => x.Confidence).ToList()
        };
    }

    /// <summary>
    /// Predict disease from image file path
    /// </summary>
    public PredictionResult PredictFromFile(string imagePath)
    {
        if (!File.Exists(imagePath))
        {
            throw new FileNotFoundException($"Image file not found: {imagePath}");
        }

        var imageBytes = File.ReadAllBytes(imagePath);
        return Predict(imageBytes);
    }
}

/// <summary>
/// Input class for ML model
/// </summary>
public class ImageInput
{
    [LoadColumn(0)]
    [ImageType(224, 224)]
    public byte[]? ImageData { get; set; }
}

/// <summary>
/// Output class for ML model prediction
/// </summary>
public class ImagePrediction
{
    [ColumnName("score")]
    public float[]? Score { get; set; }
}

/// <summary>
/// Prediction result with label and confidence
/// </summary>
public class PredictionResult
{
    public string PredictedLabel { get; set; } = string.Empty;
    public float Confidence { get; set; }
    public List<ClassPrediction> AllPredictions { get; set; } = new();
}

/// <summary>
/// Individual class prediction with confidence score
/// </summary>
public class ClassPrediction
{
    public string Label { get; set; } = string.Empty;
    public float Confidence { get; set; }
}
