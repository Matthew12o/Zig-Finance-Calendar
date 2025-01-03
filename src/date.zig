const std = @import("std");
const Allocator = std.mem.Allocator;

/// Seconds per day
pub const SECS_PER_DAY: u17 = 24 * 60 * 60;
/// Seconds per hour
pub const SECS_PER_HOUR: u17 = 60 * 60;

/// TimeObject Interface
pub const TimeObject = union(enum) {
    timedelta: TimeDelta,
    date: Date,
    datetime: DateTime,
    pub fn toSeconds(self: TimeObject) ?i64 {
        return switch (self) {
            .timedelta => |*td| td.toSeconds(null),
            .date => |*d| d.toDateTime().secondsFromBase(),
            .datetime => |*dt| dt.secondsFromBase(),
        };
    }
};

// Enums
/// Weekday identifiers
/// Monday = 1 ... Sunday = 7
pub const WEEKDAY = enum(u3) {
    MONDAY = 1,
    TUESDAY = 2,
    WEDNESDAY = 3,
    THURSDAY = 4,
    FRIDAY = 5,
    SATURDAY = 6,
    SUNDAY = 7,
};

/// Month identifiers
/// January = 1 ... December = 12
pub const Month = enum(u4) {
    JANUARY = 1,
    FEBRUARY = 2,
    MARCH = 3,
    APRIL = 4,
    MAY = 5,
    JUNE = 6,
    JULY = 7,
    AUGUST = 8,
    SEPTEMBER = 9,
    OCTOBER = 10,
    NOVEMBER = 11,
    DECEMBER = 12,
};

// Helper Functions
/// Returns true if the given year is a leap year and false otherwise
pub fn isLeapYear(year: u12) bool {
    if (@mod(year, 4) != 0) return false;
    if (@mod(year, 100) != 0) return true;
    return (0 == @mod(year, 400));
}

