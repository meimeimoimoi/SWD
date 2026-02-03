using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MyApp.Domain.Entities;

namespace MyApp.Persistence.Configurations
{
    public class ImageUpLoadConfiguration : IEntityTypeConfiguration<ImageUpload>
    {
        public void Configure(EntityTypeBuilder<ImageUpload> entity)
        {
            entity.HasKey(e => e.UploadId).HasName("PK__image_up__A13DEF58E7C35B7D");

            entity.ToTable("image_uploads");

            entity.HasIndex(e => e.UploadStatus, "idx_upload_status");

            entity.HasIndex(e => e.UploadedAt, "idx_uploaded_at");

            entity.HasIndex(e => e.UserId, "idx_user_id");

            entity.Property(e => e.UploadId).HasColumnName("upload_id");
            entity.Property(e => e.FilePath)
                .HasMaxLength(1000)
                .IsUnicode(false)
                .HasColumnName("file_path");
            entity.Property(e => e.FileSize).HasColumnName("file_size");
            entity.Property(e => e.ImageHeight).HasColumnName("image_height");
            entity.Property(e => e.ImageWidth).HasColumnName("image_width");
            entity.Property(e => e.MimeType)
                .HasMaxLength(100)
                .IsUnicode(false)
                .HasColumnName("mime_type");
            entity.Property(e => e.OriginalFilename)
                .HasMaxLength(500)
                .IsUnicode(false)
                .HasColumnName("original_filename");
            entity.Property(e => e.StoredFilename)
                .HasMaxLength(500)
                .IsUnicode(false)
                .HasColumnName("stored_filename");
            entity.Property(e => e.UploadStatus)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("upload_status");
            entity.Property(e => e.UploadedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("uploaded_at");
            entity.Property(e => e.UserId).HasColumnName("user_id");

            entity.HasOne(d => d.User).WithMany(p => p.ImageUploads)
                .HasForeignKey(d => d.UserId)
                .HasConstraintName("FK_upload_user");
        }
    }
}
