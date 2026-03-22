using System;

namespace MyApp.Domain.Entities
{
    public class SystemSetting
    {
        public int SettingId { get; set; }
        public string Key { get; set; } = null!;
        public string Value { get; set; } = null!;
        public string? Description { get; set; }
        public string? Group { get; set; }
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
}