/// Returns the maximum day in a given month
/// February = if (isLeap) 29 else 28
pub fn getDaysInMonth(isLeap: bool, month: Month) u5 {
    return switch (month) {
        .JANUARY => 31,
        .FEBRUARY => if (isLeap) 29 else 28,
        .MARCH => 31,
        .APRIL => 30,
        .MAY => 31,
        .JUNE => 30,
        .JULY => 31,
        .AUGUST => 31,
        .SEPTEMBER => 30,
        .OCTOBER => 31,
        .NOVEMBER => 30,
        .DECEMBER => 31,
    };
}
/// Returns the maximum day in a given month
/// Can panic, if the month specified is not between 1 and 12
/// TODO Remove and replace with the @intFromEnum logic
pub fn getDaysInMonthAsInt(isLeap: bool, month: u4) u5 {
    return switch (month) {
        1 => 31,
        2 => if (isLeap) 29 else 28,
        3 => 31,
        4 => 30,
        5 => 31,
        6 => 30,
        7 => 31,
        8 => 31,
        9 => 30,
        10 => 31,
        11 => 30,
        12 => 31,
        else => unreachable,
    };
}
/// Representation of the TimeZone, int value represents shift in seconds
pub const TimeZone = enum(i64) {
    Y = -12 * 60 * 60,
    X = -11 * 60 * 60,
    W = -10 * 60 * 60,
    Vt = -9 * 60 * 60 + 30 * 60,
    V = -9 * 60 * 60,
    U = -8 * 60 * 60,
    T = -7 * 60 * 60,
    S = -6 * 60 * 60,
    R = -5 * 60 * 60,
    Q = -4 * 60 * 60,
    Pt = -3 * 60 * 60 + 30 * 60,
    P = -3 * 60 * 60,
    O = -2 * 60 * 60,
    N = -1 * 60 * 60,
    Z = 0,
    A = 1 * 60 * 60,
    B = 2 * 60 * 60,
    C = 3 * 60 * 60,
    Ct = 3 * 60 * 60 + 30 * 60,
    D = 4 * 60 * 60,
    Dt = 4 * 60 * 60 + 30 * 60,
    E = 5 * 60 * 60,
    Et = 5 * 60 * 60 + 30 * 60,
    F = 6 * 60 * 60,
    Ft = 6 * 60 * 60 + 30 * 60,
    G = 7 * 60 * 60,
    H = 8 * 60 * 60,
    I = 9 * 60 * 60,
    It = 9 * 60 * 60 + 30 * 60,
    K = 10 * 60 * 60,
    Kt = 10 * 60 * 60 + 30 * 60,
    L = 11 * 60 * 60,
    M = 12 * 60 * 60,
    /// Returns TimeDelta object representing seconds away from UTC timezone
    pub fn toTimeDelta(self: TimeZone) TimeDelta {
        return TimeDelta{ .second = @intFromEnum(self) };
    }
};
/// TIMEDELTA represetns a generic difference in time.
pub const TimeDelta = struct {
    year: i16 = 0,
    month: i16 = 0,
    day: i16 = 0,
    hour: i16 = 0,
    minute: i16 = 0,
    second: i64 = 0,
    pub fn toSeconds(self: TimeDelta, other: ?DateTime) i64 {
        const reference = other orelse DateTime{ .year = 2000, .month = Month.JANUARY, .day = 1 };
        var as_seconds = reference.ShiftYear(self.year).ShiftMonths(self.month).secondsFromBase();
        as_seconds += @as(i64, self.day) * @as(i64, SECS_PER_DAY);
        as_seconds += @as(i64, self.hour) * @as(i64, SECS_PER_HOUR);
        as_seconds += self.minute * 60;
        as_seconds += self.second;
        return as_seconds - reference.secondsFromBase();
    }
    /// Tries to convert the TimeDelta into a number of days
    /// -  truncated - 10.5 days will be 10 days
    ///
    /// Will return null if Month or Year is not zero, the number of days is not fixed if month or year is included
    pub fn Days(self: TimeDelta) ?i64 {
        // it'll return null if Month or Year is not zero
        if (self.year == 0 or self.month == 0) {
            var total_seconds: i64 = 0;
            total_seconds += self.day * SECS_PER_DAY;
            total_seconds += self.hour * SECS_PER_HOUR;
            total_seconds += self.minute * 60;
            total_seconds += self.second;
            return @divTrunc(total_seconds, SECS_PER_DAY);
        } else {
            return null;
        }
    }
};
/// Date Object
/// Date Object can be initialized by struct, which does not validate inputs, use init method to initialize with validation
pub const Date = struct {
    year: u12,
    month: Month,
    day: u6,
    /// Initialize the Date Object
    /// Checks if the day valid given the month
    pub fn init(year: u12, month: Month, day: u6) !Date {
        const max_day = getDaysInMonth(isLeapYear(year), month);
        if (day <= max_day and day > 0) {
            return Date{
                .year = year,
                .month = month,
                .day = day,
            };
        } else {
            return DateFormationError.NotValidDay;
        }
    }
    /// Convert the Date object into a DateTime object
    pub fn toDateTime(self: Date) DateTime {
        return DateTime{ .year = self.year, .month = self.month, .day = self.day, .hour = 0, .minute = 0, .second = 0 };
    }
    /// Calculates the weekday value
    pub fn Weekday(self: Date) WEEKDAY {
        // Base Date is on Saturday
        const seconds = self.secondsFromBase();
        const isLeap: bool = isLeapYear(self.year);
        const days = @divTrunc(seconds, SECS_PER_DAY);
        var shifted: i64 = if (seconds < 0) -@mod(days, 7) else @mod(days, 7);
        if (shifted >= 0) {
            return switch (shifted) {
                0 => WEEKDAY.SATURDAY,
                1 => WEEKDAY.SUNDAY,
                2 => WEEKDAY.MONDAY,
                3 => WEEKDAY.TUESDAY,
                4 => WEEKDAY.WEDNESDAY,
                5 => WEEKDAY.THURSDAY,
                6 => WEEKDAY.FRIDAY,
                else => unreachable,
            };
        } else {
            if (isLeap) {
                shifted -= 1;
            }
            return switch (shifted) {
                -1 => WEEKDAY.SUNDAY,
                -2 => WEEKDAY.MONDAY,
                -3 => WEEKDAY.TUESDAY,
                -4 => WEEKDAY.WEDNESDAY,
                -5 => WEEKDAY.THURSDAY,
                -6 => WEEKDAY.FRIDAY,
                else => unreachable,
            };
        }
    }
    /// Calculate the seconds from the Base Date (2000-01-01)
    ///
    pub fn secondsFromBase(self: Date) i64 {
        return self.toDateTime().secondsFromBase();
    }
    /// Returns Date object with years shifted from the Date
    pub fn ShiftYears(self: Date, years: i16) Date {
        return self.toDateTime().ShiftYear(years).toDate();
    }
    /// Shift Date objevt with months shifted from the Date
    pub fn ShiftMonths(self: Date, months: i16) Date {
        return self.toDateTime().ShiftMonths(months).toDate();
    }
    /// Format into string
    pub fn Format(self: Date, format: DateTimeFormat, allocator: Allocator) ![]u8 {
        return self.toDateTime().Format(format, allocator);
    }
    /// Add TimeDelta to the date
    pub fn Add(self: Date, other: TimeDelta) Date {
        return self.toDateTime().Add(other).toDate();
    }
    /// Subtract TimeObject from the Date
    pub fn Sub(self: Date, other: TimeObject) TimeObject {
        return self.toDateTime().Sub(other);
    }

    /// Compares two Date objects
    pub fn Equal(self: Date, other: Date) bool {
        return std.meta.eql(self, other);
    }
};

