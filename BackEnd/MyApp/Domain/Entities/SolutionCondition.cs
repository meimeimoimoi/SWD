using System;
using System.Collections.Generic;

namespace MyApp.Domain.Entities;

public partial class SolutionCondition
{
    public int ConditionId { get; set; }

    public int SolutionId { get; set; }

    public decimal? MinConfidence { get; set; }

    public string? WeatherCondition { get; set; }

    public string? Note { get; set; }

    public virtual TreatmentSolution Solution { get; set; } = null!;
}
