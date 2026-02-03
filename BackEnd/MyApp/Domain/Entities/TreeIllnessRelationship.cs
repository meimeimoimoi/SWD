using System;
using System.Collections.Generic;

namespace MyApp.Domain.Entities;

public partial class TreeIllnessRelationship
{
    public int RelationshipId { get; set; }

    public int TreeId { get; set; }

    public int IllnessId { get; set; }

    public virtual TreeIllness Illness { get; set; } = null!;

    public virtual Tree Tree { get; set; } = null!;
}