test "Equality" {
    const control_date = Date{ .year = 2000, .month = Month.JANUARY, .day = 1 };
    const control_date2 = Date{ .year = 2000, .month = Month.JANUARY, .day = 1 };
    try std.testing.expect(std.meta.eql(control_date, control_date2));

    const control_date3 = Date{ .year = 2000, .month = Month.OCTOBER, .day = 1 };
    try std.testing.expectEqual(false, std.meta.eql(control_date, control_date3));
}

test "Date Invalid Initailziation" {
    try std.testing.expectError(DateFormationError.NotValidDay, Date.init(2000, Month.JUNE, 31));
}

test "Date Weekday" {
    const base_date = Date{ .year = 2000, .month = Month.JANUARY, .day = 1 };
    try std.testing.expectEqual(WEEKDAY.SATURDAY, base_date.Weekday());
    const test_date1 = Date{ .year = 2000, .month = Month.JANUARY, .day = 7 };
    try std.testing.expectEqual(WEEKDAY.FRIDAY, test_date1.Weekday());
    const test_date2 = Date{ .year = 2024, .month = Month.DECEMBER, .day = 30 };
    try std.testing.expectEqual(WEEKDAY.MONDAY, test_date2.Weekday());

    const test_date3 = Date{ .year = 1999, .month = Month.DECEMBER, .day = 31 };
    try std.testing.expectEqual(WEEKDAY.FRIDAY, test_date3.Weekday());
    const test_date7 = Date{ .year = 1999, .month = Month.DECEMBER, .day = 30 };

    try std.testing.expectEqual(WEEKDAY.THURSDAY, test_date7.Weekday());
    const test_date4 = Date{ .year = 1996, .month = Month.DECEMBER, .day = 31 };
    try std.testing.expectEqual(WEEKDAY.TUESDAY, test_date4.Weekday());
    const test_date5: Date = Date{ .year = 1995, .month = Month.SEPTEMBER, .day = 25 };
    try std.testing.expectEqual(WEEKDAY.MONDAY, test_date5.Weekday());

    const test_date8: Date = Date{ .year = 1991, .month = Month.JANUARY, .day = 1 };
    try std.testing.expectEqual(WEEKDAY.TUESDAY, test_date8.Weekday());

    const test_date6: Date = Date{ .year = 1990, .month = Month.DECEMBER, .day = 31 };
    try std.testing.expectEqual(WEEKDAY.MONDAY, test_date6.Weekday());
}

