using System;
using System.Collections.Generic;

namespace MyApp.Domain.Entities;

public partial class TreeStage
{
    public int StageId { get; set; }

    public string? StageName { get; set; }

    public string? Description { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual ICollection<TreatmentSolution> TreatmentSolutions { get; set; } = new List<TreatmentSolution>();
}
