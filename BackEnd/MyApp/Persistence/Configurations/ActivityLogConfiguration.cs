using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MyApp.Domain.Entities;

namespace MyApp.Persistence.Configurations
{
    public class ActivityLogConfiguration : IEntityTypeConfiguration<ActivityLog>
    {
        public void Configure(EntityTypeBuilder<ActivityLog> builder)
        {
            builder.HasKey(e => e.ActivityLogId);
            builder.ToTable("activity_logs");

            builder.Property(e => e.ActivityLogId).HasColumnName("activity_log_id");
            builder.Property(e => e.UserId).HasColumnName("user_id");
            builder.Property(e => e.Action).IsRequired().HasMaxLength(100).HasColumnName("action");
            builder.Property(e => e.EntityName).IsRequired().HasMaxLength(100).HasColumnName("entity_name");
            builder.Property(e => e.EntityId).HasMaxLength(100).HasColumnName("entity_id");
            builder.Property(e => e.Description).HasColumnName("description");
            builder.Property(e => e.IpAddress).HasMaxLength(50).HasColumnName("ip_address");
            builder.Property(e => e.CreatedAt).HasDefaultValueSql("GETDATE()").HasColumnName("created_at");

            builder.HasOne(d => d.User)
                   .WithMany()
                   .HasForeignKey(d => d.UserId)
                   .OnDelete(DeleteBehavior.SetNull)
                   .HasConstraintName("FK_activity_user");
        }
    }
}