test "Date To Seconds" {
    const test_date_1 = Date{ .year = 2000, .month = Month.JANUARY, .day = 1 };
    try std.testing.expect((test_date_1.secondsFromBase() == 0));

    const test_date_2 = Date{ .year = 2000, .month = Month.JANUARY, .day = 2 };
    try std.testing.expect((test_date_2.secondsFromBase() == SECS_PER_DAY));

    const test_date_3 = Date{ .year = 1999, .month = Month.DECEMBER, .day = 31 };
    try std.testing.expect((@abs(test_date_3.secondsFromBase()) == SECS_PER_DAY));

    const test_date_5 = Date{ .year = 2001, .month = Month.JANUARY, .day = 1 };
    try std.testing.expect((@abs(test_date_5.secondsFromBase()) == @as(u32, SECS_PER_DAY) * 366));
}
/// DateTime Object
pub const DateTime = struct {
    year: u12,
    month: Month,
    day: u6,
    hour: u6 = 0,
    minute: u16 = 0,
    second: u16 = 0,
    timezone: ?TimeZone = null,
    /// Initalize the DateTime Objevt
    /// Validates if the inputs are valid
    pub fn init(year: u12, month: Month, day: u6, hour: u6, minute: u16, second: u64, timezone: ?TimeZone) !DateTime {
        const max_day = getDaysInMonth(year, month);
        const valid_day = (day <= max_day and day > 0);
        const valid_hour = (hour <= 23);
        const valid_minute = (minute <= 59);
        const valid_second = (second <= 99);
        if (valid_day and valid_hour and valid_minute and valid_second) {
            return DateTime{
                .year = year,
                .month = month,
                .day = day,
                .hour = hour,
                .minute = minute,
                .second = second,
                .timezone = timezone,
            };
        } else {
            return DateFormationError.NotValidInput;
        }
    }
    /// Returns a Date Object with the same year, month, and day
    pub fn toDate(self: DateTime) Date {
        return Date{ .year = self.year, .month = self.month, .day = self.day };
    }
    /// Calculates the weekday value
    pub fn Weekday(self: DateTime) WEEKDAY {
        return self.toDate().Weekday();
    }
    /// Return the date object into the seconds from the base time (2000-01-01 00:00:00)
    ///ignores the TimeZone
    fn secondsFromBase(self: DateTime) i64 {
        const year: i16 = @intCast(self.year);
        const diff_year: i16 = year - 2000;
        const isLeap = isLeapYear(self.year);
        const diff_month = @intFromEnum(self.month);
        const diff_day = self.day - 1;
        if (diff_year >= 0) {
            var total_days: u32 = 0;
            for (0..@abs(diff_year)) |i| {
                total_days += if (isLeapYear(@truncate(2000 + i))) 366 else 365;
            }
            for (1..diff_month) |i| {
                total_days += getDaysInMonthAsInt(isLeap, @truncate(i));
            }
            total_days += diff_day;
            var total_seconds: i64 = 0;
            total_seconds += total_days * @as(i64, SECS_PER_DAY);
            total_seconds += @as(i64, self.hour) * 60 * 60;
            total_seconds += @as(i64, self.minute) * 60;
            total_seconds += self.second;
            return total_seconds;
        } else {
            var total_days: i32 = 0;
            var total_subdays: i16 = 0;
            for (0..@abs(diff_year) - 1) |i| {
                total_days += if (isLeapYear(@truncate(2000 - i - 2))) 366 else 365;
            }
            for (1..diff_month) |i| {
                total_subdays += getDaysInMonthAsInt(isLeap, @truncate(i));
            }
            total_subdays += diff_day;
            //total_days += if (isLeapYear(@as(u12, self.year))) 366 - total_subdays else 365 - total_subdays;
            const seconds_from_years = @as(i64, total_days) * @as(i64, SECS_PER_DAY);
            const seconds_in_year = if (isLeap) 366 * @as(i64, SECS_PER_DAY) else 365 * @as(i64, SECS_PER_DAY);
            var seconds_to_subtract = total_subdays * @as(i64, SECS_PER_DAY);
            seconds_to_subtract += @as(i64, self.hour) * 60 * 60;
            seconds_to_subtract += @as(i64, self.minute) * 60;
            seconds_to_subtract += self.second;
            return -1 * (seconds_from_years + seconds_in_year - seconds_to_subtract);
        }
    }
    /// Returns DateTime Object that has been moved by the TimeDelta object
    pub fn Add(self: DateTime, other: TimeDelta) DateTime {
        const seconds_from_base = self.secondsFromBase() + other.toSeconds(self);
        return DateTimeFromSeconds(seconds_from_base);
    }
    /// Returns DateTime Object that has been moved by the TimeDelta object
    pub fn Sub(self: DateTime, other: TimeObject) TimeObject {
        return switch (other) {
            .timedelta => |*td| TimeObject{ .datetime = DateTimeFromSeconds(self.secondsFromBase() - td.toSeconds(self)) },
            .date => |*d| self.Sub(TimeObject{ .datetime = d.toDateTime() }),
            .datetime => |*td| TimeObject{ .timedelta = TimeDelta{ .second = self.secondsFromBase() - td.secondsFromBase() } },
        };
    }
    /// Compares DateTime Object to each other.
    ///ignores TimeZone
    pub fn Equal(self: DateTime, other: DateTime) bool {
        if (self.year == other.year and self.month == other.month and self.day == other.day and self.hour == other.hour and self.minute == other.minute and self.second == other.second) {
            return true;
        } else {
            return false;
        }
    }
    /// Returns DateTime Object with years moved
    pub fn ShiftYear(self: DateTime, years: i16) DateTime {
        const new_year: u16 = @truncate(@abs(@as(i16, self.year) + years));
        return DateTime{
            .year = @truncate(new_year),
            .month = self.month,
            .day = self.day,
            .hour = self.hour,
            .minute = self.minute,
            .second = self.second,
        };
    }
    /// Returns DateTime Object with months moved
    pub fn ShiftMonths(self: DateTime, months: i16) DateTime {
        const shift_years = @divTrunc(months, 12);
        if (shift_years != 0) {
            return self.ShiftYear(shift_years).ShiftMonths(@mod(months, 12));
        } else {
            const new_month: i16 = @intFromEnum(self.month) + months;
            // if the resulting shift would move the year
            if (new_month > 12) {
                return DateTime{
                    .year = self.year + 1,
                    .month = @enumFromInt(new_month - 12),
                    .day = self.day,
                    .hour = self.hour,
                    .minute = self.minute,
                    .second = self.second,
                };
                // if the resulting shift would move the year
            } else if (new_month <= 0) {
                return DateTime{
                    .year = self.year - 1,
                    .month = @enumFromInt(12 - new_month),
                    .day = self.day,
                    .hour = self.hour,
                    .minute = self.minute,
                    .second = self.second,
                };
            } else {
                return DateTime{
                    .year = self.year,
                    .month = @enumFromInt(new_month),
                    .day = self.day,
                    .hour = self.hour,
                    .minute = self.minute,
                    .second = self.second,
                };
            }
        }
    }
    /// Returns string object based on the specified format
    ///
    /// TODO - Expand on the number of formats supported
    pub fn Format(self: DateTime, format: DateTimeFormat, allocator: Allocator) ![]u8 {
        const string = try switch (format) {
            .DATE_ONLY => std.fmt.allocPrint(allocator, "{d:0>4}-{d:0>2}-{d:0>2}", .{
                self.year, @intFromEnum(self.month), self.day,
            }),
            .DATETIME => std.fmt.allocPrint(allocator, "{d:0>4}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}:{d:0>2}", .{
                self.year, @intFromEnum(self.month), self.day, self.hour, self.minute, self.second,
            }),
            .DATETIME_ZONE => std.fmt.allocPrint(allocator, "{d:0>4}-{d:0>2}-{d:0>2} {d:0>2}:{d:0>2}:{d:0>2}{?}", .{
                self.year, @intFromEnum(self.month), self.day, self.hour, self.minute, self.second, self.timezone,
            }),
        };
        return string;
    }
};

