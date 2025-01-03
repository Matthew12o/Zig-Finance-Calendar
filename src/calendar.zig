// Import
const std = @import("std");
const DateTime = @import("date.zig");
const holidays = @import("holidays.zig");

// Aliases
const AutoHashMap = std.AutoHashMap;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

/// Calendar Specific Error
pub const CalendarError = error{
    NotImplemented,
    CalendarNotImplemented,
};

pub const CalendarDates = struct {
    allocator: Allocator,
    dates: ArrayList(DateTime.Date),
};

pub const DateIterator = struct {
    dates: []DateTime.Date,
    index: usize = 0,

    fn next(self: *DateIterator) ?DateTime.Date {
        const index = self.index;
        for (self.dates[index..]) |date| {
            self.index += 1;
            return date;
        }
        return null;
    }

    fn reset(self: *DateIterator) void {
        self.index = 0;
    }
};

test "Date Iterator" {
    //const test_allocator = std.testing.allocator;
    var date_array: [4]DateTime.Date = [4]DateTime.Date{
        DateTime.Date{
            .year = 2000,
            .month = @enumFromInt(1),
            .day = 1,
        },
        DateTime.Date{
            .year = 2000,
            .month = @enumFromInt(1),
            .day = 1,
        },
        DateTime.Date{
            .year = 2000,
            .month = @enumFromInt(1),
            .day = 1,
        },
        DateTime.Date{
            .year = 2000,
            .month = @enumFromInt(1),
            .day = 1,
        },
    };
    var date_iter = DateIterator{
        .dates = &date_array,
    };
    while (date_iter.next()) |_| {}
}

pub const DateTag = struct {
    date: *DateTime.Date,
    isWeekend: bool,
    isHoliday: bool,
    isBusinessDay: bool,
};

