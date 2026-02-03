using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MyApp.Domain.Entities;

namespace MyApp.Persistence.Configurations
{
    public class TreeConfiguration : IEntityTypeConfiguration<Tree>
    {
        public void Configure(EntityTypeBuilder<Tree> entity)
        {
            entity.HasKey(e => e.TreeId).HasName("PK__trees__B80FA69880146702");

            entity.ToTable("trees", tb => tb.HasTrigger("trg_trees_updated_at"));

            entity.HasIndex(e => e.ScientificName, "idx_scientific_name");

            entity.HasIndex(e => e.TreeName, "idx_tree_name");

            entity.Property(e => e.TreeId).HasColumnName("tree_id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.ImagePath)
                .HasMaxLength(500)
                .IsUnicode(false)
                .HasColumnName("image_path");
            entity.Property(e => e.ScientificName)
                .HasMaxLength(255)
                .IsUnicode(false)
                .HasColumnName("scientific_name");
            entity.Property(e => e.TreeName)
                .HasMaxLength(255)
                .IsUnicode(false)
                .HasColumnName("tree_name");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("updated_at");
        }
    }
}