// Date Parser Logics
const DateFormationError = error{
    NotImplementedFormat,
    NotValidDay,
    NotValidInput,
};
/// Returns DateTime Object from string.
/// The string must comply with the existing formats
/// TODO - Currently only supports the DATE_ONLY format
pub fn DateTimeFromString(format: DateTimeFormat, string: []const u8) !DateTime {
    return switch (format) {
        .DATE_ONLY => {
            var splits = std.mem.split(u8, string, "-");
            var i: u4 = 0;
            var year: u12 = 0;
            var month: u8 = 0;
            var day: u6 = 0;
            while (splits.next()) |component| {
                switch (i) {
                    0 => year = try std.fmt.parseInt(u12, component, 10),
                    1 => month = try std.fmt.parseInt(u8, component, 10),
                    2 => day = try std.fmt.parseInt(u6, component, 10),
                    else => unreachable,
                }
                i += 1;
            }
            const date = try Date.init(year, @enumFromInt(month), day);
            return date.toDateTime();
        },
        else => DateFormationError.NotImplementedFormat,
    };
}

test "DateTime Read From String" {
    const control_dt1 = DateTime{
        .year = 2000,
        .month = Month.JANUARY,
        .day = 1,
    };
    const control_dt2 = DateTime{
        .year = 2010,
        .month = Month.DECEMBER,
        .day = 31,
    };
    const test_string = "2000-01-01";
    const date_from_string = try DateTimeFromString(DateTimeFormat.DATE_ONLY, test_string);
    try std.testing.expect(date_from_string.Equal(control_dt1));

    const test_string2 = "2010-12-31";
    const date_from_string2 = try DateTimeFromString(DateTimeFormat.DATE_ONLY, test_string2);
    try std.testing.expect(date_from_string2.Equal(control_dt2));
}

