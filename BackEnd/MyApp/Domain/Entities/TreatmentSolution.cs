using System;
using System.Collections.Generic;

namespace MyApp.Domain.Entities;

public partial class TreatmentSolution
{
    public int SolutionId { get; set; }

    public int IllnessId { get; set; }

    public int? IllnessStageId { get; set; }

    public string? SolutionName { get; set; }

    public string? SolutionType { get; set; }

    public string? Description { get; set; }

    public int TreeStageId { get; set; }

    public decimal? MinConfidence { get; set; }

    public int? Priority { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual TreeIllness Illness { get; set; } = null!;

    public virtual ICollection<SolutionCondition> SolutionConditions { get; set; } = new List<SolutionCondition>();

    public virtual TreeStage TreeStage { get; set; } = null!;
}
