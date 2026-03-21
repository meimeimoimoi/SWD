using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MyApp.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddEfMigrationsHistoryChecksum : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                """
                IF COL_LENGTH(N'dbo.__EFMigrationsHistory', N'Checksum') IS NULL
                    ALTER TABLE [__EFMigrationsHistory] ADD [Checksum] varchar(64) NULL;
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                """
                IF COL_LENGTH(N'dbo.__EFMigrationsHistory', N'Checksum') IS NOT NULL
                    ALTER TABLE [__EFMigrationsHistory] DROP COLUMN [Checksum];
                """);
        }
    }
}
