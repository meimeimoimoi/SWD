using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MyApp.Domain.Entities;

namespace MyApp.Persistence.Configurations
{
    public class NotificationConfiguration : IEntityTypeConfiguration<Notification>
    {
        public void Configure(EntityTypeBuilder<Notification> builder)
        {
            builder.HasKey(e => e.NotificationId);
            builder.ToTable("notifications");

            builder.Property(e => e.NotificationId).HasColumnName("notification_id");
            builder.Property(e => e.UserId).HasColumnName("user_id");
            builder.Property(e => e.Title).IsRequired().HasMaxLength(200).HasColumnName("title");
            builder.Property(e => e.Message).IsRequired().HasColumnName("message");
            builder.Property(e => e.Type).HasMaxLength(50).HasColumnName("type");
            builder.Property(e => e.IsRead).HasDefaultValue(false).HasColumnName("is_read");
            builder.Property(e => e.CreatedAt).HasDefaultValueSql("GETDATE()").HasColumnName("created_at");

            builder.HasOne(d => d.User)
                   .WithMany() // Or add a collection in User entity if needed
                   .HasForeignKey(d => d.UserId)
                   .OnDelete(DeleteBehavior.Cascade)
                   .HasConstraintName("FK_notification_user");
        }
    }
}
