using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MyApp.Domain.Entities;

namespace MyApp.Persistence.Configurations
{
    public class ModelVersionConfiguration : IEntityTypeConfiguration<ModelVersion>
    {
        public void Configure(EntityTypeBuilder<ModelVersion> entity)
        {
            entity.HasKey(e => e.ModelVersionId).HasName("PK__model_ve__D71A143AFF269214");

            entity.ToTable("model_versions");

            entity.HasIndex(e => e.IsActive, "idx_is_active");

            entity.HasIndex(e => e.IsDefault, "idx_is_default");

            entity.HasIndex(e => new { e.ModelName, e.Version }, "unique_model_version").IsUnique();

            entity.Property(e => e.ModelVersionId).HasColumnName("model_version_id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.IsActive)
                .HasDefaultValue(true)
                .HasColumnName("is_active");
            entity.Property(e => e.IsDefault)
                .HasDefaultValue(false)
                .HasColumnName("is_default");
            entity.Property(e => e.ModelName)
                .HasMaxLength(255)
                .IsUnicode(false)
                .HasColumnName("model_name");
            entity.Property(e => e.ModelType)
                .HasMaxLength(100)
                .IsUnicode(false)
                .HasDefaultValue("resnet18")
                .HasColumnName("model_type");
            entity.Property(e => e.Version)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("version");
        }
    }
}
