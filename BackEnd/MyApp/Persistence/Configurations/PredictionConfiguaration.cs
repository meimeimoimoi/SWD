using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MyApp.Domain.Entities;

namespace MyApp.Persistence.Configurations
{
    public class PredictionConfiguaration : IEntityTypeConfiguration<Prediction>
    {
        public void Configure(EntityTypeBuilder<Prediction> entity)
        {
            entity.HasKey(e => e.PredictionId).HasName("PK__predicti__F1AE77BF0DB959B5");

            entity.ToTable("predictions");

            entity.HasIndex(e => e.CreatedAt, "idx_created_at_pred");

            entity.HasIndex(e => e.IllnessId, "idx_illness_id_pred");

            entity.HasIndex(e => e.ModelVersionId, "idx_model_version_id");

            entity.HasIndex(e => e.TreeId, "idx_tree_id_pred");

            entity.HasIndex(e => e.UploadId, "idx_upload_id_pred");

            entity.Property(e => e.PredictionId).HasColumnName("prediction_id");
            entity.Property(e => e.ConfidenceScore)
                .HasColumnType("decimal(5, 4)")
                .HasColumnName("confidence_score");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnName("created_at");
            entity.Property(e => e.IllnessId).HasColumnName("illness_id");
            entity.Property(e => e.ModelVersionId).HasColumnName("model_version_id");
            entity.Property(e => e.PredictedClass)
                .HasMaxLength(255)
                .IsUnicode(false)
                .HasColumnName("predicted_class");
            entity.Property(e => e.ProcessingTimeMs).HasColumnName("processing_time_ms");
            entity.Property(e => e.TopNPredictions).HasColumnName("top_n_predictions");
            entity.Property(e => e.TreeId).HasColumnName("tree_id");
            entity.Property(e => e.UploadId).HasColumnName("upload_id");

            entity.HasOne(d => d.Illness).WithMany(p => p.Predictions)
                .HasForeignKey(d => d.IllnessId)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("FK_prediction_illness");

            entity.HasOne(d => d.ModelVersion).WithMany(p => p.Predictions)
                .HasForeignKey(d => d.ModelVersionId)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("FK_prediction_model");

            entity.HasOne(d => d.Tree).WithMany(p => p.Predictions)
                .HasForeignKey(d => d.TreeId)
                .OnDelete(DeleteBehavior.SetNull)
                .HasConstraintName("FK_prediction_tree");

            entity.HasOne(d => d.Upload).WithMany(p => p.Predictions)
                .HasForeignKey(d => d.UploadId)
                .HasConstraintName("FK_prediction_upload");
        }
    }
}
