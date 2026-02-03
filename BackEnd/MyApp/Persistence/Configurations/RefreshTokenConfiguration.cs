using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MyApp.Domain.Entities;

namespace MyApp.Persistence.Configurations
{
    public class RefreshTokenConfiguration : IEntityTypeConfiguration<RefreshToken>
    {
        public void Configure(EntityTypeBuilder<RefreshToken> entity)
        {
            entity.HasKey(e => e.RefreshTokenId).HasName("PK__refresh___B0A1F7C766869DA0");

            entity.ToTable("refresh_tokens");

            entity.HasIndex(e => e.JtiHash, "UQ__refresh___11D28A4E0314AB34").IsUnique();

            entity.HasIndex(e => e.IsRevoked, "idx_refresh_revoked");

            entity.Property(e => e.RefreshTokenId).HasColumnName("refresh_token_id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.IsRevoked)
                .HasDefaultValue(false)
                .HasColumnName("is_revoked");
            entity.Property(e => e.JtiHash)
                .HasMaxLength(255)
                .IsUnicode(false)
                .HasColumnName("jti_hash");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("updated_at");
        }
    }
}
