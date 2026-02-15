using System.ComponentModel.DataAnnotations;

namespace MyApp.Application.Features.Predictions.DTOs;

public class RunPredictionRequestDto
{
    [Required(ErrorMessage = "UploadId is required")]
    public int UploadId { get; set; }

    public int? ModelVersionId { get; set; } // Optional - use default if not specified
    
    public bool UsePreprocessedImage { get; set; } = true;
}
