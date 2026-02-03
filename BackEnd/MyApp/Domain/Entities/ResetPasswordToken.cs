using System;
using System.Collections.Generic;

namespace MyApp.Domain.Entities;

public partial class ResetPasswordToken
{
    public int ResetTokenId { get; set; }

    public string TokenHash { get; set; } = null!;

    public bool? IsUsed { get; set; }

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }
}
