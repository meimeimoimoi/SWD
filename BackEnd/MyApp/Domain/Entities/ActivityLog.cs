using System;

namespace MyApp.Domain.Entities
{
    public class ActivityLog
    {
        public int ActivityLogId { get; set; }
        public int? UserId { get; set; }
        public string Action { get; set; } = null!; // e.g., "Login", "CreatePrediction", "UpdateProfile"
        public string EntityName { get; set; } = null!; // e.g., "User", "Prediction"
        public string? EntityId { get; set; }
        public string? Description { get; set; }
        public string? IpAddress { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public virtual User? User { get; set; }
    }
}
