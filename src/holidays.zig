const std = @import("std");
const dt = @import("date.zig");
const easters = @embedFile("easter_dates.csv");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub const HolidayList = enum {
    Empty,
    WeekendOnly,
    US_PUBLIC,
    US_NYSE,
    US_BOND,
    US_FEDERAL_RESERVE_BANKWIRE_SYSTEM,
};

/// Returns the holiday from that year, determined by the CalendarType;
/// If the CalendarType has not been implemented it'll return an NotImplementedError
pub fn getHolidays(allocator: Allocator, list: HolidayList, year: u12) !ArrayList(dt.Date) {
    var holidays = ArrayList(dt.Date).init(allocator);
    errdefer holidays.deinit();
    switch (list) {
        .Empty => {},
        .WeekendOnly => {
            // add weekends
            const weekends = try getWeekends(allocator, year);
            defer allocator.free(weekends);
            try holidays.appendSlice(weekends);
        },
        .US_PUBLIC => {
            // add weekends
            const weekends = try getWeekends(allocator, year);
            defer allocator.free(weekends);
            try holidays.appendSlice(weekends);
            // New Year's day
            try holidays.append(getNewYearsDayMoveBoth(year));
            // MLK's day
            try holidays.append(getMartinLutherKingsDay(year));
            // President's day
            try holidays.append(getPresidentsDay(year));
            // Memorial Day
            try holidays.append(getMemorialDay(year));
            // Juneteenth, moved both
            try holidays.append(getJuneteeth(year));
            // Independence Day
            try holidays.append(getIndependenceDay(year));
            // Labor day
            try holidays.append(getLaborDay(year));
            // Columbus Day
            try holidays.append(getColumbusDay(year));
            // Veterans' day
            try holidays.append(getVeteransDay(year));
            // Thanksgiving day
            try holidays.append(getThanksgivingDay(year));
            // christmas
            try holidays.append(getChristmas(year));
        },
        .US_NYSE => {
            // weekend
            const weekends = try getWeekends(allocator, year);
            defer allocator.free(weekends);
            try holidays.appendSlice(weekends);
            // New Year's Day
            try holidays.append(getNewYearsDayMoveSunday(year));
            // MLK's day
            try holidays.append(getMartinLutherKingsDay(year));
            // Presidents day
            try holidays.append(getPresidentsDay(year));
            // Good Friday
            try holidays.append(try getGoodFriday(year));
            // Memorial Day
            try holidays.append(getMemorialDay(year));
            // Independence day
            try holidays.append(getIndependenceDay(year));
            // Labor day
            try holidays.append(getLaborDay(year));
            // Thanksgivine day
            try holidays.append(getThanksgivingDay(year));
            // Presidenial election day (until 1980)
            const presidential_election = getPresidentialElectionUntil1980(year);
            if (presidential_election != null) {
                try holidays.append(presidential_election.?);
            }
            // Chrismas day
            try holidays.append(getChristmas(year));
        },
        .US_BOND => {
            // Weekend
            const weekends = try getWeekends(allocator, year);
            defer allocator.free(weekends);
            try holidays.appendSlice(weekends);
            // New Years day both
            try holidays.append(getNewYearsDayMoveBoth(year));
            // MLK
            try holidays.append(getMartinLutherKingsDay(year));
            // President's day
            try holidays.append(getPresidentsDay(year));
            // Good Friday
            try holidays.append(try getGoodFriday(year));
            // Memorial day
            try holidays.append(getMemorialDay(year));
            // Independence Day
            try holidays.append(getIndependenceDay(year));
            // Labor day
            try holidays.append(getLaborDay(year));
            // Columbus day
            try holidays.append(getColumbusDay(year));
            // Veteran's day
            try holidays.append(getVeteransDay(year));
            // Thanksgiving day
            try holidays.append(getThanksgivingDay(year));
            // Christmas day
            try holidays.append(getChristmas(year));
        },
        .US_FEDERAL_RESERVE_BANKWIRE_SYSTEM => {
            // Weekend
            const weekends = try getWeekends(allocator, year);
            defer allocator.free(weekends);
            try holidays.appendSlice(weekends);
            // New Years Moved Sunday only
            try holidays.append(getNewYearsDayMoveSunday(year));
            // MLK
            try holidays.append(getMartinLutherKingsDay(year));
            // President's day
            try holidays.append(getPresidentsDay(year));
            // Memorial day
            try holidays.append(getMemorialDay(year));
            // Juneteenth
            try holidays.append(getJuneteeth(year));
            // Indpendence Day
            try holidays.append(getIndependenceDay(year));
            // Labor day,
            try holidays.append(getLaborDay(year));
            // Columbus Day
            try holidays.append(getColumbusDay(year));
            // Veterans' Day
            try holidays.append(getVeteransDay(year));
            // Thanksgiving day
            try holidays.append(getThanksgivingDay(year));
            // Christmas
            try holidays.append(getChristmas(year));
        },
    }
    return holidays;
}

