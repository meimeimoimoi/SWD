using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MyApp.Persistence.Migrations
{
    public partial class SeedInitialMasterData : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                """
                IF NOT EXISTS (SELECT 1 FROM [users] WHERE [username] = N'admin')
                BEGIN
                    INSERT INTO [users] ([username], [email], [password_hash], [first_name], [last_name], [phone], [profile_image_path], [account_status], [last_login_at], [role], [created_at], [updated_at])
                    VALUES (N'admin', N'admin@swd.com', N'$2a$11$61GJCQQAT3CQOcv4hIRdAeTmRUYOKaqoSxz/ID/iyP7xEdotkWe76', N'System', N'Administrator', NULL, NULL, N'Active', NULL, N'Admin', GETUTCDATE(), GETUTCDATE());
                END

                IF NOT EXISTS (SELECT 1 FROM [users] WHERE [username] = N'user1')
                BEGIN
                    INSERT INTO [users] ([username], [email], [password_hash], [first_name], [last_name], [phone], [profile_image_path], [account_status], [last_login_at], [role], [created_at], [updated_at])
                    VALUES (N'user1', N'user1@swd.com', N'$2a$11$LP4218Hs.UhYigmBRRXqG.iSgjzNHPYwEq7zJLQNv.2X0R6pZI3cq', N'Demo', N'User One', NULL, NULL, N'Active', NULL, N'User', GETUTCDATE(), GETUTCDATE());
                END

                IF NOT EXISTS (SELECT 1 FROM [users] WHERE [username] = N'user2')
                BEGIN
                    INSERT INTO [users] ([username], [email], [password_hash], [first_name], [last_name], [phone], [profile_image_path], [account_status], [last_login_at], [role], [created_at], [updated_at])
                    VALUES (N'user2', N'user2@swd.com', N'$2a$11$Aq7eea8x.M94D00dZO6rw.AvgebOJjWh/lIgl0bu0.Ip/EGW//NW.', N'Demo', N'User Two', NULL, NULL, N'Active', NULL, N'User', GETUTCDATE(), GETUTCDATE());
                END

                IF NOT EXISTS (SELECT 1 FROM [users] WHERE [username] = N'user3')
                BEGIN
                    INSERT INTO [users] ([username], [email], [password_hash], [first_name], [last_name], [phone], [profile_image_path], [account_status], [last_login_at], [role], [created_at], [updated_at])
                    VALUES (N'user3', N'user3@swd.com', N'$2a$11$/S04SdZcd2mt8GksRINv5OG6IistEr.eGIlbwA5mVmfvpVcA2i0KW', N'Demo', N'User Three', NULL, NULL, N'Active', NULL, N'User', GETUTCDATE(), GETUTCDATE());
                END
                """);
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                """
                DELETE FROM [users] WHERE [username] IN (N'user1', N'user2', N'user3');
                DELETE FROM [users] WHERE [username] = N'admin';
                """);
        }
    }
}
