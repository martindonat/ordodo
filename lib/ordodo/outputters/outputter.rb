module Ordodo
  module Outputters
    class Outputter
      extend Forwardable

      def initialize(config, output_dir: nil, output_filename:nil, templates_dir: nil, globals: {})
        @config = config
        @output_dir = output_dir
        @output_filename = output_filename
        @templates_dir = templates_dir
        @globals = globals
      end

      attr_reader :config
      def_delegators :@config, :year, :title

      def prepare
      end

      def before_season(season)
      end

      def before_month(month)
      end

      def <<(record)
      end

      def finish
      end
    end
  end
end