test "DateTime Format Print" {
    const date1 = DateTime{ .year = 2000, .month = Month.JANUARY, .day = 1, .timezone = TimeZone.Z };

    const test_allocator = std.testing.allocator;

    const string = try date1.Format(DateTimeFormat.DATE_ONLY, test_allocator);
    defer test_allocator.free(string);
    const control_string = "2000-01-01";
    try std.testing.expectEqualStrings(control_string, string);

    const string2 = try date1.Format(DateTimeFormat.DATETIME, test_allocator);
    defer test_allocator.free(string2);
    const control_string2 = "2000-01-01 00:00:00";
    try std.testing.expectEqualStrings(control_string2, string2);
}

/// Manually defined Date Format
pub const DateTimeFormat = enum {
    /// DATE ONLY = "YYYY-MM-DD"
    DATE_ONLY,
    /// DATETIME = "YYYY-MM-DDTHH:MM:SS",
    DATETIME,
    /// DATETIME ZONE = "YYYY-MM-DDTHH:MM:SSZ",
    DATETIME_ZONE,
};

test "DateTime Arithmetics" {
    const date1 = DateTime{
        .year = 2000,
        .month = Month.JANUARY,
        .day = 1,
    };
    const date2 = DateTime{
        .year = 2000,
        .month = Month.JANUARY,
        .day = 2,
    };

    const elapsed = date2.Sub(TimeObject{ .datetime = date1 });
    const elapsed_seconds = elapsed.toSeconds();
    try std.testing.expect(elapsed_seconds == SECS_PER_DAY);

    const timedelta = TimeDelta{
        .day = 1,
    };
    const test_date_add = date1.Add(timedelta);
    try std.testing.expect(test_date_add.secondsFromBase() == SECS_PER_DAY);
}
/// Depreciated, the calculation is not correct
fn fromNegativeSeconds(seconds: i64) DateTime {
    var residual_seconds = @mod(seconds, @as(i64, SECS_PER_DAY));
    // calculate seconds
    var second = @mod(residual_seconds, 60);
    second = if (second == 0) 0 else 60 - second;
    residual_seconds += second;
    // calculate minutes
    var minute = @mod(residual_seconds, 60 * 60);
    residual_seconds -= minute;
    minute = if (minute == 0) 0 else 60 + @divTrunc(minute, 60);
    var hour = @divTrunc(residual_seconds, (60 * 60));
    hour = if (hour == 0) 0 else 24 - hour;
    var residual_days = @abs(@divTrunc(seconds, SECS_PER_DAY));
    var curr_month: u4 = 1;
    var curr_year: u12 = 2000;
    var curr_day: u6 = 1;
    while (residual_days > 0) {
        const isLeap = isLeapYear(curr_year);
        const day_in_year: u9 = if (isLeapYear(curr_year - 1)) 366 else 365;
        if (residual_days >= day_in_year) {
            curr_year -= 1;
            residual_days -= day_in_year;
        } else {
            if (curr_month == 1) {
                curr_month = 12;
                curr_year -= 1;
            }
            const day_in_month = @as(u6, getDaysInMonthAsInt(isLeap, curr_month));
            curr_day = day_in_month;
            if (residual_days >= day_in_month) {
                curr_month -= 1;
                residual_days -= day_in_month;
            } else {
                curr_day -= @truncate(@abs(residual_days));
                residual_days = 0;
            }
        }
    }
    return DateTime{
        .year = curr_year,
        .month = @enumFromInt(curr_month),
        .day = curr_day,
        .hour = @truncate(@abs(hour)),
        .minute = @truncate(@abs(minute)),
        .second = if (second == 60) 0 else @truncate(@abs(second)),
    };
}
/// Returns DateTime from seconds reference to the base time (2000-01-01 00:00:00)
fn fromNegativeSeconds2(seconds: i64) DateTime {
    var curr_year: u12 = 2000;
    var curr_seconds: i64 = seconds;
    while (curr_seconds < 0) {
        curr_year -= 1;
        const days_in_year: i64 = if (isLeapYear(curr_year)) 366 else 365;
        const seconds_in_year: i64 = days_in_year * @as(i64, @intCast(SECS_PER_DAY));
        curr_seconds += seconds_in_year;
    }
    return fromPositiveSecondsFromReference(curr_seconds, curr_year);
}
/// Returns DateTime object by calculating the difference from the reference time (<YEAR>-01-01 00:00:00)
fn fromPositiveSecondsFromReference(seconds: i64, year: u12) DateTime {
    var residual_seconds = @mod(seconds, @as(i64, SECS_PER_DAY));
    // calculate seconds
    const second = @mod(residual_seconds, 60);
    residual_seconds -= second;
    // calculate minutes
    var minute = @mod(residual_seconds, 60 * 60);
    residual_seconds -= minute;
    minute = @divTrunc(minute, 60);
    const hour = @divTrunc(residual_seconds, (60 * 60));
    var residual_days = @divTrunc(seconds, SECS_PER_DAY);
    var curr_month: u4 = 1;
    var curr_year: u12 = year;
    var curr_day: u6 = 1;
    while (residual_days > 0) {
        const isLeap = isLeapYear(curr_year);
        const day_in_year: u9 = if (isLeapYear(curr_year)) 366 else 365;
        if (residual_days >= day_in_year) {
            curr_year += 1;
            residual_days -= day_in_year;
        } else {
            const day_in_month = getDaysInMonthAsInt(isLeap, curr_month);
            if (residual_days >= day_in_month) {
                curr_month += 1;
                residual_days -= day_in_month;
            } else {
                curr_day += @truncate(@abs(residual_days));
                residual_days = 0;
            }
        }
    }
    return DateTime{
        .year = curr_year,
        .month = @enumFromInt(curr_month),
        .day = curr_day,
        .hour = @truncate(@abs(hour)),
        .minute = @truncate(@abs(minute)),
        .second = @truncate(@abs(second)),
    };
}
fn fromPositiveSeconds(seconds: i64) DateTime {
    var residual_seconds = @mod(seconds, @as(i64, SECS_PER_DAY));
    // calculate seconds
    const second = @mod(residual_seconds, 60);
    residual_seconds -= second;
    // calculate minutes
    var minute = @mod(residual_seconds, 60 * 60);
    residual_seconds -= minute;
    minute = @divTrunc(minute, 60);
    const hour = @divTrunc(residual_seconds, (60 * 60));
    var residual_days = @divTrunc(seconds, SECS_PER_DAY);
    var curr_month: u4 = 1;
    var curr_year: u12 = 2000;
    var curr_day: u6 = 1;
    while (residual_days > 0) {
        const isLeap = isLeapYear(curr_year);
        const day_in_year: u9 = if (isLeapYear(curr_year)) 366 else 365;
        if (residual_days >= day_in_year) {
            curr_year += 1;
            residual_days -= day_in_year;
        } else {
            const day_in_month = getDaysInMonthAsInt(isLeap, curr_month);
            if (residual_days >= day_in_month) {
                curr_month += 1;
                residual_days -= day_in_month;
            } else {
                curr_day += @truncate(@abs(residual_days));
                residual_days = 0;
            }
        }
    }
    return DateTime{
        .year = curr_year,
        .month = @enumFromInt(curr_month),
        .day = curr_day,
        .hour = @truncate(@abs(hour)),
        .minute = @truncate(@abs(minute)),
        .second = @truncate(@abs(second)),
    };
}

