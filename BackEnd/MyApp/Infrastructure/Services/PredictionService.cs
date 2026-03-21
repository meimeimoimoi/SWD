using Microsoft.ML.OnnxRuntime;
using Microsoft.ML.OnnxRuntime.Tensors;
using MyApp.Application.Features.Prediction;
using MyApp.Application.Features.Treatment.DTOs;
using MyApp.Application.Interfaces;
using MyApp.Domain.Entities;
using MyApp.Infrastructure.Ml;
using MyApp.Persistence.Repositories;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.ImageSharp.Processing;
using System.Diagnostics;
using System.Text.Json;

namespace MyApp.Infrastructure.Services;

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
    private string[]? _classNames;
    private const int ImageSize = 224;

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

    private async Task EnsureModelLoadedAsync()
    {
        var defaultModel = await _modelRepository.GetDefaultModelAsync();

        if (defaultModel == null)
            throw new InvalidOperationException("No active default model in the database.");

        if (_session != null && _loadedModelVersionId == defaultModel.ModelVersionId)
            return;

        _session?.Dispose();
        _session = null;
        _classNames = null;

        if (string.IsNullOrWhiteSpace(defaultModel.FilePath))
            throw new InvalidOperationException($"Model Id={defaultModel.ModelVersionId} has no FilePath.");

        var modelPath = Path.Combine(_env.ContentRootPath, defaultModel.FilePath);
        if (!File.Exists(modelPath))
            throw new InvalidOperationException($"Model file not found: {modelPath}");

        var session = new InferenceSession(modelPath);
        _classNames = OnnxModelLabels.Read(session);
        _session = session;
        _loadedModelVersionId = defaultModel.ModelVersionId;

        _logger.LogInformation("Loaded ONNX id={Id} path={Path} classes={N}",
            defaultModel.ModelVersionId, modelPath, _classNames.Length);
    }

    public async Task<PredictionResponseDto> PredictAsync(int userId, IFormFile imageFile)
    {
        await EnsureModelLoadedAsync();
        var names = _classNames!;

        var sw = Stopwatch.StartNew();
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
                var p = image[x, y];
                inputTensor[0, y, x, 0] = p.R;
                inputTensor[0, y, x, 1] = p.G;
                inputTensor[0, y, x, 2] = p.B;
            }

        var inputName = _session!.InputMetadata.Keys.First();
        var outputName = _session.OutputMetadata.Keys.First();
        using var results = _session.Run(new List<NamedOnnxValue>
        {
            NamedOnnxValue.CreateFromTensor(inputName, inputTensor)
        });

        var output = results.First(v => v.Name == outputName).AsEnumerable<float>().ToArray();
        if (output.Length != names.Length)
            throw new InvalidOperationException("Output size does not match class_labels count.");

        int best = 0;
        for (int i = 1; i < output.Length; i++)
            if (output[i] > output[best]) best = i;

        var predictedLabel = names[best];
        var probs = new Dictionary<string, double>();
        for (int i = 0; i < output.Length; i++)
            probs[names[i]] = Math.Round(output[i], 6);

        var illnessInfo = await _illnessRepository.GetByNameAysnc(predictedLabel);
        sw.Stop();

        var prediction = new Prediction
        {
            UploadId = uploadResult.UploadId,
            ModelVersionId = _loadedModelVersionId,
            Illness = illnessInfo,
            PredictedClass = predictedLabel,
            ConfidenceScore = (decimal)output[best],
            TopNPredictions = JsonSerializer.Serialize(probs),
            ProcessingTimeMs = (int)sw.ElapsedMilliseconds,
            CreatedAt = DateTime.UtcNow
        };

        await _predictionRepository.AddPredictionAsync(prediction);

        return new PredictionResponseDto
        {
            PredictionId = prediction.PredictionId,
            ImageUrl = uploadResult.StoredFilename ?? string.Empty,
            PredictedClass = predictedLabel,
            Confidence = Math.Round(output[best], 4),
            ProcessingTimeMs = sw.ElapsedMilliseconds,
            DiseaseName = illnessInfo?.IllnessName ?? predictedLabel,
            Symptoms = illnessInfo?.Symptoms,
            Causes = illnessInfo?.Causes,
            Treatments = illnessInfo?.TreatmentSolutions.Where(t => t.SolutionType == "treatment")
                .Select(t => new TreatmentDto
                {
                    Name = t.SolutionName ?? "Treatment",
                    Type = t.SolutionType ?? "treatment",
                    Description = t.Description ?? string.Empty
                }).ToList() ?? [],
            Medicines = illnessInfo?.TreatmentSolutions.Where(m => m.SolutionType == "medicine")
                .Select(m => new MedicineDto
                {
                    Name = m.SolutionName ?? "Medicine",
                    Type = m.SolutionType ?? "medicine",
                    Description = m.Description ?? string.Empty
                }).ToList() ?? []
        };
    }

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
