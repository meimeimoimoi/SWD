using System;
using System.Collections.Generic;

namespace MyApp.Domain.Entities;

public partial class TreeIllness
{
    public int IllnessId { get; set; }

    public string? IllnessName { get; set; }

    public string? ScientificName { get; set; }

    public string? Description { get; set; }

    public string? Symptoms { get; set; }

    public string? Causes { get; set; }

    public string? Severity { get; set; }

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual ICollection<Prediction> Predictions { get; set; } = new List<Prediction>();

    public virtual ICollection<TreatmentSolution> TreatmentSolutions { get; set; } = new List<TreatmentSolution>();

    public virtual ICollection<TreeIllnessRelationship> TreeIllnessRelationships { get; set; } = new List<TreeIllnessRelationship>();
}
