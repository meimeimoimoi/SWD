namespace MyApp.Application.Features.AI.DTOs;

public class PreprocessImageResponseDto
{
    public int ProcessedId { get; set; }
    public int UploadId { get; set; }
    public string ProcessedFilePath { get; set; } = null!;
    public string PreprocessingSteps { get; set; } = null!;
    public int OriginalWidth { get; set; }
    public int OriginalHeight { get; set; }
    public int ProcessedWidth { get; set; }
    public int ProcessedHeight { get; set; }
    public DateTime CreatedAt { get; set; }
}
