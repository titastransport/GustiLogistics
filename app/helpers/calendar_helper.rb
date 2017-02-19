module CalendarHelper
  # Called in calendar view template
  def calendar(date = Date.today, &block)
    Calendar.new(self, date, block).table
  end

  # Struct makes it convient way to define accessors for the various attributes
  class Calendar < Struct.new(:view, :date, :callback)
    HEADER = %w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday]
    START_DAY = :monday

    delegate :content_tag, to: :view

    def table
      content_tag :table, class: "calendar" do
        header + week_rows
      end
    end

    def header
      content_tag :tr do
        HEADER.map { |day| content_tag :th, day }.join.html_safe
      end
    end

    def week_rows
      weeks.map do |week|
        content_tag :tr do 
          week.map { |day| day_cell(day) }.join.html_safe
        end
      end.join.html_safe
    end

    # Block from calendar index view get's executed here for each day when
    # calendar is generated 
    def day_cell(day)
      content_tag :td, class: day_classes(day) do 
        content_tag(:div, view.capture(day, &callback), class: "content")
      end
    end

    # Possible to add on more classes
    def day_classes(day)
      classes = []
      classes << "today" if day == Date.today
      classes << "notmonth" if day.month != date.month
      classes.empty? ? nil : classes.join(" ")
    end

    def weeks
      first = date.beginning_of_month.beginning_of_week(START_DAY)
      last = date.end_of_month.end_of_week(START_DAY)
      (first..last).to_a.in_groups_of(7)
    end
  end
end
