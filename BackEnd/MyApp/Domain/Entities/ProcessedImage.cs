using System;
using System.Collections.Generic;

namespace MyApp.Domain.Entities;

public partial class ProcessedImage
{
    public int ProcessedId { get; set; }

    public int UploadId { get; set; }

    public string? ProcessedFilePath { get; set; }

    public string? PreprocessingSteps { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual ImageUpload Upload { get; set; } = null!;
}
