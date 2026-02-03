using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MyApp.Domain.Entities;

namespace MyApp.Persistence.Configurations
{
    public class ProcessedImageConfiguration : IEntityTypeConfiguration<ProcessedImage>
    {
        public void Configure(EntityTypeBuilder<ProcessedImage> entity) 
        {
            entity.HasKey(e => e.ProcessedId).HasName("PK__processe__EE42C2329266644E");

            entity.ToTable("processed_images");

            entity.HasIndex(e => e.CreatedAt, "idx_created_at");

            entity.HasIndex(e => e.UploadId, "idx_upload_id");

            entity.Property(e => e.ProcessedId).HasColumnName("processed_id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.PreprocessingSteps).HasColumnName("preprocessing_steps");
            entity.Property(e => e.ProcessedFilePath)
                .HasMaxLength(1000)
                .IsUnicode(false)
                .HasColumnName("processed_file_path");
            entity.Property(e => e.UploadId).HasColumnName("upload_id");

            entity.HasOne(d => d.Upload).WithMany(p => p.ProcessedImages)
                .HasForeignKey(d => d.UploadId)
                .HasConstraintName("FK_processed_upload");
        }
    }
}
