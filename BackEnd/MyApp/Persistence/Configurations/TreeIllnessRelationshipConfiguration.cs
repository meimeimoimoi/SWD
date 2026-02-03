using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MyApp.Domain.Entities;

namespace MyApp.Persistence.Configurations
{
    public class TreeIllnessRelationshipConfiguration : IEntityTypeConfiguration<TreeIllnessRelationship>
    {
        public void Configure(EntityTypeBuilder<TreeIllnessRelationship> entity) 
        {
            entity.HasKey(e => e.RelationshipId).HasName("PK__tree_ill__C0CFD5549315CE3C");

            entity.ToTable("tree_illness_relationships");

            entity.HasIndex(e => e.IllnessId, "idx_illness_id");

            entity.HasIndex(e => e.TreeId, "idx_tree_id");

            entity.HasIndex(e => new { e.TreeId, e.IllnessId }, "unique_tree_illness").IsUnique();

            entity.Property(e => e.RelationshipId).HasColumnName("relationship_id");
            entity.Property(e => e.IllnessId).HasColumnName("illness_id");
            entity.Property(e => e.TreeId).HasColumnName("tree_id");

            entity.HasOne(d => d.Illness).WithMany(p => p.TreeIllnessRelationships)
                .HasForeignKey(d => d.IllnessId)
                .HasConstraintName("FK_tree_illness_illness");

            entity.HasOne(d => d.Tree).WithMany(p => p.TreeIllnessRelationships)
                .HasForeignKey(d => d.TreeId)
                .HasConstraintName("FK_tree_illness_tree");
        }
    }
}
