using System.ComponentModel.DataAnnotations;

namespace MyApp.Application.Features.Prediction;

public class AssignPredictionToTreeDto
{
    [Required]
    [Range(1, int.MaxValue)]
    public int TreeId { get; set; }
}
