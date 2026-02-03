using System;
using System.Collections.Generic;

namespace MyApp.Domain.Entities;

public partial class Tree
{
    public int TreeId { get; set; }

    public string? TreeName { get; set; }

    public string? ScientificName { get; set; }

    public string? Description { get; set; }

    public string? ImagePath { get; set; }

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual ICollection<Prediction> Predictions { get; set; } = new List<Prediction>();

    public virtual ICollection<TreeIllnessRelationship> TreeIllnessRelationships { get; set; } = new List<TreeIllnessRelationship>();
}
