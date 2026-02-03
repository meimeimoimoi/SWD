using System;
using System.Collections.Generic;

namespace MyApp.Domain.Entities;

public partial class RefreshToken
{
    public int RefreshTokenId { get; set; }

    public string JtiHash { get; set; } = null!;

    public bool? IsRevoked { get; set; }

    public DateTime? CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }
}
