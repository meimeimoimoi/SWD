using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MyApp.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "model_versions",
                columns: table => new
                {
                    model_version_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    model_name = table.Column<string>(type: "varchar(255)", unicode: false, maxLength: 255, nullable: false),
                    version = table.Column<string>(type: "varchar(50)", unicode: false, maxLength: 50, nullable: false),
                    model_type = table.Column<string>(type: "varchar(100)", unicode: false, maxLength: 100, nullable: true, defaultValue: "resnet18"),
                    description = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    file_path = table.Column<string>(type: "varchar(500)", unicode: false, maxLength: 500, nullable: true),
                    is_active = table.Column<bool>(type: "bit", nullable: true, defaultValue: true),
                    is_default = table.Column<bool>(type: "bit", nullable: true, defaultValue: false),
                    created_at = table.Column<DateTime>(type: "datetime2", nullable: true, defaultValueSql: "(getdate())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__model_ve__D71A143AFF269214", x => x.model_version_id);
                });

            migrationBuilder.CreateTable(
                name: "refresh_tokens",
                columns: table => new
                {
                    refresh_token_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    jti_hash = table.Column<string>(type: "varchar(255)", unicode: false, maxLength: 255, nullable: false),
                    is_revoked = table.Column<bool>(type: "bit", nullable: true, defaultValue: false),
                    created_at = table.Column<DateTime>(type: "datetime2", nullable: true, defaultValueSql: "(getdate())"),
                    updated_at = table.Column<DateTime>(type: "datetime2", nullable: true, defaultValueSql: "(getdate())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__refresh___B0A1F7C766869DA0", x => x.refresh_token_id);
                });

            migrationBuilder.CreateTable(
                name: "reset_password_tokens",
                columns: table => new
                {
                    reset_token_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    token_hash = table.Column<string>(type: "varchar(255)", unicode: false, maxLength: 255, nullable: false),
                    is_used = table.Column<bool>(type: "bit", nullable: true, defaultValue: false),
                    created_at = table.Column<DateTime>(type: "datetime2", nullable: true, defaultValueSql: "(getdate())"),
                    updated_at = table.Column<DateTime>(type: "datetime2", nullable: true, defaultValueSql: "(getdate())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__reset_pa__9D878429B4763C71", x => x.reset_token_id);
                });

            migrationBuilder.CreateTable(
                name: "system_settings",
                columns: table => new
                {
                    setting_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    setting_key = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    setting_value = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    description = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    setting_group = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    updated_at = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETDATE()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_system_settings", x => x.setting_id);
                });

            migrationBuilder.CreateTable(
                name: "tree_illnesses",
                columns: table => new
                {
                    illness_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    illness_name = table.Column<string>(type: "varchar(255)", unicode: false, maxLength: 255, nullable: true),
                    scientific_name = table.Column<string>(type: "varchar(255)", unicode: false, maxLength: 255, nullable: true),
                    description = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    symptoms = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    causes = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    severity = table.Column<string>(type: "varchar(50)", unicode: false, maxLength: 50, nullable: true),
                    created_at = table.Column<DateTime>(type: "datetime2", nullable: true, defaultValueSql: "(getdate())"),
                    updated_at = table.Column<DateTime>(type: "datetime2", nullable: true, defaultValueSql: "(getdate())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__tree_ill__F28BCB8F81CADBC2", x => x.illness_id);
                });

            migrationBuilder.CreateTable(
                name: "tree_stages",
                columns: table => new
                {
                    stage_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    stage_name = table.Column<string>(type: "varchar(255)", unicode: false, maxLength: 255, nullable: true),
                    description = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    created_at = table.Column<DateTime>(type: "datetime2", nullable: true, defaultValueSql: "(getdate())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__tree_sta__CFC787609D9C4079", x => x.stage_id);
                });

            migrationBuilder.CreateTable(
                name: "trees",
                columns: table => new
                {
                    tree_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    tree_name = table.Column<string>(type: "varchar(255)", unicode: false, maxLength: 255, nullable: true),
                    scientific_name = table.Column<string>(type: "varchar(255)", unicode: false, maxLength: 255, nullable: true),
                    description = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    image_path = table.Column<string>(type: "varchar(500)", unicode: false, maxLength: 500, nullable: true),
                    created_at = table.Column<DateTime>(type: "datetime2", nullable: true, defaultValueSql: "(getdate())"),
                    updated_at = table.Column<DateTime>(type: "datetime2", nullable: true, defaultValueSql: "(getdate())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__trees__B80FA69880146702", x => x.tree_id);
                });

            migrationBuilder.CreateTable(
                name: "users",
                columns: table => new
                {
                    user_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    username = table.Column<string>(type: "varchar(255)", unicode: false, maxLength: 255, nullable: false),
                    email = table.Column<string>(type: "varchar(255)", unicode: false, maxLength: 255, nullable: false),
                    password_hash = table.Column<string>(type: "varchar(255)", unicode: false, maxLength: 255, nullable: false),
                    first_name = table.Column<string>(type: "varchar(100)", unicode: false, maxLength: 100, nullable: true),
                    last_name = table.Column<string>(type: "varchar(100)", unicode: false, maxLength: 100, nullable: true),
                    phone = table.Column<string>(type: "varchar(20)", unicode: false, maxLength: 20, nullable: true),
                    profile_image_path = table.Column<string>(type: "varchar(500)", unicode: false, maxLength: 500, nullable: true),
                    account_status = table.Column<string>(type: "varchar(50)", unicode: false, maxLength: 50, nullable: true),
                    last_login_at = table.Column<DateTime>(type: "datetime2", nullable: true),
                    role = table.Column<string>(type: "varchar(50)", unicode: false, maxLength: 50, nullable: true),
                    created_at = table.Column<DateTime>(type: "datetime2", nullable: true, defaultValueSql: "(getdate())"),
                    updated_at = table.Column<DateTime>(type: "datetime2", nullable: true, defaultValueSql: "(getdate())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__users__B9BE370FEF387219", x => x.user_id);
                });

            migrationBuilder.CreateTable(
                name: "treatment_solutions",
                columns: table => new
                {
                    solution_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    illness_id = table.Column<int>(type: "int", nullable: false),
                    illness_stage_id = table.Column<int>(type: "int", nullable: true),
                    solution_name = table.Column<string>(type: "varchar(255)", unicode: false, maxLength: 255, nullable: true),
                    solution_type = table.Column<string>(type: "varchar(100)", unicode: false, maxLength: 100, nullable: true),
                    description = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    tree_stage_id = table.Column<int>(type: "int", nullable: false),
                    min_confidence = table.Column<decimal>(type: "decimal(5,4)", nullable: true),
                    priority = table.Column<int>(type: "int", nullable: true),
                    created_at = table.Column<DateTime>(type: "datetime2", nullable: true, defaultValueSql: "(getdate())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__treatmen__EA431C4996C956A8", x => x.solution_id);
                    table.ForeignKey(
                        name: "FK_treatment_illness",
                        column: x => x.illness_id,
                        principalTable: "tree_illnesses",
                        principalColumn: "illness_id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_treatment_stage",
                        column: x => x.tree_stage_id,
                        principalTable: "tree_stages",
                        principalColumn: "stage_id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "tree_illness_relationships",
                columns: table => new
                {
                    relationship_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    tree_id = table.Column<int>(type: "int", nullable: false),
                    illness_id = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__tree_ill__C0CFD5549315CE3C", x => x.relationship_id);
                    table.ForeignKey(
                        name: "FK_tree_illness_illness",
                        column: x => x.illness_id,
                        principalTable: "tree_illnesses",
                        principalColumn: "illness_id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_tree_illness_tree",
                        column: x => x.tree_id,
                        principalTable: "trees",
                        principalColumn: "tree_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "activity_logs",
                columns: table => new
                {
                    activity_log_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    user_id = table.Column<int>(type: "int", nullable: true),
                    action = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    entity_name = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: false),
                    entity_id = table.Column<string>(type: "nvarchar(100)", maxLength: 100, nullable: true),
                    description = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ip_address = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    created_at = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETDATE()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_activity_logs", x => x.activity_log_id);
                    table.ForeignKey(
                        name: "FK_activity_user",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "user_id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "image_uploads",
                columns: table => new
                {
                    upload_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    user_id = table.Column<int>(type: "int", nullable: false),
                    original_filename = table.Column<string>(type: "varchar(500)", unicode: false, maxLength: 500, nullable: true),
                    stored_filename = table.Column<string>(type: "varchar(500)", unicode: false, maxLength: 500, nullable: true),
                    file_path = table.Column<string>(type: "varchar(1000)", unicode: false, maxLength: 1000, nullable: true),
                    file_size = table.Column<long>(type: "bigint", nullable: true),
                    mime_type = table.Column<string>(type: "varchar(100)", unicode: false, maxLength: 100, nullable: true),
                    image_width = table.Column<int>(type: "int", nullable: true),
                    image_height = table.Column<int>(type: "int", nullable: true),
                    upload_status = table.Column<string>(type: "varchar(50)", unicode: false, maxLength: 50, nullable: true),
                    uploaded_at = table.Column<DateTime>(type: "datetime2", nullable: true, defaultValueSql: "(getdate())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__image_up__A13DEF58E7C35B7D", x => x.upload_id);
                    table.ForeignKey(
                        name: "FK_upload_user",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "user_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "notifications",
                columns: table => new
                {
                    notification_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    user_id = table.Column<int>(type: "int", nullable: false),
                    title = table.Column<string>(type: "nvarchar(200)", maxLength: 200, nullable: false),
                    message = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    type = table.Column<string>(type: "nvarchar(50)", maxLength: 50, nullable: true),
                    is_read = table.Column<bool>(type: "bit", nullable: false, defaultValue: false),
                    created_at = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "GETDATE()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_notifications", x => x.notification_id);
                    table.ForeignKey(
                        name: "FK_notification_user",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "user_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "solution_conditions",
                columns: table => new
                {
                    condition_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    solution_id = table.Column<int>(type: "int", nullable: false),
                    min_confidence = table.Column<decimal>(type: "decimal(5,4)", nullable: true),
                    weather_condition = table.Column<string>(type: "varchar(255)", unicode: false, maxLength: 255, nullable: true),
                    note = table.Column<string>(type: "nvarchar(max)", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__solution__8527AB15A8E109B8", x => x.condition_id);
                    table.ForeignKey(
                        name: "FK_condition_solution",
                        column: x => x.solution_id,
                        principalTable: "treatment_solutions",
                        principalColumn: "solution_id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "predictions",
                columns: table => new
                {
                    prediction_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    upload_id = table.Column<int>(type: "int", nullable: false),
                    model_version_id = table.Column<int>(type: "int", nullable: true),
                    tree_id = table.Column<int>(type: "int", nullable: true),
                    illness_id = table.Column<int>(type: "int", nullable: true),
                    predicted_class = table.Column<string>(type: "varchar(255)", unicode: false, maxLength: 255, nullable: true),
                    confidence_score = table.Column<decimal>(type: "decimal(5,4)", nullable: true),
                    top_n_predictions = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    processing_time_ms = table.Column<int>(type: "int", nullable: true),
                    created_at = table.Column<DateTime>(type: "datetime2", nullable: true, defaultValueSql: "(getdate())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__predicti__F1AE77BF0DB959B5", x => x.prediction_id);
                    table.ForeignKey(
                        name: "FK_prediction_illness",
                        column: x => x.illness_id,
                        principalTable: "tree_illnesses",
                        principalColumn: "illness_id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_prediction_model",
                        column: x => x.model_version_id,
                        principalTable: "model_versions",
                        principalColumn: "model_version_id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_prediction_tree",
                        column: x => x.tree_id,
                        principalTable: "trees",
                        principalColumn: "tree_id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_prediction_upload",
                        column: x => x.upload_id,
                        principalTable: "image_uploads",
                        principalColumn: "upload_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "processed_images",
                columns: table => new
                {
                    processed_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    upload_id = table.Column<int>(type: "int", nullable: false),
                    processed_file_path = table.Column<string>(type: "varchar(1000)", unicode: false, maxLength: 1000, nullable: true),
                    preprocessing_steps = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    created_at = table.Column<DateTime>(type: "datetime2", nullable: true, defaultValueSql: "(getdate())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__processe__EE42C2329266644E", x => x.processed_id);
                    table.ForeignKey(
                        name: "FK_processed_upload",
                        column: x => x.upload_id,
                        principalTable: "image_uploads",
                        principalColumn: "upload_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ratings",
                columns: table => new
                {
                    rating_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    prediction_id = table.Column<int>(type: "int", nullable: false),
                    rating = table.Column<string>(type: "varchar(50)", unicode: false, maxLength: 50, nullable: true),
                    comment = table.Column<string>(type: "varchar(1000)", unicode: false, maxLength: 1000, nullable: true),
                    created_at = table.Column<DateTime>(type: "datetime2", nullable: true, defaultValueSql: "(getdate())")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK__ratings__D35B278B2C910B23", x => x.rating_id);
                    table.ForeignKey(
                        name: "FK_rating_prediction",
                        column: x => x.prediction_id,
                        principalTable: "predictions",
                        principalColumn: "prediction_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_activity_logs_user_id",
                table: "activity_logs",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "idx_upload_status",
                table: "image_uploads",
                column: "upload_status");

            migrationBuilder.CreateIndex(
                name: "idx_uploaded_at",
                table: "image_uploads",
                column: "uploaded_at");

            migrationBuilder.CreateIndex(
                name: "idx_user_id",
                table: "image_uploads",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "idx_is_active",
                table: "model_versions",
                column: "is_active");

            migrationBuilder.CreateIndex(
                name: "idx_is_default",
                table: "model_versions",
                column: "is_default");

            migrationBuilder.CreateIndex(
                name: "unique_model_version",
                table: "model_versions",
                columns: new[] { "model_name", "version" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_notifications_user_id",
                table: "notifications",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "idx_created_at_pred",
                table: "predictions",
                column: "created_at");

            migrationBuilder.CreateIndex(
                name: "idx_illness_id_pred",
                table: "predictions",
                column: "illness_id");

            migrationBuilder.CreateIndex(
                name: "idx_model_version_id",
                table: "predictions",
                column: "model_version_id");

            migrationBuilder.CreateIndex(
                name: "idx_tree_id_pred",
                table: "predictions",
                column: "tree_id");

            migrationBuilder.CreateIndex(
                name: "idx_upload_id_pred",
                table: "predictions",
                column: "upload_id");

            migrationBuilder.CreateIndex(
                name: "idx_created_at",
                table: "processed_images",
                column: "created_at");

            migrationBuilder.CreateIndex(
                name: "idx_upload_id",
                table: "processed_images",
                column: "upload_id");

            migrationBuilder.CreateIndex(
                name: "idx_prediction_id",
                table: "ratings",
                column: "prediction_id");

            migrationBuilder.CreateIndex(
                name: "idx_refresh_revoked",
                table: "refresh_tokens",
                column: "is_revoked");

            migrationBuilder.CreateIndex(
                name: "UQ__refresh___11D28A4E0314AB34",
                table: "refresh_tokens",
                column: "jti_hash",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "idx_reset_used",
                table: "reset_password_tokens",
                column: "is_used");

            migrationBuilder.CreateIndex(
                name: "UQ__reset_pa__9F6BDB13B2CE46D6",
                table: "reset_password_tokens",
                column: "token_hash",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_solution_conditions_solution_id",
                table: "solution_conditions",
                column: "solution_id");

            migrationBuilder.CreateIndex(
                name: "IX_system_settings_setting_key",
                table: "system_settings",
                column: "setting_key",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_treatment_solutions_illness_id",
                table: "treatment_solutions",
                column: "illness_id");

            migrationBuilder.CreateIndex(
                name: "IX_treatment_solutions_tree_stage_id",
                table: "treatment_solutions",
                column: "tree_stage_id");

            migrationBuilder.CreateIndex(
                name: "idx_illness_id",
                table: "tree_illness_relationships",
                column: "illness_id");

            migrationBuilder.CreateIndex(
                name: "idx_tree_id",
                table: "tree_illness_relationships",
                column: "tree_id");

            migrationBuilder.CreateIndex(
                name: "unique_tree_illness",
                table: "tree_illness_relationships",
                columns: new[] { "tree_id", "illness_id" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "idx_illness_name",
                table: "tree_illnesses",
                column: "illness_name");

            migrationBuilder.CreateIndex(
                name: "idx_scientific_name",
                table: "trees",
                column: "scientific_name");

            migrationBuilder.CreateIndex(
                name: "idx_tree_name",
                table: "trees",
                column: "tree_name");

            migrationBuilder.CreateIndex(
                name: "idx_account_status",
                table: "users",
                column: "account_status");

            migrationBuilder.CreateIndex(
                name: "idx_email",
                table: "users",
                column: "email");

            migrationBuilder.CreateIndex(
                name: "idx_username",
                table: "users",
                column: "username");

            migrationBuilder.CreateIndex(
                name: "UQ__users__AB6E61643CD88CAE",
                table: "users",
                column: "email",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "UQ__users__F3DBC572B30B5982",
                table: "users",
                column: "username",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "activity_logs");

            migrationBuilder.DropTable(
                name: "notifications");

            migrationBuilder.DropTable(
                name: "processed_images");

            migrationBuilder.DropTable(
                name: "ratings");

            migrationBuilder.DropTable(
                name: "refresh_tokens");

            migrationBuilder.DropTable(
                name: "reset_password_tokens");

            migrationBuilder.DropTable(
                name: "solution_conditions");

            migrationBuilder.DropTable(
                name: "system_settings");

            migrationBuilder.DropTable(
                name: "tree_illness_relationships");

            migrationBuilder.DropTable(
                name: "predictions");

            migrationBuilder.DropTable(
                name: "treatment_solutions");

            migrationBuilder.DropTable(
                name: "model_versions");

            migrationBuilder.DropTable(
                name: "trees");

            migrationBuilder.DropTable(
                name: "image_uploads");

            migrationBuilder.DropTable(
                name: "tree_illnesses");

            migrationBuilder.DropTable(
                name: "tree_stages");

            migrationBuilder.DropTable(
                name: "users");
        }
    }
}
