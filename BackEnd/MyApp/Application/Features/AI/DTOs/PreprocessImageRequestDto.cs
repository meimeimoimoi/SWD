namespace MyApp.Application.Features.AI.DTOs;

public class PreprocessImageRequestDto
{
    public int UploadId { get; set; }
    public int TargetWidth { get; set; } = 224;
    public int TargetHeight { get; set; } = 224;
    public bool Normalize { get; set; } = true;
}
