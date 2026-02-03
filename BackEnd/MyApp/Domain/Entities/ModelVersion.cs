using System;
using System.Collections.Generic;

namespace MyApp.Domain.Entities;

public partial class ModelVersion
{
    public int ModelVersionId { get; set; }

    public string ModelName { get; set; } = null!;

    public string Version { get; set; } = null!;

    public string? ModelType { get; set; }

    public string? Description { get; set; }

    public bool? IsActive { get; set; }

    public bool? IsDefault { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual ICollection<Prediction> Predictions { get; set; } = new List<Prediction>();
}
