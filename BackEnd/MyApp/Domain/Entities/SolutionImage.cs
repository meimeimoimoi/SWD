using System;
using System.Collections.Generic;

namespace MyApp.Domain.Entities;

public partial class SolutionImage
{
    public int ImageId { get; set; }

    public int SolutionId { get; set; }

    public string ImageUrl { get; set; } = null!;

    public int DisplayOrder { get; set; }

    public DateTime UploadedAt { get; set; }

    public long? FileSize { get; set; }

    public int? Width { get; set; }

    public int? Height { get; set; }

    public virtual TreatmentSolution Solution { get; set; } = null!;
}
