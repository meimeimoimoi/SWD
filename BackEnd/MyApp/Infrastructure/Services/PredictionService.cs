using Microsoft.ML.OnnxRuntime;
using Microsoft.ML.OnnxRuntime.Tensors;
using MyApp.Application.Features.Prediction;
using MyApp.Application.Features.Treatment.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Persistence.Repositories;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.ImageSharp.Processing;
using System.Diagnostics;
using System.Text.Json;

namespace MyApp.Infrastructure.Services
{
    public class PredictionService : IPredictionService, IDisposable
    {
        private readonly ILogger<PredictionService> _logger;
        private readonly PredictionRepository _predictionRepository;
        private readonly IImageUploadService _imageUploadService;
        private readonly IllnessRepository _illnessRepository;
        private readonly ModelRepository _modelRepository;
        private readonly IWebHostEnvironment _env;

        private InferenceSession? _session;
        private int? _loadedModelVersionId;
        private const int ImageSize = 224;

        private readonly Dictionary<int, string> _labels = new()
        {
            { 0, "Bacterial Leaf Blight" },
            { 1, "Brown Spot" },
            { 2, "Healthy Rice Leaf" },
            { 3, "Leaf Blast" }
        };

        public PredictionService(
            ILogger<PredictionService> logger,
            PredictionRepository predictionRepository,
            IImageUploadService imageUploadService,
            IllnessRepository illnessRepository,
            ModelRepository modelRepository,
            IWebHostEnvironment env)
        {
            _logger = logger;
            _predictionRepository = predictionRepository;
            _imageUploadService = imageUploadService;
            _illnessRepository = illnessRepository;
            _modelRepository = modelRepository;
            _env = env;
        }

        // ── Load active default model from DB ────────────────────────────────

        private async Task EnsureModelLoadedAsync()
        {
            var defaultModel = await _modelRepository.GetDefaultModelAsync();

            if (defaultModel == null)
                throw new InvalidOperationException(
                    "No active default model found in the database. Please activate a model first.");

            // Already loaded the same model — skip
            if (_session != null && _loadedModelVersionId == defaultModel.ModelVersionId)
                return;

            _session?.Dispose();
            _session = null;

            // Read FilePath from DB (relative path stored at upload/seed time)
            if (string.IsNullOrWhiteSpace(defaultModel.FilePath))
                throw new InvalidOperationException(
                    $"Model Id={defaultModel.ModelVersionId} has no FilePath stored in the database.");

            var modelPath = Path.Combine(_env.ContentRootPath, defaultModel.FilePath);

            if (!File.Exists(modelPath))
                throw new InvalidOperationException(
                    $"Model file not found at '{modelPath}'. Please re-upload the model file.");

            _session = new InferenceSession(modelPath);
            _loadedModelVersionId = defaultModel.ModelVersionId;

            _logger.LogInformation(
                "ONNX model loaded — Id={Id}, Name='{Name}', v{Version}, Path='{Path}'",
                defaultModel.ModelVersionId, defaultModel.ModelName, defaultModel.Version, modelPath);
        }

        // ── Predict ──────────────────────────────────────────────────────────

        public async Task<PredictionResponseDto> PredictAsync(int userId, IFormFile imageFile)
        {
            await EnsureModelLoadedAsync();

            var stopwatch = Stopwatch.StartNew();

            var uploadResult = await _imageUploadService.UploadImageAsync(userId, imageFile);

            using var stream = File.OpenRead(uploadResult.FilePath!);
            using var image = Image.Load<Rgb24>(stream);

            image.Mutate(x => x.Resize(new ResizeOptions
            {
                Size = new Size(ImageSize, ImageSize),
                Mode = ResizeMode.Stretch
            }));

            var inputTensor = new DenseTensor<float>(new[] { 1, ImageSize, ImageSize, 3 });
            for (int y = 0; y < image.Height; y++)
                for (int x = 0; x < image.Width; x++)
                {
                    var pixel = image[x, y];
                    inputTensor[0, y, x, 0] = pixel.R;
                    inputTensor[0, y, x, 1] = pixel.G;
                    inputTensor[0, y, x, 2] = pixel.B;
                }

            var inputName = _session!.InputMetadata.Keys.First();
            var outputName = _session.OutputMetadata.Keys.First();
            var inputs = new List<NamedOnnxValue>
            {
                NamedOnnxValue.CreateFromTensor(inputName, inputTensor)
            };

            using var results = _session.Run(inputs);
            var outputArray = results.First(v => v.Name == outputName)
                                        .AsEnumerable<float>().ToArray();

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

            var allProbs = new Dictionary<string, double>();
            for (int i = 0; i < outputArray.Length; i++)
                allProbs[_labels[i]] = Math.Round(outputArray[i], 6);

            var illnessInfo = await _illnessRepository.GetByNameAysnc(predictedLabel);

            stopwatch.Stop();

            var prediction = new Prediction
            {
                UploadId = uploadResult.UploadId,
                ModelVersionId = _loadedModelVersionId,
                Illness = illnessInfo,
                PredictedClass = predictedLabel,
                ConfidenceScore = (decimal)maxConfidence,
                TopNPredictions = JsonSerializer.Serialize(allProbs),
                ProcessingTimeMs = (int)stopwatch.ElapsedMilliseconds,
                CreatedAt = DateTime.UtcNow
            };

            await _predictionRepository.AddPredictionAsync(prediction);

            _logger.LogInformation(
                "Prediction saved — Id={Id}, Class={Class}, Confidence={Conf:P2}, ModelId={ModelId}",
                prediction.PredictionId, predictedLabel, maxConfidence, _loadedModelVersionId);

            return new PredictionResponseDto
            {
                PredictionId = prediction.PredictionId,
                ImageUrl = uploadResult.StoredFilename ?? string.Empty,
                PredictedClass = predictedLabel,
                Confidence = Math.Round(maxConfidence, 4),
                ProcessingTimeMs = stopwatch.ElapsedMilliseconds,
                DiseaseName = illnessInfo?.IllnessName ?? predictedLabel,
                Symptoms = illnessInfo?.Symptoms ?? "No description available.",
                Causes = illnessInfo?.Causes,
                Treatments = illnessInfo?.TreatmentSolutions.Where(t => t.SolutionType == "treatment")
                .Select(t => new TreatmentDto
                {
                    Name = t.SolutionName ?? "Treatment",
                    Type = t.SolutionType ?? "treatment",
                    Description = t.Description ?? string.Empty
                }).ToList() ?? new List<TreatmentDto>(),
                Medicines = illnessInfo?.TreatmentSolutions.Where(m => m.SolutionType == "medicine")
                .Select(m => new MedicineDto
                {
                    Name = m.SolutionName ?? "Medicine",
                    Type = m.SolutionType ?? "medicine",
                    Description = m.Description ?? string.Empty
                }).ToList() ?? new List<MedicineDto>()
                
            };
        }

        // ── Health check ─────────────────────────────────────────────────────

        public async Task<bool> IsModelLoaded()
        {
            try
            {
                await EnsureModelLoadedAsync();
                return _session != null;
            }
            catch
            {
                return false;
            }
        }

        public void Dispose() => _session?.Dispose();
    }
}
