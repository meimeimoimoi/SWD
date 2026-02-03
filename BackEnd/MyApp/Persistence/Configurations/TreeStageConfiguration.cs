using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MyApp.Domain.Entities;

namespace MyApp.Persistence.Configurations
{
    public class TreeStageConfiguration : IEntityTypeConfiguration<TreeStage>
    {
        public void Configure(EntityTypeBuilder<TreeStage> entity) 
        {
            entity.HasKey(e => e.StageId).HasName("PK__tree_sta__CFC787609D9C4079");

            entity.ToTable("tree_stages");

            entity.Property(e => e.StageId).HasColumnName("stage_id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.StageName)
                .HasMaxLength(255)
                .IsUnicode(false)
                .HasColumnName("stage_name");
        }
    }
}