/// Returns DateTime object based on the seconds elapsed from BaseTime (2000-01-01 00:00:00)
pub fn DateTimeFromSeconds(seconds: i64) DateTime {
    return if (seconds >= 0) fromPositiveSeconds(seconds) else fromNegativeSeconds2(seconds);
}

test "DateTime From Seconds" {
    const control_dt = DateTime{ .year = 2000, .month = Month.JANUARY, .day = 1 };
    const test_dt = DateTimeFromSeconds(0);
    try std.testing.expect(test_dt.Equal(control_dt));

    const control_dt2 = DateTime{ .year = 1999, .month = Month.JANUARY, .day = 1 };
    const test_dt2 = DateTimeFromSeconds(control_dt2.secondsFromBase());
    try std.testing.expect(test_dt2.Equal(control_dt2));

    const control_dt3 = DateTime{ .year = 2001, .month = Month.JANUARY, .day = 1 };
    const test_dt3 = DateTimeFromSeconds(control_dt3.secondsFromBase());
    try std.testing.expect(test_dt3.Equal(control_dt3));

    const control_dt4 = DateTime{ .year = 2005, .month = Month.JULY, .day = 19 };
    const test_dt4 = DateTimeFromSeconds(control_dt4.secondsFromBase());
    try std.testing.expect(test_dt4.Equal(control_dt4));

    const control_dt5 = DateTime{ .year = 1990, .month = Month.SEPTEMBER, .day = 14 };
    const test_dt5 = DateTimeFromSeconds(control_dt5.secondsFromBase());

    const control_dt6 = DateTime{ .year = 1994, .month = Month.FEBRUARY, .day = 10 };
    const test_dt6 = DateTimeFromSeconds(control_dt6.secondsFromBase());
    try std.testing.expect(test_dt6.Equal(control_dt6));

    const test_allocator = std.testing.allocator;
    const string = try test_dt5.Format(DateTimeFormat.DATE_ONLY, test_allocator);
    //std.debug.print("\n{s}\n", .{string});
    defer test_allocator.free(string);

    try std.testing.expect(test_dt5.Equal(control_dt5));
}