/// U.S. Presidential Election Day
/// First Tuesday in November until 1980
pub fn getPresidentialElectionUntil1980(year: u12) ?dt.Date {
    if (year <= 1980) {
        const first = dt.Date{ .year = year, .month = @enumFromInt(11), .day = 1 };
        return switch (first.Weekday()) {
            .MONDAY => first.Add(dt.TimeDelta{ .day = 1 }),
            .TUESDAY => first,
            .WEDNESDAY => first.Add(dt.TimeDelta{ .day = 6 }),
            .THURSDAY => first.Add(dt.TimeDelta{ .day = 5 }),
            .FRIDAY => first.Add(dt.TimeDelta{ .day = 4 }),
            .SATURDAY => first.Add(dt.TimeDelta{ .day = 3 }),
            .SUNDAY => first.Add(dt.TimeDelta{ .day = 2 }),
        };
    } else {
        return null;
    }
}

/// Juneteeth
/// June 19th
/// - Moved to Monday if Sunday
/// - Moved to Friday if Saturday
pub fn getJuneteeth(year: u12) dt.Date {
    const juneteeth = dt.Date{ .year = year, .month = @enumFromInt(6), .day = 19 };
    return moveForWeekend(juneteeth);
}

/// Weekends
/// iterates through all the days in the year and returns slice of Date(s)
pub fn getWeekends(allocator: Allocator, year: u12) ![]dt.Date {
    var wknds = ArrayList(dt.Date).init(allocator);
    defer wknds.deinit();
    const is_leap: bool = dt.isLeapYear(year);
    const days: u12 = if (is_leap) 366 else 365;
    const start_date = try dt.Date.init(year, @enumFromInt(1), 1);
    for (0..days) |i| {
        const curr_date = start_date.Add(dt.TimeDelta{ .day = @intCast(i) });
        if (isWeekend(curr_date)) {
            try wknds.append(curr_date);
        }
    }
    return try wknds.toOwnedSlice();
}

