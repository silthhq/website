---
title: Decimals & dates
description: Exact money with Decimal, calendar dates with Date, and how times are written to JSON.
---
# Decimals & dates

Money, quantities and rates must never go through `Float64`: `0.1 + 0.2` is not `0.3` in binary floating point. Silth reads `NUMERIC`/`DECIMAL` columns as `Decimal`, an exact decimal number that keeps its scale, and `DATE` columns as `Date`, a calendar day without a time zone.

```crystal
class Invoice < ApplicationModel
  primary_key
  column total_ht : Decimal          # t.decimal :total_ht, precision: 12, scale: 2
  column vat_rate : Decimal          # t.decimal :vat_rate, precision: 5, scale: 2
  column due_on : Date               # t.date :due_on
  timestamps
end

invoice = Invoice.create!(total_ht: Decimal.new("100.00"), vat_rate: Decimal.new("20.00"), due_on: Date.today + 30)
vat = (invoice.total_ht * invoice.vat_rate / 100).round(2)   # => 20.00
invoice.to_json # => {"id":1,"total_ht":"100.00","vat_rate":"20.00","due_on":"2026-12-27",…}
```

`Decimal` and `Date` are `Silth::Decimal` and `Silth::Date`, also available at the top level.

## Decimal

```crystal
price = Decimal.new("19.90")       # from a string (also "1e3", ".5")
Decimal.new(3)                     # from an integer
Decimal.new(0.1)                   # from a float, through its shortest representation: 0.1

price * 3                          # => 59.70   the scales add up (2 + 0)
price + Decimal.new("0.1")         # => 20.00   the larger scale
Decimal.new("1.00") / 2            # => 0.50
Decimal.new("10") / 3              # => 3.3333333333333333333333333333 (28 places at most)
[Decimal.new("1.10"), Decimal.new("2.205")].sum  # => 3.305
```

Arithmetic is exact. Only a division that does not terminate is rounded, at 28 decimal places (or 28 to 29 significant digits), half to even. These are the rules of Rust's `rust_decimal`, Java's `BigDecimal` and .NET's `decimal`, so a port from those languages computes the same amounts.

### Rounding and formatting

```crystal
amount = Decimal.new("2.345")
amount.round(2)                    # => 2.34   half to even (banker's rounding), the default
amount.round(2, :ties_away)        # => 2.35   half away from zero
amount.truncate(2)                 # => 2.34
Decimal.new("-5.1").floor          # => -6
Decimal.new("1.5").round(2)        # => 1.5    round never adds digits…
Decimal.new("1.5").rescale(2)      # => 1.50   …rescale does
Decimal.new("3").to_fixed(2)       # => "3.00"
Decimal.new("12.500").normalize    # => 12.5
```

The modes are Crystal's `Number::RoundingMode`: `:ties_even`, `:ties_away`, `:to_zero`, `:to_positive`, `:to_negative`.

### Comparing and converting

Comparisons look at values, not scales: `Decimal.new("1.50") == Decimal.new("1.5")` is true and both hash the same. `to_f64`, `to_i64` (truncated), `to_big_d` and `Decimal.new(big_decimal)` convert.

### JSON

A `Decimal` is written as a string that keeps its scale (`"12.50"`), so no JavaScript client turns it into a float. Reading accepts a string or a number, kept exactly as written:

```crystal
struct LineInput
  include JSON::Serializable
  getter quantity : Decimal
  getter unit_price : Decimal
end

LineInput.from_json(%({"quantity": 2, "unit_price": "12.50"}))
```

Form requests take decimals too: `field price : Decimal`.

### Sums

`sum` returns a `Float64` for compatibility; use `sum_decimal` on money:

```crystal
Invoice.where(status: "paid").sum_decimal(:total_ht)   # => Decimal, zero when nothing matches
```

SQLite has no decimal type: it stores `NUMERIC` as a float, so the scale is lost there (`12.50` comes back as `12.5`). Use PostgreSQL or MySQL for money.

`BigDecimal` columns are supported as well (`column x : BigDecimal`), but Crystal's `BigDecimal` drops trailing zeros: prefer `Decimal`.

## Date

```crystal
due = Date.new(2026, 11, 27)
due + 30                           # => 2026-12-27
due - Date.new(2026, 11, 1)        # => 26 (days)
due.shift(months: 1)               # => 2026-12-27; Jan 31 + 1 month = Feb 28
due.at_beginning_of_month          # => 2026-11-01
due.at_end_of_month                # => 2026-11-30
due.at_beginning_of_week           # => 2026-11-23 (Monday)
due.day_of_week                    # => Time::DayOfWeek::Friday
due.weekend?                       # => false
Date.today                         # in the machine's time zone
Date.today(Time::Location.load("Europe/Paris"))
Date.parse("2026-11-27")           # also takes the date part of a timestamp
Date.parse?("2026-02-30")          # => nil
due.to_s("%d/%m/%Y")               # => "27/11/2026"
due.to_time                        # midnight UTC; to_time(location) for another zone
(due..due + 6).each { |day| }      # ranges of days
```

A `Date` is written to JSON as `"2026-11-27"`. A model column typed `Time` on a `DATE` column still works (midnight UTC).

## Times in JSON

Times are written in RFC 3339, in UTC, everywhere: models, hashes and `JSON::Serializable` structs. `json_time_precision` in `config/app.yml` sets the fractional digits:

```yaml
# config/app.yml
json_time_precision: 3       # 2026-11-27T10:00:00.000Z (default)
json_time_precision: auto    # 2026-11-27T10:00:00Z, 2026-11-27T10:00:00.250Z, 2026-11-27T10:00:00.123456Z
json_time_precision: 0       # 2026-11-27T10:00:00Z (truncated)
```

`auto` writes no fraction for a whole second and otherwise 3, 6 or 9 digits, as Rust's chrono does. PostgreSQL stores microseconds: `auto` (or `6`) keeps them, so a timestamp read back from JSON matches the database.
