namespace MyApp.Application.Features.AI.DTOs;

public class InferenceRequestDto
{
    public int UploadId { get; set; }
    public int? ModelVersionId { get; set; } // If null, use default model
    public bool UsePreprocessedImage { get; set; } = true;
}
