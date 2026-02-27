using Microsoft.ML.OnnxRuntime;
using Microsoft.ML.OnnxRuntime.Tensors;
using MyApp.Application.Features.Prediction;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Persistence.Repositories;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.ImageSharp.Processing;
using System.Diagnostics;
using System.Text.Json;
using static System.Net.Mime.MediaTypeNames;

namespace MyApp.Infrastructure.Services
{
    public class PredictionService : IPredictionService, IDisposable
    {
        private readonly InferenceSession _session;
        private readonly ILogger<PredictionService> _logger;
        private readonly PredictionRepository _predictionRepository;
        private readonly IImageUploadService _imageUploadService;
        private readonly IllnessRepository _illnessRepository;
        private const int ImageSize = 224;

        private readonly Dictionary<int, string> _labels = new()
        {
            { 0, "Bacterial Leaf Blight" },
            { 1, "Brown Spot" },
            { 2, "Healthy Rice Leaf" },
            { 3, "Leaf Blast" }
        };

        private readonly Dictionary<string, string> _recommendations = new()
        {
            { "Healthy Rice Leaf", "Rice plant is healthy! No treatment needed." },
            { "Bacterial Leaf Blight", "Apply copper-based bactericides. Remove infected leaves. Ensure proper field drainage." },
            { "Brown Spot", "Apply potassium fertilizer. Use Mancozeb fungicide. Improve soil nutrition." },
            { "Leaf Blast", "Apply Tricyclazole fungicide. Improve drainage. Avoid excess nitrogen fertilizer." }
        };

        private readonly Dictionary<string, string> _severity = new()
        {
            { "Healthy Rice Leaf", "none" },
            { "Bacterial Leaf Blight", "high" },
            { "Brown Spot", "medium" },
            { "Leaf Blast", "high" }
        };

        public PredictionService(
            ILogger<PredictionService> logger, 
            PredictionRepository predictionRepository,
            IImageUploadService imageUploadService,
            IllnessRepository illnessRepository)
        {
            _logger = logger;
            // Load model lúc app vừa chạy
            _predictionRepository = predictionRepository;
            _imageUploadService = imageUploadService;
            _illnessRepository = illnessRepository;

            var modelPath = Path.Combine(Directory.GetCurrentDirectory(), "Models", "rice_disease_v3.onnx");
            _logger.LogInformation("ONNX Model loaded successfully from {Path}", modelPath);
            _session = new InferenceSession(modelPath);
        }

        public async Task<PredictionResponseDto> PredictAsync(int userId, IFormFile imageFile)
        {
            var stopwatch = Stopwatch.StartNew();

            // Đọc và Resize ảnh giống PIL.Image.resize((224, 224))
            var uploadResult = await _imageUploadService.UploadImageAsync(userId, imageFile);

            // Xử lý ảnh 
            using var stream = File.OpenRead(uploadResult.FilePath);
            using var image = SixLabors.ImageSharp.Image.Load<Rgb24>(stream);

            image.Mutate(x => x.Resize(new ResizeOptions
            {
                Size = new Size(ImageSize, ImageSize),
                Mode = ResizeMode.Stretch 
            }));

            var inputTensor = new DenseTensor<float>(new[] { 1, ImageSize, ImageSize, 3 });
            for (int y = 0; y < image.Height; y++)
            {
                for (int x = 0; x < image.Width; x++)
                {
                    var pixel = image[x, y];
                    
                    inputTensor[0, y, x, 0] = pixel.R; // R
                    inputTensor[0, y, x, 1] = pixel.G; // G 
                    inputTensor[0, y, x, 2] = pixel.B; // B
                }
            }

            // Tự động lấy tên input/output của Model ONNX
            var inputName = _session.InputMetadata.Keys.First();
            var outputName = _session.OutputMetadata.Keys.First();

            var inputs = new List<NamedOnnxValue> { NamedOnnxValue.CreateFromTensor(inputName, inputTensor) };

            // Chạy Model dự đoán
            using var results = _session.Run(inputs);
            var outputArray = results.First(v => v.Name == outputName).AsEnumerable<float>().ToArray();

            // Tìm class có tỷ lệ cao nhất
            int predictedIndex = 0;
            float maxConfidence = outputArray[0];

            for (int i = 1; i < outputArray.Length; i++)
            {
                if (outputArray[i] > maxConfidence)
                {
                    maxConfidence = outputArray[i];
                    predictedIndex = i;
                }
            }

            string predictedLabel = _labels[predictedIndex];

            // Map dữ liệu trả về
            var allProbs = new Dictionary<string, double>();
            for (int i = 0; i < outputArray.Length; i++)
            {
                allProbs[_labels[i]] = Math.Round(outputArray[i], 6);
            }

            var illnessInfo = await _illnessRepository.GetByNameAysnc(predictedLabel);

            stopwatch.Stop();

            var prediction = new Prediction
            {
               UploadId = uploadResult.UploadId,
               Illness = illnessInfo,
               PredictedClass = predictedLabel,
               ConfidenceScore = (decimal) maxConfidence,
               TopNPredictions = JsonSerializer.Serialize(allProbs),
               ProcessingTimeMs = (int) stopwatch.ElapsedMilliseconds,
               CreatedAt = DateTime.UtcNow
            };

            await _predictionRepository.AddPredictionAsync(prediction);

            return new PredictionResponseDto
            {
                PredictionId = prediction.PredictionId,
                ImageUrl = uploadResult.StoredFilename,
                PredictedClass = predictedLabel,
                Confidence = Math.Round(maxConfidence, 4),
                ProcessingTimeMs = stopwatch.ElapsedMilliseconds,

                DiseaseName = illnessInfo?.IllnessName ?? predictedLabel,
                Symptoms = illnessInfo?.Symptoms ?? "Chưa có dữ liệu mô tả.",
                Causes = illnessInfo?.Causes,
                Treatments = illnessInfo?.TreatmentSolutions.Select(t => new TreatmentDto
                {
                    Name = t.SolutionName ?? "Thuốc",
                    Type = t.SolutionType ?? "Chưa rõ",
                    Description = t.Description ?? ""
                }).ToList() ?? new List<TreatmentDto>()
            };
        }

        public Task<bool> IsModelLoaded()
        {
            return Task.FromResult(_session != null);
        }

        public void Dispose()
        {
            _session?.Dispose();
        }
    }
}
