using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MyApp.Persistence.Migrations
{
    public partial class AddEfMigrationsHistoryChecksum : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                """
                IF COL_LENGTH(N'dbo.__EFMigrationsHistory', N'Checksum') IS NULL
                    ALTER TABLE [__EFMigrationsHistory] ADD [Checksum] varchar(64) NULL;
                """);
        }

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