// holiday logics
/// Return true if the Date object falls on the weekend; otherwise, false
pub fn isWeekend(date: dt.Date) bool {
    return switch (date.Weekday()) {
        dt.WEEKDAY.SATURDAY, dt.WEEKDAY.SUNDAY => true,
        else => false,
    };
}
/// Return true if the date is January 1st, unless if Jan. 1st falls on Sunday, then the 2nd will result in true
pub fn isNewYears(date: dt.Date) bool {
    if (@intFromEnum(date.month) == 1) {
        if (date.day <= 2) {
            const ny = dt.Date{ .year = date.year, .month = date.month, .day = 1 };
            if (ny.Weekday() == dt.WEEKDAY.SUNDAY) {
                if (date.day == 2) {
                    return true;
                } else {
                    return false;
                }
            } else {
                if (date.day == 1) {
                    return true;
                } else {
                    return false;
                }
            }
        } else {
            return false;
        }
    } else {
        return false;
    }
}
pub fn getNewYearsDayMoveBoth(year: u12) dt.Date {
    const ny_day = dt.Date{
        .year = year,
        .month = @enumFromInt(1),
        .day = 1,
    };
    return moveForWeekend(ny_day);
}
pub fn getNewYearsDayMoveSunday(year: u12) dt.Date {
    const ny_day = dt.Date{
        .year = year,
        .month = @enumFromInt(1),
        .day = 1,
    };
    if (ny_day.Weekday() == dt.WEEKDAY.SUNDAY) {
        return dt.Date{
            .year = year,
            .month = @enumFromInt(1),
            .day = 2,
        };
    } else {
        return ny_day;
    }
}
test "New Year's Day Test" {
    const valid_date = dt.Date{ .year = 2024, .month = @enumFromInt(1), .day = 1 };
    try std.testing.expectEqual(true, isNewYears(valid_date));

    const invalid_date_ny = dt.Date{ .year = 2023, .month = @enumFromInt(1), .day = 1 };
    try std.testing.expectEqual(false, isNewYears(invalid_date_ny));

    const valid_date_ny_2nd = dt.Date{ .year = 2023, .month = @enumFromInt(1), .day = 2 };
    try std.testing.expectEqual(true, isNewYears(valid_date_ny_2nd));

    try std.testing.expectEqual(2, getNewYearsDayMoveSunday(2023).day);
    try std.testing.expectEqual(1, getNewYearsDayMoveSunday(2024).day);
}
/// Martin Luther King's Day
/// Third Monday of January
pub fn isMartinLutherKingsDay(date: dt.Date) bool {
    if (@intFromEnum(date.month) == 1) {
        if (date.Weekday() == dt.WEEKDAY.MONDAY) {
            const div = @divTrunc(date.day - 1, 7) + 1;
            if (div == 3) {
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    } else {
        return false;
    }
}
pub fn getMartinLutherKingsDay(year: u12) dt.Date {
    const start_date = dt.Date{ .year = year, .month = @enumFromInt(1), .day = 1 };
    const start_weekday = start_date.Weekday();
    return switch (start_weekday) {
        .MONDAY => start_date.Add(dt.TimeDelta{ .day = 14 }),
        .TUESDAY => start_date.Add(dt.TimeDelta{ .day = 20 }),
        .WEDNESDAY => start_date.Add(dt.TimeDelta{ .day = 19 }),
        .THURSDAY => start_date.Add(dt.TimeDelta{ .day = 18 }),
        .FRIDAY => start_date.Add(dt.TimeDelta{ .day = 17 }),
        .SATURDAY => start_date.Add(dt.TimeDelta{ .day = 16 }),
        .SUNDAY => start_date.Add(dt.TimeDelta{ .day = 15 }),
    };
}
test "MLK Day Test" {
    const valid_date = dt.Date{ .year = 2025, .month = @enumFromInt(1), .day = 20 };
    try std.testing.expect(isMartinLutherKingsDay(valid_date));

    const invalid_date = dt.Date{ .year = 2024, .month = @enumFromInt(1), .day = 20 };
    try std.testing.expectEqual(false, isMartinLutherKingsDay(invalid_date));

    try std.testing.expectEqual(20, getMartinLutherKingsDay(2025).day);
    try std.testing.expectEqual(15, getMartinLutherKingsDay(2024).day);
}
/// President's Day is the third Monday in Feb.
pub fn getPresidentsDay(year: u12) dt.Date {
    const start_date = dt.Date{ .year = year, .month = @enumFromInt(2), .day = 1 };
    const start_weekday = start_date.Weekday();
    return switch (start_weekday) {
        .MONDAY => start_date.Add(dt.TimeDelta{ .day = 14 }),
        .TUESDAY => start_date.Add(dt.TimeDelta{ .day = 20 }),
        .WEDNESDAY => start_date.Add(dt.TimeDelta{ .day = 19 }),
        .THURSDAY => start_date.Add(dt.TimeDelta{ .day = 18 }),
        .FRIDAY => start_date.Add(dt.TimeDelta{ .day = 17 }),
        .SATURDAY => start_date.Add(dt.TimeDelta{ .day = 16 }),
        .SUNDAY => start_date.Add(dt.TimeDelta{ .day = 15 }),
    };
}
// TODO Add President's Day testings

// TODO Manually Add Good Friday

// Memorial Day
/// Memorial Day is the last Monday in May
pub fn getMemorialDay(year: u12) dt.Date {
    const eom_may = dt.Date{ .year = year, .month = @enumFromInt(5), .day = 31 };
    const weekday = eom_may.Weekday();
    return switch (weekday) {
        .MONDAY => eom_may,
        .TUESDAY => eom_may.Add(dt.TimeDelta{ .day = -1 }),
        .WEDNESDAY => eom_may.Add(dt.TimeDelta{ .day = -2 }),
        .THURSDAY => eom_may.Add(dt.TimeDelta{ .day = -3 }),
        .FRIDAY => eom_may.Add(dt.TimeDelta{ .day = -4 }),
        .SATURDAY => eom_may.Add(dt.TimeDelta{ .day = -5 }),
        .SUNDAY => eom_may.Add(dt.TimeDelta{ .day = -6 }),
    };
}
test "Memorial Day" {
    const control_date_2024 = dt.Date{
        .year = 2024,
        .month = @enumFromInt(5),
        .day = 27,
    };
    try std.testing.expectEqual(true, control_date_2024.Equal(getMemorialDay(2024)));

    const control_date_2020 = dt.Date{
        .year = 2020,
        .month = @enumFromInt(5),
        .day = 25,
    };
    try std.testing.expectEqual(true, control_date_2020.Equal(getMemorialDay(2020)));

    const control_date_1990 = dt.Date{
        .year = 1990,
        .month = @enumFromInt(5),
        .day = 28,
    };
    try std.testing.expectEqual(true, control_date_1990.Equal(getMemorialDay(1990)));
}

/// Independence Day (US)
/// July 4th, moved to Monday if Sunday, Friday if Saturday
pub fn getIndependenceDay(year: u12) dt.Date {
    const fourth = dt.Date{
        .year = year,
        .month = @enumFromInt(7),
        .day = 4,
    };
    return switch (fourth.Weekday()) {
        .SATURDAY => dt.Date{ .year = year, .month = @enumFromInt(7), .day = 3 },
        .SUNDAY => dt.Date{ .year = year, .month = @enumFromInt(7), .day = 5 },
        else => fourth,
    };
}

/// Labor Day
/// first Monday in September
pub fn getLaborDay(year: u12) dt.Date {
    const first = dt.Date{
        .year = year,
        .month = @enumFromInt(9),
        .day = 1,
    };
    return switch (first.Weekday()) {
        .MONDAY => first,
        .TUESDAY => first.Add(dt.TimeDelta{ .day = 6 }),
        .WEDNESDAY => first.Add(dt.TimeDelta{ .day = 5 }),
        .THURSDAY => first.Add(dt.TimeDelta{ .day = 4 }),
        .FRIDAY => first.Add(dt.TimeDelta{ .day = 3 }),
        .SATURDAY => first.Add(dt.TimeDelta{ .day = 2 }),
        .SUNDAY => first.Add(dt.TimeDelta{ .day = 1 }),
    };
}
/// Columbus Day
/// - second Monday in October
pub fn getColumbusDay(year: u12) dt.Date {
    const eighth = dt.Date{ .year = year, .month = @enumFromInt(10), .day = 8 };
    return switch (eighth.Weekday()) {
        .MONDAY => eighth,
        .TUESDAY => eighth.Add(dt.TimeDelta{ .day = 6 }),
        .WEDNESDAY => eighth.Add(dt.TimeDelta{ .day = 5 }),
        .THURSDAY => eighth.Add(dt.TimeDelta{ .day = 4 }),
        .FRIDAY => eighth.Add(dt.TimeDelta{ .day = 3 }),
        .SATURDAY => eighth.Add(dt.TimeDelta{ .day = 2 }),
        .SUNDAY => eighth.Add(dt.TimeDelta{ .day = 1 }),
    };
}
/// Veteran's Day
/// November 11th
/// - Moved to Monday if Sunday
/// - Moved to Friday if Saturday
pub fn getVeteransDay(year: u12) dt.Date {
    const veterans_day = dt.Date{ .year = year, .month = @enumFromInt(11), .day = 11 };
    return switch (veterans_day.Weekday()) {
        .SATURDAY => dt.Date{ .year = year, .month = @enumFromInt(11), .day = 10 },
        .SUNDAY => dt.Date{ .year = year, .month = @enumFromInt(11), .day = 12 },
        else => veterans_day,
    };
}

/// Thanksgiving Day
/// Fourth Thursday in November
pub fn getThanksgivingDay(year: u12) dt.Date {
    const first = dt.Date{ .year = year, .month = @enumFromInt(11), .day = 1 };
    return switch (first.Weekday()) {
        .MONDAY => first.Add(dt.TimeDelta{ .day = 24 }),
        .TUESDAY => first.Add(dt.TimeDelta{ .day = 23 }),
        .WEDNESDAY => first.Add(dt.TimeDelta{ .day = 22 }),
        .THURSDAY => first.Add(dt.TimeDelta{ .day = 21 }),
        .FRIDAY => first.Add(dt.TimeDelta{ .day = 27 }),
        .SATURDAY => first.Add(dt.TimeDelta{ .day = 26 }),
        .SUNDAY => first.Add(dt.TimeDelta{ .day = 25 }),
    };
}
test "Thanksgiving Days" {
    // Sunday Start
    const control_tg_sunday = dt.Date{ .year = 2020, .month = @enumFromInt(11), .day = 26 };
    const test_tg_sunday = getThanksgivingDay(2020);
    try std.testing.expect(control_tg_sunday.Equal(test_tg_sunday));
    // Wednesday Start
    const control_tg_wednesday = dt.Date{ .year = 2017, .month = @enumFromInt(11), .day = 23 };
    const test_tg_wednesday = getThanksgivingDay(2017);
    try std.testing.expect(control_tg_wednesday.Equal(test_tg_wednesday));
    // Tuesday Start
    const control_tg_tuesday = dt.Date{ .year = 2016, .month = @enumFromInt(11), .day = 24 };
    const test_tg_tuesday = getThanksgivingDay(2016);
    try std.testing.expect(control_tg_tuesday.Equal(test_tg_tuesday));
}

/// Christmas
/// December 25th
/// - Moved to Monday if Sunday
/// - Moved to Friday if Saturday
pub fn getChristmas(year: u12) dt.Date {
    const christmas = dt.Date{ .year = year, .month = dt.Month.DECEMBER, .day = 25 };
    return moveForWeekend(christmas);
}

/// Good Friday
/// Easter Sunday minus 2 days
pub fn getGoodFriday(year: u12) !dt.Date {
    var buff: [4]u8 = undefined;
    const year_std = try std.fmt.bufPrint(&buff, "{}", .{year});
    var easter_dates = std.mem.split(u8, easters, ",");
    while (easter_dates.next()) |date| {
        if (std.mem.eql(u8, date[0..4], year_std)) {
            const month_as_int = try std.fmt.parseInt(u12, date[5..7], 10);
            const month: dt.Month = @enumFromInt(month_as_int);
            const day = try std.fmt.parseInt(u6, date[8..], 10);
            const easter = dt.Date{ .year = year, .month = month, .day = day };
            return easter.Add(dt.TimeDelta{ .day = -2 });
        }
    }
    return error.NotValidInput;
}
test "Good Fridays" {
    const good_friday_1 = try getGoodFriday(2000);
    const control_gf_1 = dt.Date{ .year = 2000, .month = dt.Month.APRIL, .day = 21 };
    try std.testing.expect(control_gf_1.Equal(good_friday_1));

    const good_friday_2 = try getGoodFriday(1990);
    const control_gf_2 = dt.Date{ .year = 1990, .month = dt.Month.APRIL, .day = 13 };
    try std.testing.expect(control_gf_2.Equal(good_friday_2));

    const good_friday_3 = try getGoodFriday(2025);
    const control_gf_3 = dt.Date{ .year = 2025, .month = dt.Month.APRIL, .day = 18 };
    try std.testing.expect(control_gf_3.Equal(good_friday_3));

    const good_friday_4 = try getGoodFriday(2067);
    const control_gf_4 = dt.Date{ .year = 2067, .month = dt.Month.APRIL, .day = 1 };
    try std.testing.expect(control_gf_4.Equal(good_friday_4));
}

/// Returns Date that's been moved for the weekend
/// - Moved to Monday if Sunday
/// - Moved to Friday if Saturday
fn moveForWeekend(date: dt.Date) dt.Date {
    return switch (date.Weekday()) {
        .SUNDAY => date.Add(dt.TimeDelta{ .day = 1 }),
        .SATURDAY => date.Add(dt.TimeDelta{ .day = -1 }),
        else => date,
    };
}
