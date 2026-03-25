using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MyApp.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddTreatmentSolutionFieldsAndImages : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "instructions",
                table: "treatment_solutions",
                type: "nvarchar(max)",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "shoppe_url",
                table: "treatment_solutions",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "updated_at",
                table: "treatment_solutions",
                type: "datetime2",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "solution_images",
                columns: table => new
                {
                    image_id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    solution_id = table.Column<int>(type: "int", nullable: false),
                    image_url = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    display_order = table.Column<int>(type: "int", nullable: false),
                    uploaded_at = table.Column<DateTime>(type: "datetime2", nullable: false, defaultValueSql: "(getdate())"),
                    file_size = table.Column<long>(type: "bigint", nullable: true),
                    width = table.Column<int>(type: "int", nullable: true),
                    height = table.Column<int>(type: "int", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_solution_images", x => x.image_id);
                    table.ForeignKey(
                        name: "FK_solution_images_treatment_solutions",
                        column: x => x.solution_id,
                        principalTable: "treatment_solutions",
                        principalColumn: "solution_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_solution_images_solution_id",
                table: "solution_images",
                column: "solution_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "solution_images");

            migrationBuilder.DropColumn(
                name: "instructions",
                table: "treatment_solutions");

            migrationBuilder.DropColumn(
                name: "shoppe_url",
                table: "treatment_solutions");

            migrationBuilder.DropColumn(
                name: "updated_at",
                table: "treatment_solutions");
        }
    }
}
