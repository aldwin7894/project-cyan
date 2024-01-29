# frozen_string_literal: true

module FormatDateHelper
  def format_date(seconds, include_seconds = false, array_values = true)
    day, hr, min, sec = [60, 60, 24].reduce([seconds]) { |m, o| m.unshift(m.shift.divmod(o)).flatten }
    day = day > 0 ? [day, "d"] : nil
    hr = hr > 0 ? [hr, "h"] : nil
    min = !include_seconds ? [min, "m"] : min > 0 ? [min, "m"] : nil
    sec = include_seconds ? [sec.round, "s"] : nil

    date = [day, hr, min, sec].compact
    if !array_values
      date = date.map { |x| x.join() }.join(" ")
    end

    date
  end
end
