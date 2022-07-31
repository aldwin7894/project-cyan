# frozen_string_literal: true

module FormatDateHelper
  def format_date(seconds)
    day, hr, min, sec = [60, 60, 24].reduce([seconds]) { |m, o| m.unshift(m.shift.divmod(o)).flatten }
    day = day > 0 ? "#{day}d" : nil
    hr = hr > 0 ? "#{hr}h" : nil
    min = min > 0 ? "#{min}m" : nil
    sec = "#{sec}s"

    date = [day, hr, min, sec].compact
    date.join(" ")
  end
end
