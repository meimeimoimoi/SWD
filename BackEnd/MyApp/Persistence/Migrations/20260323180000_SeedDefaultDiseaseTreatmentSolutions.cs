using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MyApp.Persistence.Migrations
{
    /// <summary>
    /// Seeds default <c>tree_stages</c> row (FK for solutions), default <c>tree_illnesses</c> rows for
    /// rice_disease_v3 ONNX labels if missing, and baseline <c>treatment_solutions</c> (treatment + medicine).
    /// Uses <c>priority = 9000</c> for seeded solutions so Down can remove them safely.
    /// Idempotent: for each disease, inserts the full pair only when that illness has no solutions yet.
    /// </summary>
    public partial class SeedDefaultDiseaseTreatmentSolutions : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                """
                IF NOT EXISTS (SELECT 1 FROM [tree_stages])
                BEGIN
                    INSERT INTO [tree_stages] ([stage_name], [description], [created_at])
                    VALUES (
                        N'General (all growth stages)',
                        N'Default stage for treatments not tied to a specific phenological stage.',
                        GETUTCDATE());
                END;

                DECLARE @DefaultStageId INT = (SELECT TOP (1) [stage_id] FROM [tree_stages] ORDER BY [stage_id]);

                IF NOT EXISTS (SELECT 1 FROM [tree_illnesses] WHERE [illness_name] = N'Bacterial Leaf Blight')
                    INSERT INTO [tree_illnesses] ([illness_name], [created_at], [updated_at])
                    VALUES (N'Bacterial Leaf Blight', GETUTCDATE(), GETUTCDATE());

                IF NOT EXISTS (SELECT 1 FROM [tree_illnesses] WHERE [illness_name] = N'Brown Spot')
                    INSERT INTO [tree_illnesses] ([illness_name], [created_at], [updated_at])
                    VALUES (N'Brown Spot', GETUTCDATE(), GETUTCDATE());

                IF NOT EXISTS (SELECT 1 FROM [tree_illnesses] WHERE [illness_name] = N'Healthy Rice Leaf')
                    INSERT INTO [tree_illnesses] ([illness_name], [created_at], [updated_at])
                    VALUES (N'Healthy Rice Leaf', GETUTCDATE(), GETUTCDATE());

                IF NOT EXISTS (SELECT 1 FROM [tree_illnesses] WHERE [illness_name] = N'Leaf Blast')
                    INSERT INTO [tree_illnesses] ([illness_name], [created_at], [updated_at])
                    VALUES (N'Leaf Blast', GETUTCDATE(), GETUTCDATE());

                UPDATE [tree_illnesses] SET
                    [scientific_name] = N'Xanthomonas oryzae pv. oryzae',
                    [description] = N'Bacterial leaf blight causes water-soaked lesions along veins; severe infections reduce photosynthetic area and yield under warm, humid weather.',
                    [symptoms] = N'Water-soaked stripes along leaf veins, yellow halos, bacterial exudate on cuts; older lesions tan and dry.',
                    [causes] = N'Xanthomonas oryzae pv. oryzae; spread by splash, wind-driven rain, tools, and infected seed.',
                    [severity] = N'High'
                WHERE [illness_name] = N'Bacterial Leaf Blight' AND [description] IS NULL;

                UPDATE [tree_illnesses] SET
                    [scientific_name] = N'Bipolaris oryzae',
                    [description] = N'Brown spot produces small oval brown lesions; common under nutrient stress and humid canopies.',
                    [symptoms] = N'Circular to oval brown spots with darker borders on leaves; may coalesce on susceptible varieties.',
                    [causes] = N'Bipolaris oryzae (Helminthosporium); favored by high humidity, potassium deficiency, and dense stands.',
                    [severity] = N'Medium'
                WHERE [illness_name] = N'Brown Spot' AND [description] IS NULL;

                UPDATE [tree_illnesses] SET
                    [scientific_name] = N'—',
                    [description] = N'No disease detected; tissue appears healthy. Continue good agronomy and scouting.',
                    [symptoms] = N'Uniform green tissue without diagnostic disease lesions.',
                    [causes] = N'Not applicable.',
                    [severity] = N'None'
                WHERE [illness_name] = N'Healthy Rice Leaf' AND [description] IS NULL;

                UPDATE [tree_illnesses] SET
                    [scientific_name] = N'Magnaporthe oryzae',
                    [description] = N'Blast causes diamond-shaped necrotic lesions and can attack leaves, nodes, and panicles; major yield risk.',
                    [symptoms] = N'Spindle-shaped lesions with brown borders and gray centers; collar and neck blast affect grain fill.',
                    [causes] = N'Magnaporthe oryzae; spread by airborne spores; worsened by excess nitrogen and prolonged leaf wetness.',
                    [severity] = N'High'
                WHERE [illness_name] = N'Leaf Blast' AND [description] IS NULL;

                IF NOT EXISTS (
                    SELECT 1 FROM [treatment_solutions] s
                    INNER JOIN [tree_illnesses] i ON s.[illness_id] = i.[illness_id]
                    WHERE i.[illness_name] = N'Bacterial Leaf Blight')
                BEGIN
                    INSERT INTO [treatment_solutions] ([illness_id], [illness_stage_id], [solution_name], [solution_type], [description], [tree_stage_id], [min_confidence], [priority], [created_at])
                    SELECT i.[illness_id], NULL, N'Sanitation & resistant cultivars', N'treatment',
                        N'Use certified seed; destroy infected stubble; avoid excess nitrogen and prolonged leaf wetness; choose BLB-tolerant or locally adapted resistant varieties where available.',
                        @DefaultStageId, NULL, 9000, GETUTCDATE()
                    FROM [tree_illnesses] i WHERE i.[illness_name] = N'Bacterial Leaf Blight';

                    INSERT INTO [treatment_solutions] ([illness_id], [illness_stage_id], [solution_name], [solution_type], [description], [tree_stage_id], [min_confidence], [priority], [created_at])
                    SELECT i.[illness_id], NULL, N'Copper / registered bactericides', N'medicine',
                        N'Apply copper-based or other bactericides registered for rice only per local label and pre-harvest interval; rotate modes of action where applicable.',
                        @DefaultStageId, NULL, 9000, GETUTCDATE()
                    FROM [tree_illnesses] i WHERE i.[illness_name] = N'Bacterial Leaf Blight';
                END;

                IF NOT EXISTS (
                    SELECT 1 FROM [treatment_solutions] s
                    INNER JOIN [tree_illnesses] i ON s.[illness_id] = i.[illness_id]
                    WHERE i.[illness_name] = N'Brown Spot')
                BEGIN
                    INSERT INTO [treatment_solutions] ([illness_id], [illness_stage_id], [solution_name], [solution_type], [description], [tree_stage_id], [min_confidence], [priority], [created_at])
                    SELECT i.[illness_id], NULL, N'Nutrition & canopy management', N'treatment',
                        N'Maintain balanced NPK (especially potassium); avoid excessive nitrogen; improve air movement; remove heavily infected debris after harvest.',
                        @DefaultStageId, NULL, 9000, GETUTCDATE()
                    FROM [tree_illnesses] i WHERE i.[illness_name] = N'Brown Spot';

                    INSERT INTO [treatment_solutions] ([illness_id], [illness_stage_id], [solution_name], [solution_type], [description], [tree_stage_id], [min_confidence], [priority], [created_at])
                    SELECT i.[illness_id], NULL, N'Fungicides (strobilurin / triazole)', N'medicine',
                        N'Apply fungicides registered for brown spot when thresholds are met; follow label rates and rotate FRAC groups to slow resistance.',
                        @DefaultStageId, NULL, 9000, GETUTCDATE()
                    FROM [tree_illnesses] i WHERE i.[illness_name] = N'Brown Spot';
                END;

                IF NOT EXISTS (
                    SELECT 1 FROM [treatment_solutions] s
                    INNER JOIN [tree_illnesses] i ON s.[illness_id] = i.[illness_id]
                    WHERE i.[illness_name] = N'Healthy Rice Leaf')
                BEGIN
                    INSERT INTO [treatment_solutions] ([illness_id], [illness_stage_id], [solution_name], [solution_type], [description], [tree_stage_id], [min_confidence], [priority], [created_at])
                    SELECT i.[illness_id], NULL, N'Good agronomy & scouting', N'treatment',
                        N'Keep proper water depth, split nitrogen, and scout weekly; remove off-types and monitor for early blast or blight signs.',
                        @DefaultStageId, NULL, 9000, GETUTCDATE()
                    FROM [tree_illnesses] i WHERE i.[illness_name] = N'Healthy Rice Leaf';

                    INSERT INTO [treatment_solutions] ([illness_id], [illness_stage_id], [solution_name], [solution_type], [description], [tree_stage_id], [min_confidence], [priority], [created_at])
                    SELECT i.[illness_id], NULL, N'No chemical treatment needed', N'medicine',
                        N'Healthy tissue does not require fungicide or bactericide; avoid unnecessary applications to protect beneficials and reduce resistance pressure.',
                        @DefaultStageId, NULL, 9000, GETUTCDATE()
                    FROM [tree_illnesses] i WHERE i.[illness_name] = N'Healthy Rice Leaf';
                END;

                IF NOT EXISTS (
                    SELECT 1 FROM [treatment_solutions] s
                    INNER JOIN [tree_illnesses] i ON s.[illness_id] = i.[illness_id]
                    WHERE i.[illness_name] = N'Leaf Blast')
                BEGIN
                    INSERT INTO [treatment_solutions] ([illness_id], [illness_stage_id], [solution_name], [solution_type], [description], [tree_stage_id], [min_confidence], [priority], [created_at])
                    SELECT i.[illness_id], NULL, N'Blast-resistant varieties & N management', N'treatment',
                        N'Use clean seed and seed treatment where available; moderate nitrogen rates; avoid frequent shallow flooding that keeps leaves wet; favor resistant lines for high-risk fields.',
                        @DefaultStageId, NULL, 9000, GETUTCDATE()
                    FROM [tree_illnesses] i WHERE i.[illness_name] = N'Leaf Blast';

                    INSERT INTO [treatment_solutions] ([illness_id], [illness_stage_id], [solution_name], [solution_type], [description], [tree_stage_id], [min_confidence], [priority], [created_at])
                    SELECT i.[illness_id], NULL, N'Fungicides (QoI / SDHI / triazole)', N'medicine',
                        N'Apply registered blast fungicides at early lesion or weather-risk timing; rotate FRAC groups and respect resistance management guidelines.',
                        @DefaultStageId, NULL, 9000, GETUTCDATE()
                    FROM [tree_illnesses] i WHERE i.[illness_name] = N'Leaf Blast';
                END;
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                """
                DELETE s
                FROM [treatment_solutions] s
                INNER JOIN [tree_illnesses] i ON s.[illness_id] = i.[illness_id]
                WHERE i.[illness_name] IN (
                    N'Bacterial Leaf Blight',
                    N'Brown Spot',
                    N'Healthy Rice Leaf',
                    N'Leaf Blast')
                  AND s.[priority] = 9000;
                """);
        }
    }
}
