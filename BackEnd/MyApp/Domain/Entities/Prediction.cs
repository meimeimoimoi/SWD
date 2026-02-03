using System;
using System.Collections.Generic;

namespace MyApp.Domain.Entities;

public partial class Prediction
{
    public int PredictionId { get; set; }

    public int UploadId { get; set; }

    public int? ModelVersionId { get; set; }

    public int? TreeId { get; set; }

    public int? IllnessId { get; set; }

    public string? PredictedClass { get; set; }

    public decimal? ConfidenceScore { get; set; }

    public string? TopNPredictions { get; set; }

    public int? ProcessingTimeMs { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual TreeIllness? Illness { get; set; }

    public virtual ModelVersion? ModelVersion { get; set; }

    public virtual ICollection<Rating> Ratings { get; set; } = new List<Rating>();

    public virtual Tree? Tree { get; set; }

    public virtual ImageUpload Upload { get; set; } = null!;
}
