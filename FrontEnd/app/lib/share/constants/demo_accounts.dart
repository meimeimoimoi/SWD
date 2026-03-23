/// Seeded demo credentials for quick login (also used by backend seed data).
abstract final class DemoAccounts {
  static const userEmail = 'User1@swd.com';
  static const userPassword = 'User123!';
  static const adminEmail = 'Admin@swd.com';
  static const adminPassword = 'Admin123!';

  static bool isUserDemo(String email) =>
      email.trim().toLowerCase() == userEmail.toLowerCase();

  static bool isAdminDemo(String email) =>
      email.trim().toLowerCase() == adminEmail.toLowerCase();
}
