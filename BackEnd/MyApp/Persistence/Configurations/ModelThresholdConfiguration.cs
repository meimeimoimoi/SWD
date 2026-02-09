using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MyApp.Domain.Entities;

namespace MyApp.Persistence.Configurations;

public class ModelThresholdConfiguration : IEntityTypeConfiguration<ModelThreshold>
{
    public void Configure(EntityTypeBuilder<ModelThreshold> builder)
    {
        builder.HasKey(e => e.ThresholdId);
        
        builder.ToTable("model_thresholds");

        builder.Property(e => e.ThresholdId)
            .HasColumnName("threshold_id");
            
        builder.Property(e => e.ModelVersionId)
            .HasColumnName("model_version_id");
            
        builder.Property(e => e.MinConfidence)
            .HasColumnType("decimal(5, 4)")
            .HasColumnName("min_confidence");
            
        builder.Property(e => e.CreatedAt)
            .HasDefaultValueSql("CURRENT_TIMESTAMP")
            .HasColumnName("created_at");

        builder.HasOne(d => d.ModelVersion)
            .WithMany()
            .HasForeignKey(d => d.ModelVersionId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
