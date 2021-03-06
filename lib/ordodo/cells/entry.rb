module Ordodo
  module Cells
    class Entry < Cell
      def_delegators :model, :vespers_from_following?

      def offices
        model.offices.each_with_index.collect do |office, i|
          Cells::Office.(
            office,
            order: i,
            vespers_from_following: vespers_from_following?,
          )
        end
      end

      def nth_entry?
        options[:order] > 0
      end

      def heading
        model.titles.join(', ') + ':'
      end

      def compline_worth_mentioning?
        vespers_from_following? && !model.vespers_from_following_sunday?
      end

      def vespers
        if model.vespers_from_following_sunday?
          I18n.t 'office.vespers_from_following.sunday'
        elsif model.vespers_from_following_feast?
          I18n.t 'office.vespers_from_following.feast'
        else
          I18n.t 'office.vespers_from_following.solemnity'
        end
      end

      def compline
        vespers_from_following? &&
          I18n.t('office.compline.sunday_first')
      end
    end
  end
end
