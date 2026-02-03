using System;
using System.Collections.Generic;

namespace MyApp.Domain.Entities;

public partial class Rating
{
    public int RatingId { get; set; }

    public int PredictionId { get; set; }

    public string? Rating1 { get; set; }

    public string? Comment { get; set; }

    public DateTime? CreatedAt { get; set; }

    public virtual Prediction Prediction { get; set; } = null!;
}