test "DateTime To Seconds" {
    const test_datetime_1 = DateTime{ .year = 2000, .month = Month.JANUARY, .day = 1 };
    try std.testing.expect((test_datetime_1.secondsFromBase() == 0));

    const test_datetime_2 = DateTime{ .year = 2000, .month = Month.JANUARY, .day = 2 };
    try std.testing.expect((test_datetime_2.secondsFromBase() == SECS_PER_DAY));

    const test_datetime_3 = DateTime{ .year = 1999, .month = Month.DECEMBER, .day = 31 };
    try std.testing.expect((@abs(test_datetime_3.secondsFromBase()) == SECS_PER_DAY));

    const test_datetime_5 = DateTime{ .year = 2001, .month = Month.JANUARY, .day = 1, .minute = 1, .second = 1 };
    try std.testing.expect((@abs(test_datetime_5.secondsFromBase()) == @as(u32, SECS_PER_DAY) * 366 + 61));
}

pub fn main() void {}
// test "DateTime Feb" {
// const test_date1 = try Date.init(2000, @enumFromInt(2), 1);
// std.debug.print("\n{any}\n", .{test_date1});
//
// const base_date = try Date.init(2000, @enumFromInt(1), 1);
// const test_elapsed = test_date1.Sub(TimeObject{ .date = base_date });
// std.debug.print("\n{any}\n", .{test_elapsed});
// const days = @divTrunc(test_elapsed.toSeconds().?, SECS_PER_DAY);
// std.debug.print("\n{d}\n", .{days});
//}
