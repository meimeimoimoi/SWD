using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MyApp.Domain.Entities;

namespace MyApp.Persistence.Configurations
{
    public class SolutionConditionConfiguration : IEntityTypeConfiguration<SolutionCondition>
    {
        public void Configure(EntityTypeBuilder<SolutionCondition> entity)
        {
            entity.HasKey(e => e.ConditionId).HasName("PK__solution__8527AB15A8E109B8");

            entity.ToTable("solution_conditions");

            entity.Property(e => e.ConditionId).HasColumnName("condition_id");
            entity.Property(e => e.MinConfidence)
                .HasColumnType("decimal(5, 4)")
                .HasColumnName("min_confidence");
            entity.Property(e => e.Note).HasColumnName("note");
            entity.Property(e => e.SolutionId).HasColumnName("solution_id");
            entity.Property(e => e.WeatherCondition)
                .HasMaxLength(255)
                .IsUnicode(false)
                .HasColumnName("weather_condition");

            entity.HasOne(d => d.Solution).WithMany(p => p.SolutionConditions)
                .HasForeignKey(d => d.SolutionId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_condition_solution");
        }
    }
}
