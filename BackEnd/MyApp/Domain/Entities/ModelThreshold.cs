using System;

namespace MyApp.Domain.Entities;

public partial class ModelThreshold
{
    public int ThresholdId { get; set; }

    public int? ModelVersionId { get; set; }

    public decimal? MinConfidence { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual ModelVersion? ModelVersion { get; set; }
}
