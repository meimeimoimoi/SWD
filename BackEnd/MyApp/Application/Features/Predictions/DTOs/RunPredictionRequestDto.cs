using System.ComponentModel.DataAnnotations;

namespace MyApp.Application.Features.Predictions.DTOs;

public class RunPredictionRequestDto
{
    [Required(ErrorMessage = "UploadId is required")]
    public int UploadId { get; set; }
}
