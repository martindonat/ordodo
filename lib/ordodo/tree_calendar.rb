module Ordodo
  class TreeCalendar
    def initialize(year, sanctorale_tree)
      @year = year
      @calendar_tree = build_calendar_tree sanctorale_tree
    end

    def each_day
      root_calendar = @calendar_tree.content
      root_calendar.temporale.date_range.each do |date|
        yield day(date)
      end
    end

    def day(date)
      build_day_tree(date, @calendar_tree)
    end

    private

    def build_calendar_tree(sanctorale_tree)
      sanctorale = sanctorale_tree.content
      calendar = CalendariumRomanum::Calendar.new(@year, sanctorale)
      node = Tree::TreeNode.new(sanctorale_tree.name, calendar)

      sanctorale_tree.children.each do |child|
        node << build_calendar_tree(child)
      end

      node
    end

    def build_day_tree(date, calendar_tree)
      calendar = calendar_tree.content
      day = calendar.day date
      node = Tree::TreeNode.new(calendar_tree.name, day)

      calendar_tree.children.each do |child|
        node << build_day_tree(date, child)
      end

      node
    end
  end
end
