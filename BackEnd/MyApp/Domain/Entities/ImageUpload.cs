using System;
using System.Collections.Generic;

namespace MyApp.Domain.Entities;

public partial class ImageUpload
{
    public int UploadId { get; set; }

    public int UserId { get; set; }

    public string? OriginalFilename { get; set; }

    public string? StoredFilename { get; set; }

    public string? FilePath { get; set; }

    public long? FileSize { get; set; }

    public string? MimeType { get; set; }

    public int? ImageWidth { get; set; }

    public int? ImageHeight { get; set; }

    public string? UploadStatus { get; set; }

    public DateTime? UploadedAt { get; set; }

    public virtual ICollection<Prediction> Predictions { get; set; } = new List<Prediction>();

    public virtual ICollection<ProcessedImage> ProcessedImages { get; set; } = new List<ProcessedImage>();

    public virtual User User { get; set; } = null!;
}
