using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MyApp.Domain.Entities;

namespace MyApp.Persistence.Configurations
{
    public class RatingConfiguration : IEntityTypeConfiguration<Rating>
    {
        public void Configure(EntityTypeBuilder<Rating> entity)
        {
            entity.HasKey(e => e.RatingId).HasName("PK__ratings__D35B278B2C910B23");

            entity.ToTable("ratings");

            entity.HasIndex(e => e.PredictionId, "idx_prediction_id");

            entity.Property(e => e.RatingId).HasColumnName("rating_id");
            entity.Property(e => e.Comment)
                .HasMaxLength(1000)
                .IsUnicode(false)
                .HasColumnName("comment");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.PredictionId).HasColumnName("prediction_id");
            entity.Property(e => e.Rating1)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasColumnName("rating");

            entity.HasOne(d => d.Prediction).WithMany(p => p.Ratings)
                .HasForeignKey(d => d.PredictionId)
                .HasConstraintName("FK_rating_prediction");
        }
    }
}
