namespace MyApp.Application.Features.Prediction
{
    public class PredictionResponseDto
    {
        public string PredictedClass { get; set; } = string.Empty;
        public double Confidence { get; set; }
        public Dictionary<string, double> AllProbabilities { get; set; } = new();
        public string Recommendation { get; set; } = string.Empty;
        public string Severity { get; set; } = string.Empty;
        public long ProcessingTimeMs { get; set; }
    }
}