pub const Calendar = struct {
    type: holidays.HolidayList,
    allocator: Allocator,
    holidays: AutoHashMap(u12, ArrayList(DateTime.Date)),

    /// initialize the Calendar object
    pub fn init(allocator: Allocator, calendar_type: holidays.HolidayList) Calendar {
        return Calendar{
            .allocator = allocator,
            .type = calendar_type,
            .holidays = AutoHashMap(u12, ArrayList(DateTime.Date)).init(allocator),
        };
    }

    /// deinitialize the Calendar object
    pub fn deinit(self: *Calendar) void {
        // deinitialize the HashMap
        defer self.holidays.deinit();
        // deinitialize ArrayList inside the HashMap
        var keys = self.holidays.keyIterator();
        while (keys.next()) |key| {
            const arrList = self.holidays.fetchRemove(key.*);
            if (arrList != null) {
                arrList.?.value.deinit();
            }
        }
    }

    /// set holidays for the year based on the calendar
    fn setHolidays(self: *Calendar, year: u12) !void {
        const year_holidays = try holidays.getHolidays(self.allocator, self.type, year);
        try self.holidays.put(year, year_holidays);
    }

    pub fn addHoliday(self: *Calendar, holiday: DateTime.Date) !void {
        // check if holidays exists
        var holiday_year = self.holidays.getPtr(holiday.year);
        if (holiday_year == null) {
            // if not, set holidays
            try self.setHolidays(holiday.year);
            try self.addHoliday(holiday);
        } else {
            // add holiday into the list
            try holiday_year.?.append(holiday);
        }
    }

    /// Removes a holiday from the holiday in Calendar.
    /// If the holiday has been removed, returns true else false
    pub fn removeHoliday(self: *Calendar, holiday: DateTime.Date) !bool {
        var holidays_year = self.holidays.getPtr(holiday.year);
        if (holidays_year != null) {
            var index: ?usize = null;
            for (holidays_year.?.items, 0..) |day, i| {
                if (day.Equal(holiday)) {
                    index = i;
                    break;
                }
            }
            if (index == null) {
                return false;
            } else {
                const removed = holidays_year.?.swapRemove(index.?);
                std.debug.print("\nHoliday removed : {any}\n", .{removed});
                return true;
            }
        } else {
            return false;
        }
    }
    /// Returns first business day of the month
    pub fn startOfMonth(self: *Calendar, year: u12, month: DateTime.Month) !DateTime.Date {
        const holidays_in_year = self.holidays.get(year);
        if (holidays_in_year == null) {
            try self.setHolidays(year);
            return self.startOfMonth(year, month);
        } else {
            var require_check: bool = true;
            var curr_date = DateTime.Date{ .year = year, .month = month, .day = 1 };
            switch (curr_date.Weekday()) {
                .SUNDAY => {
                    curr_date = curr_date.Add(DateTime.TimeDelta{ .day = 1 });
                },
                .SATURDAY => {
                    curr_date = curr_date.Add(DateTime.TimeDelta{ .day = 2 });
                },
                else => {},
            }
            while (require_check) {
                require_check = false;
                for (holidays_in_year.?.items) |day| {
                    if (day.Equal(curr_date)) {
                        curr_date = curr_date.Add(DateTime.TimeDelta{ .day = 1 });
                        require_check = true;
                    }
                }
            }
            return curr_date;
        }
    }
    /// Returns last business day of the month
    pub fn endOfMonth(self: *Calendar, year: u12, month: DateTime.Month) !DateTime.Date {
        const holidays_in_year = self.holidays.get(year);
        if (holidays_in_year == null) {
            try self.setHolidays(year);
            return self.endOfMonth(year, month);
        } else {
            var require_check: bool = true;
            const last_date = DateTime.getDaysInMonth(DateTime.isLeapYear(year), month);
            var curr_date = DateTime.Date{ .year = year, .month = month, .day = last_date };
            switch (curr_date.Weekday()) {
                .SUNDAY => {
                    curr_date = curr_date.Add(DateTime.TimeDelta{ .day = -2 });
                },
                .SATURDAY => {
                    curr_date = curr_date.Add(DateTime.TimeDelta{ .day = -1 });
                },
                else => {},
            }
            while (require_check) {
                require_check = false;
                for (holidays_in_year.?.items) |day| {
                    if (day.Equal(curr_date)) {
                        curr_date = curr_date.Add(DateTime.TimeDelta{ .day = -1 });
                        require_check = true;
                    }
                }
            }
            return curr_date;
        }
    }
    /// holiday list
    pub fn holidayList(self: *Calendar, start: DateTime.Date, end: DateTime.Date) ![]DateTime.Date {
        const diff_year: usize = end.year - start.year;

        var holiday_list = ArrayList(DateTime.Date).init(self.allocator);
        defer holiday_list.deinit();
        var final_list = ArrayList(DateTime.Date).init(self.allocator);
        defer final_list.deinit();

        var i: u12 = 0;
        while (i <= diff_year) : (i += 1) {
            var holidays_in_year = self.holidays.get(start.year + i);
            if (holidays_in_year == null) {
                try self.setHolidays(start.year + i);
                holidays_in_year = self.holidays.get(start.year + i);
            }
            const slice = holidays_in_year.?.allocatedSlice();
            try holiday_list.appendSlice(slice);
        }

        const start_as_second = start.secondsFromBase();
        const end_as_second = end.secondsFromBase();
        for (holiday_list.items) |item| {
            const seconds_from_base = item.secondsFromBase();
            if (seconds_from_base >= start_as_second and seconds_from_base <= end_as_second) {
                try final_list.append(item);
            }
        }

        return final_list.toOwnedSlice();
    }
    /// all days inbetween
    pub fn dayList(self: *Calendar, start: DateTime.Date, end: DateTime.Date) ![]DateTime.Date {
        const days = ArrayList(DateTime.Date).init(self.allocator);
        defer days.deinit();

        const end_seconds = end.secondsFromBase();
        var curr_date = start;
        while (curr_date.secondsFromBase() <= end_seconds) {
            try days.append(curr_date);
            curr_date = curr_date.Add(DateTime.TimeDelta{ .day = 1 });
        }
        return try days.toOwnedSlice();
    }
    /// business day
    pub fn businessDayList(self: *Calendar, start: DateTime.Date, end: DateTime.Date) ![]DateTime.Date {
        const holiday_list = try self.holidayList(start, end);
        self.allocator.free(holiday_list);
        const all_days = try self.dayList(start, end);
        self.allocator.free(all_days);
        var business_days = ArrayList(DateTime.Date).init(self.allocator);
        defer business_days.deinit();
        for (all_days) |day| {
            var include: bool = true;
            for (holiday_list) |hldy| {
                if (hldy.Equal(day)) {
                    include = false;
                    break;
                }
            }
            if (include) {
                try business_days.append(day);
            }
        }
        return try business_days.toOwnedSlice();
    }
    /// Number of busienss days
    pub fn businessDaysInBetween(self: *Calendar, start: DateTime.Date, end: DateTime.Date) !usize {
        const business_days = try self.businessDayList(start, end);
        self.allocator.free(business_days);
        return business_days.len;
    }
};

