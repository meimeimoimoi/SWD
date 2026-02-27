using Microsoft.ML.OnnxRuntime;
using Microsoft.ML.OnnxRuntime.Tensors;
using MyApp.Application.Features.Prediction;
using MyApp.Application.Interfaces;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.ImageSharp.Processing;
using System.Diagnostics;
using static System.Net.Mime.MediaTypeNames;

namespace MyApp.Infrastructure.Services
{
    public class PredictionService : IPredictionService, IDisposable
    {
        private readonly InferenceSession _session;
        private readonly ILogger<PredictionService> _logger;
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

        public PredictionService(ILogger<PredictionService> logger)
        {
            _logger = logger;
            // Load model lúc app vừa chạy
            var modelPath = Path.Combine(Directory.GetCurrentDirectory(), "Models", "rice_disease_v3.onnx");
            _session = new InferenceSession(modelPath);
            _logger.LogInformation("ONNX Model loaded successfully from {Path}", modelPath);
        }

        public async Task<PredictionResponseDto> PredictAsync(Stream imageStream)
        {
            var stopwatch = Stopwatch.StartNew();

            // Đọc và Resize ảnh giống PIL.Image.resize((224, 224))
            using var image = await  SixLabors.ImageSharp.Image.LoadAsync<Rgb24>(imageStream);
            image.Mutate(x => x.Resize(new ResizeOptions
            {
                Size = new Size(ImageSize, ImageSize),
                Mode = ResizeMode.Stretch // Bóp méo ảnh cho vừa 224x224 giống hệt Python
            }));

            // Chuyển thành Tensor chuẩn NHWC [Batch, Height, Width, Channels] của TensorFlow
            var inputTensor = new DenseTensor<float>(new[] { 1, ImageSize, ImageSize, 3 });

            for (int y = 0; y < image.Height; y++)
            {
                for (int x = 0; x < image.Width; x++)
                {
                    var pixel = image[x, y];
                    
                    inputTensor[0, y, x, 0] = pixel.R;
                    inputTensor[0, y, x, 1] = pixel.G;
                    inputTensor[0, y, x, 2] = pixel.B;
                }
            }

            // Tự động lấy tên input/output của Model ONNX
            var inputName = _session.InputMetadata.Keys.First();
            var outputName = _session.OutputMetadata.Keys.First();

            var inputs = new List<NamedOnnxValue> { NamedOnnxValue.CreateFromTensor(inputName, inputTensor) };

            // Chạy Model dự đoán
            using var results = _session.Run(inputs);
            var outputArray = results.First(v => v.Name == outputName).AsEnumerable<float>().ToArray();

            // Output lúc này đã là Softmax (tổng = 1)

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

            string predictedClass = _labels[predictedIndex];

            // Map dữ liệu trả về
            var allProbs = new Dictionary<string, double>();
            for (int i = 0; i < outputArray.Length; i++)
            {
                allProbs[_labels[i]] = Math.Round(outputArray[i], 6);
            }

            stopwatch.Stop();

            return new PredictionResponseDto
            {
                PredictedClass = predictedClass,
                Confidence = Math.Round(maxConfidence, 6),
                AllProbabilities = allProbs,
                Recommendation = _recommendations.GetValueOrDefault(predictedClass, "Consult expert."),
                Severity = _severity.GetValueOrDefault(predictedClass, "unknown"),
                ProcessingTimeMs = stopwatch.ElapsedMilliseconds
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
