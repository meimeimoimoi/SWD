using System;

namespace SWD.Shared.Helpers
{
    public static class DateTimeHelper
    {
        public static DateTime GetCurrentTime()
        {
            return DateTime.UtcNow;
        }

        public static string FormatDate(DateTime date, string format = "yyyy-MM-dd")
        {
            return date.ToString(format);
        }
    }
}