test "Holiday List" {
    const test_allocator = std.testing.allocator;
    var test_calendar = Calendar.init(test_allocator, .US_NYSE);
    defer test_calendar.deinit();

    const start = DateTime.Date{ .year = 2024, .month = @enumFromInt(1), .day = 1 };
    const end = DateTime.Date{ .year = 2024, .month = @enumFromInt(1), .day = 31 };
    const list = try test_calendar.holidayList(start, end);
    defer test_allocator.free(list);

    try std.testing.expectEqual(10, list.len);

    var test_calendar_2 = Calendar.init(test_allocator, .WeekendOnly);
    defer test_calendar_2.deinit();
    const list_2 = try test_calendar_2.holidayList(start, DateTime.Date{ .year = 2024, .month = @enumFromInt(12), .day = 31 });
    defer test_allocator.free(list_2);

    try std.testing.expectEqual(104, list_2.len);
}

test "Start Of Month" {
    const test_allocator = std.testing.allocator;
    var test_calendar = Calendar.init(test_allocator, .US_NYSE);
    defer test_calendar.deinit();
    // holiday start
    const first_business_day_1 = try test_calendar.startOfMonth(2024, @enumFromInt(1));
    const control_date_1 = DateTime.Date{ .year = 2024, .month = @enumFromInt(1), .day = 2 };
    try std.testing.expect(control_date_1.Equal(first_business_day_1));
    // saturday start
    const first_business_day_2 = try test_calendar.startOfMonth(2024, @enumFromInt(6));
    const control_date_2 = DateTime.Date{ .year = 2024, .month = @enumFromInt(6), .day = 3 };
    try std.testing.expect(control_date_2.Equal(first_business_day_2));
    // sunday start
    const first_business_day_3 = try test_calendar.startOfMonth(2024, @enumFromInt(12));
    const control_date_3 = DateTime.Date{ .year = 2024, .month = @enumFromInt(12), .day = 2 };
    try std.testing.expect(control_date_3.Equal(first_business_day_3));
}

test "Calendar Memory Safety" {
    const test_allocator = std.testing.allocator;
    var test_calendar = Calendar.init(test_allocator, .WeekendOnly);
    defer test_calendar.deinit();

    var test_arraylist = ArrayList(DateTime.Date).init(test_allocator);
    errdefer test_arraylist.deinit();
    try test_arraylist.append(DateTime.Date{
        .year = 2000,
        .month = @enumFromInt(1),
        .day = 1,
    });
    try test_arraylist.append(DateTime.Date{
        .year = 2000,
        .month = @enumFromInt(12),
        .day = 25,
    });

    try test_calendar.holidays.put(2000, test_arraylist);
}

test "Calendar Weekend Holidays" {
    const test_allocator = std.testing.allocator;

    var test_calendar = Calendar.init(test_allocator, .WeekendOnly);
    defer test_calendar.deinit();

    // Test forming holidays
    try test_calendar.setHolidays(2000);
    const weekends = test_calendar.holidays.get(2000);
    try std.testing.expectEqual(106, weekends.?.items.len);

    // Test Adding a holiday
    const control_holiday = DateTime.Date{ .year = 1999, .month = @enumFromInt(10), .day = 19 };
    try test_calendar.addHoliday(control_holiday);
    var included = false;
    for (test_calendar.holidays.get(1999).?.items) |item| {
        if (control_holiday.Equal(item)) {
            included = true;
            break;
        }
    }
    try std.testing.expect(included);

    // Test removing a holiday
    const removed = try test_calendar.removeHoliday(control_holiday);
    try std.testing.expect(removed);
    var included_after_remove = false;
    for (test_calendar.holidays.get(1999).?.items) |item| {
        if (control_holiday.Equal(item)) {
            included_after_remove = true;
            break;
        }
    }
    try std.testing.expectEqual(false, included_after_remove);
}
