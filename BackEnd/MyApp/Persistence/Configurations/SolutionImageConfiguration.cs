using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MyApp.Domain.Entities;

namespace MyApp.Persistence.Configurations
{
    public class SolutionImageConfiguration : IEntityTypeConfiguration<SolutionImage>
    {
        public void Configure(EntityTypeBuilder<SolutionImage> entity)
        {
            entity.HasKey(e => e.ImageId).HasName("PK_solution_images");

            entity.ToTable("solution_images");

            entity.Property(e => e.ImageId).HasColumnName("image_id");
            entity.Property(e => e.SolutionId).HasColumnName("solution_id");
            entity.Property(e => e.ImageUrl)
                .IsUnicode(true)
                .HasColumnName("image_url");
            entity.Property(e => e.DisplayOrder).HasColumnName("display_order");
            entity.Property(e => e.UploadedAt)
                .HasColumnName("uploaded_at")
                .HasDefaultValueSql("(getdate())");
            entity.Property(e => e.FileSize).HasColumnName("file_size");
            entity.Property(e => e.Width).HasColumnName("width");
            entity.Property(e => e.Height).HasColumnName("height");

            entity.HasOne(d => d.Solution).WithMany(p => p.Images)
                .HasForeignKey(d => d.SolutionId)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK_solution_images_treatment_solutions");
        }
    }
}
