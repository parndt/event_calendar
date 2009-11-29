module EventCalendar
  module CalendarHelper

    # Returns an HTML calendar which can show multiple, overlapping events across calendar days and rows.
    # Customize using CSS, the below options, and by passing in a code block.
    #
    # The following are optional, available for customizing the default behaviour:
    # :month => Time.now.month # The month to show the calendar for. Defaults to current month.
    # :year => Time.now.year # The year to show the calendar for. Defaults to current year.
    # :abbrev => (0..2) # This option specifies how the day names should be abbreviated.
    #     Use (0..2) for the first three letters, (0..0) for the first, and
    #     (0..-1) for the entire name.
    # :first_day_of_week => 0 # Renders calendar starting on Sunday. Use 1 for Monday, and so on.
    # :show_today => true # Highlights today on the calendar using CSS class.
    # :month_name_text => nil # Displayed center in header row.
    #     Defaults to current month name from Date::MONTHNAMES hash.
    # :previous_month_text => nil # Displayed left of the month name if set
    # :next_month_text => nil # Displayed right of the month name if set
    # :event_strips => [] # An array of arrays, encapsulating the event rows on the calendar
    # :width => nil # Width of the calendar, if none is set then it will stretch the container's width
    # :height => 500 # Approx minimum total height of the calendar (excluding the header).
    #     Height could get added if a day has too many event's to fit.
    # :day_names_height => 18 # Height of the day names table (included in the above 'height' option)
    # :day_nums_height => 18 # Height of the day numbers tables (included in the 'height' option)
    # :event_height => 18 # Height of an individual event row
    # :event_margin => 1 # Spacing of the event rows
    # :event_padding_top => 1 # Padding on the top of the event rows (increase to move text down)
    # :use_javascript => true # Outputs HTML with inline javascript so events spanning multiple days will be highlighted.
    #     If this option is false, cleaner HTML will be output, but events spanning multiple days will
    #     not be highlighted correctly on hover, so it is only really useful if you know your calendar
    #     will only have single-day events. Defaults to true.
    # :link_to_day_action => false # If controller action is passed,
    #     the day number will be a link. Override the day_link method for greater customization.
    #
    # For more customization, you can pass a code block to this method
    #
    # For example usage, see README.
    #
    def calendar(options = {}, &block)
      block ||= Proc.new {|d| nil}

      defaults = {
        :year => Time.zone.now.year,
        :month => Time.zone.now.month,
        :abbrev => (0..2),
        :first_day_of_week => 0,
        :show_today => true,
        :month_name_text => Time.zone.now.strftime("%B %Y"),
        :previous_month_text => nil,
        :next_month_text => nil,
        :event_strips => [],

        # it would be nice to have these in the CSS file
        # but they are needed to perform height calculations
        :width => nil,
        :height => 500,
        :day_names_height => 18,
        :day_nums_height => 18,
        :event_height => 18,
        :event_margin => 1,
        :event_padding_top => 1,

        :use_javascript => true,
        :link_to_day_action => false,
        :calendar_view => "month"
      }
      options = defaults.merge options

      # create the day names array [Sunday, Monday, etc...]
      @day_names = Date::DAYNAMES.dup
      options[:first_day_of_week].times do
        @day_names.push(day_names.shift)
      end

      # default month name for the given number
      options[:month_name_text] ||= Date::MONTHNAMES[options[:month]]

      render :partial => "/calendar/#{options[:calendar_view]}_view", :locals => {:options => options, :block => block}
    end

    # override this in your own helper for greater control
    def day_link(text, date, day_action)
      link_to(text, params.merge(:action => day_action, :day => date.day), :class => 'ec-day-link')
    end

    private

    # calculate the height of each row
    # by default, it will be the height option minus the day names height,
    # divided by the total number of calendar rows
    # this gets tricky, however, if there are too many event rows to fit into the row's height
    # then we need to add additional height
    def cal_row_heights(options)
      # number of rows is the number of days in the event strips divided by 7
      num_cal_rows = options[:event_strips].first.size / 7
      # the row will be at least this big
      min_height = (options[:height] - options[:day_names_height]) / num_cal_rows
      row_heights = []
      num_event_rows = 0
      # for every day in the event strip...
      1.upto(options[:event_strips].first.size+1) do |index|
        num_events = 0
        # get the largest event strip that has an event on this day
        options[:event_strips].each_with_index do |strip, strip_num|
          num_events = strip_num + 1 unless strip[index-1].blank?
        end
        # get the most event rows for this week
        num_event_rows = [num_event_rows, num_events].max
        # if we reached the end of the week, calculate this row's height
        if index % 7 == 0
          total_event_height = options[:event_height] + options[:event_margin]
          calc_row_height = (num_event_rows * total_event_height) + options[:day_nums_height] + options[:event_margin]
          row_height = [min_height, calc_row_height].max
          row_heights << row_height
          num_event_rows = 0
        end
      end
      row_heights
    end

    #
    # helper methods for working with a calendar week
    #

    def days_between(first, second)
      if first > second
        second + (7 - first)
      else
        second - first
      end
    end

    def beginning_of_week(date, start = 0)
      days_to_beg = days_between(start, date.wday)
      date - days_to_beg
    end

    def end_of_week(date, start = 0)
      beg = beginning_of_week(date, start)
      beg + 6
    end

    def weekend?(date)
      [0, 6].include?(date.wday)
    end
  end
end
