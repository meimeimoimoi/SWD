using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MyApp.Domain.Entities;

namespace MyApp.Persistence.Configurations
{
    public class SystemSettingConfiguration : IEntityTypeConfiguration<SystemSetting>
    {
        public void Configure(EntityTypeBuilder<SystemSetting> builder)
        {
            builder.HasKey(e => e.SettingId);
            builder.ToTable("system_settings");

            builder.HasIndex(e => e.Key).IsUnique();

            builder.Property(e => e.SettingId).HasColumnName("setting_id");
            builder.Property(e => e.Key).IsRequired().HasMaxLength(100).HasColumnName("setting_key");
            builder.Property(e => e.Value).IsRequired().HasColumnName("setting_value");
            builder.Property(e => e.Description).HasColumnName("description");
            builder.Property(e => e.Group).HasMaxLength(50).HasColumnName("setting_group");
            builder.Property(e => e.UpdatedAt).HasDefaultValueSql("GETDATE()").HasColumnName("updated_at");
        }
    }
}
