using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MyApp.Domain.Entities;

namespace MyApp.Persistence.Configurations
{
    public class TreeIllnessConfiguration : IEntityTypeConfiguration<TreeIllness>
    {
        public void Configure(EntityTypeBuilder<TreeIllness> entity)
        {
            entity.HasKey(e => e.IllnessId).HasName("PK__tree_ill__F28BCB8F81CADBC2");

            entity.ToTable("tree_illnesses", tb => tb.HasTrigger("trg_tree_illnesses_updated_at"));

            entity.HasIndex(e => e.IllnessName, "idx_illness_name");

            entity.Property(e => e.IllnessId).HasColumnName("illness_id");
            entity.Property(e => e.Causes).HasColumnName("causes");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.IllnessName)
                .HasMaxLength(255)
                .IsUnicode(false)
                .HasColumnName("illness_name");
            entity.Property(e => e.ScientificName)
                .HasMaxLength(255)
                .IsUnicode(false)
                .HasColumnName("scientific_name");
            entity.Property(e => e.Severity)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("severity");
            entity.Property(e => e.Symptoms).HasColumnName("symptoms");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("updated_at");
        }
    }
}
