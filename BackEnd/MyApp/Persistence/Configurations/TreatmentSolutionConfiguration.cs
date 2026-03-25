using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MyApp.Domain.Entities;

namespace MyApp.Persistence.Configurations
{
    public class TreatmentSolutionConfiguration : IEntityTypeConfiguration<TreatmentSolution>
    {
        public void Configure(EntityTypeBuilder<TreatmentSolution> entity)
        {
            entity.HasKey(e => e.SolutionId).HasName("PK__treatmen__EA431C4996C956A8");

            entity.ToTable("treatment_solutions");

            entity.Property(e => e.SolutionId).HasColumnName("solution_id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.IllnessId).HasColumnName("illness_id");
            entity.Property(e => e.IllnessStageId).HasColumnName("illness_stage_id");
            entity.Property(e => e.MinConfidence)
                .HasColumnType("decimal(5, 4)")
                .HasColumnName("min_confidence");
            entity.Property(e => e.Priority).HasColumnName("priority");
            entity.Property(e => e.SolutionName)
                .HasMaxLength(255)
                .IsUnicode(true)
                .HasColumnName("solution_name");
            entity.Property(e => e.SolutionType)
                .HasMaxLength(100)
                .IsUnicode(true)
                .HasColumnName("solution_type");
            // Some deployments may not have optional columns/tables (shoppe_url/instructions/ingredients/updated_at/solution_images).
            // To keep the application running without modifying the database, ignore these CLR properties so EF Core
            // does not expect the corresponding columns/tables at runtime.
            entity.Ignore(e => e.ShoppeUrl);
            entity.Ignore(e => e.Instructions);
            entity.Ignore(e => e.UpdatedAt);
            entity.Ignore(e => e.Ingredients);
            entity.Ignore(e => e.Images);
            entity.Property(e => e.TreeStageId).HasColumnName("tree_stage_id");

            entity.HasOne(d => d.Illness).WithMany(p => p.TreatmentSolutions)
                .HasForeignKey(d => d.IllnessId)
                .OnDelete(DeleteBehavior.Restrict)
                .HasConstraintName("FK_treatment_illness");

            entity.HasOne(d => d.TreeStage).WithMany(p => p.TreatmentSolutions)
                .HasForeignKey(d => d.TreeStageId)
                .OnDelete(DeleteBehavior.Restrict)
                .HasConstraintName("FK_treatment_stage");
        }
    }
}
