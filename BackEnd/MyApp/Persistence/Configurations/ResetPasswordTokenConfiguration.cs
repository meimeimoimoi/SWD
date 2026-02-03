using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MyApp.Domain.Entities;

namespace MyApp.Persistence.Configurations
{
    public class ResetPasswordTokenConfiguration : IEntityTypeConfiguration<ResetPasswordToken>
    {
        public void Configure(EntityTypeBuilder<ResetPasswordToken> entity)
        {
            entity.HasKey(e => e.ResetTokenId).HasName("PK__reset_pa__9D878429B4763C71");

            entity.ToTable("reset_password_tokens");

            entity.HasIndex(e => e.TokenHash, "UQ__reset_pa__9F6BDB13B2CE46D6").IsUnique();

            entity.HasIndex(e => e.IsUsed, "idx_reset_used");

            entity.Property(e => e.ResetTokenId).HasColumnName("reset_token_id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.IsUsed)
                .HasDefaultValue(false)
                .HasColumnName("is_used");
            entity.Property(e => e.TokenHash)
                .HasMaxLength(255)
                .IsUnicode(false)
                .HasColumnName("token_hash");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("updated_at");
        }
    }
}
