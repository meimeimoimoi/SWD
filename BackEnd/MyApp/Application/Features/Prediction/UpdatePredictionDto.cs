using System.ComponentModel.DataAnnotations;

namespace MyApp.Application.Features.Prediction
{
    public class UpdatePredictionDto
    {
        [Range(1, int.MaxValue, ErrorMessage = "TreeId must be a positive integer.")]
        public int? TreeId { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "IllnessId must be a positive integer.")]
        public int? IllnessId { get; set; }

        public string? PredictedClass { get; set; }
    }
}
