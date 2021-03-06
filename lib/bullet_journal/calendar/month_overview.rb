# frozen_string_literal: true

require 'prawn'

module BulletJournal
  ##
  # Module for printing a overview for the month.
  #
  class MonthOverview
    include DateHelper
    include Prawn::View
    include LayoutHelper

    FONT_SIZE = 6

    def initialize(doc, date, options = {})
      @document = doc
      @highlight = options[:highlight]
      @start_date = first_day_of_month(date)
      @end_date = last_day_of_month(date)
      @weeks = calc_weeks(@start_date, @end_date)
    end

    def print(pos, width, height)
      bounding_box [pos[0], pos[1] + height], width: width, height: height do
        print_calendar
      end
    end

    private

    def calc_weeks(start_date, end_date)
      weeks = 1
      week = start_date.cweek
      (start_date..end_date).each do |d|
        if week != d.cweek
          week = d.cweek
          weeks += 1
        end
      end
      weeks
    end

    def cell_width
      width / (@weeks + 1)
    end

    def print_calendar
      split_horizontal at: height / 7 do |split|
        split.top do
          print_month_name
        end
        split.bottom do
          print_calendar_body
        end
      end
    end

    def print_calendar_body
      print_week_names
      (@start_date..@end_date).group_by(&:cweek).each_with_index do |week, i|
        print_cweek(week[1], i)
      end
    end

    def position(x, y)
      y_offset = height / 7 * y
      [cell_width * x, height - y_offset]
    end

    def print_cweek(week, i)
      x = i + 1
      date = week.first
      print_week_number(x, date)
      highlight_week(x) if highlight?(date)
      week.each do |day|
        print_date(x, day)
      end
    end

    def print_week_number(x, date)
      formatted_text_box [{ text: date.cweek.to_s }],
                         at: position(x, 0),
                         width: cell_width, align: :center,
                         size: FONT_SIZE, styles: :bold
    end

    def print_date(x, date)
      y = date.wday
      y = 7 if y.zero?
      formatted_text_box [{ text: date.strftime('%d') }],
                         at: position(x, y),
                         width: cell_width,
                         align: :center,
                         size: FONT_SIZE
    end

    def print_week_names
      %w[KW MO DI MI DO FR SA SO].each_with_index do |s, i|
        formatted_text_box [{ text: s, styles: [:bold] }],
                           at: position(0, i),
                           width: cell_width,
                           align: :center,
                           size: FONT_SIZE
      end
    end

    def print_month_name
      formatted_text_box [{ text: month_name(@start_date), styles: [:bold] }],
                         at: [0, height],
                         width: width,
                         height: height,
                         align: :center,
                         size: FONT_SIZE + 2
    end

    def highlight_week(x)
      pos = [cell_width * x, height + 4]
      rounded_rectangle pos, cell_width, height + 2, 5
      stroke
    end

    def highlight?(date)
      !@highlight.nil? && (@highlight.cweek == date.cweek)
    end
  end
end
