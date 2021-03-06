require 'spec_helper'

describe Ordodo::Config do
  describe 'configuration parsing' do
    describe 'malformed document' do
      let(:xml) { '<ordodo><broken</ordodo>' }

      it 'fails' do
        expect do
          described_class.from_xml xml
        end.to raise_exception(Ordodo::Config::Error, /invalid XML/)
      end
    end

    describe 'document not matching DTD' do
      let(:dtd_path) { File.expand_path('../../xml/ordodo.dtd', __FILE__) }
      let(:xml) do
        "<?xml version=\"1.0\" ?>
         <!DOCTYPE ordodo SYSTEM \"#{dtd_path}\">
         <ordodo><unsupported /></ordodo>"
      end

      it 'fails' do
        expect do
          described_class.from_xml xml
        end.to raise_exception(Ordodo::Config::Error, /configuration file invalid/)
      end
    end
  end

  describe 'configuration effects' do
    let(:config) { described_class.from_xml xml }

    describe 'locale' do
      describe 'not specified' do
        let(:xml) { '<ordodo></ordodo>' }

        it 'loads default' do
          config = described_class.from_xml xml
          expect(config.locale).to eq :en
        end

        it 'sets default globally' do
          I18n.locale = :it

          expect do
            config = described_class.from_xml xml
          end.to change { I18n.locale }.to :en
        end
      end

      describe 'known' do
        let(:xml) { '<ordodo locale="it"></ordodo>' }

        it 'loads it' do
          config = described_class.from_xml xml
          expect(config.locale).to eq 'it'
        end

        it 'sets it globally' do
          I18n.locale = :en

          expect do
            config = described_class.from_xml xml
          end.to change { I18n.locale }.to :it
        end
      end

      describe 'unknown' do
        let(:xml) { '<ordodo locale="xx"></ordodo>' }

        it 'fails loudly' do
          expect do
            described_class.from_xml xml
          end.to raise_exception(Ordodo::Config::Error, /not a valid locale/)
        end
      end
    end

    describe 'temporale options' do
      let(:xml) do
        "<ordodo>
           <temporale>
             <option type=\"transfer_to_sunday\" feast=\"Epiphany\" apply=\"#{apply}\" />
         </temporale></ordodo>"
      end

      describe 'applied always' do
        let(:apply) { 'always' }

        it 'loaded data structure' do
          expect(config.temporale_options)
            .to eq({always: {transfer_to_sunday: [:epiphany]}})
        end
      end

      describe 'applied optionally' do
        let(:apply) { 'optional' }

        it 'loaded data structure' do
          expect(config.temporale_options)
            .to eq({optional: {transfer_to_sunday: [:epiphany]}})
        end
      end

      describe 'never applied' do
        let(:apply) { 'never' }

        it 'has no effect on the loaded data structure' do
          expect(config.temporale_options)
            .to eq({})
        end
      end
    end

    describe 'temporale extensions' do
      describe 'supported' do
        let(:xml) do
        "<ordodo>
           <temporale>
             <extension>Christ Eternal Priest</extension>
         </temporale></ordodo>"
        end

        it 'is loaded' do
          expect(config.temporale_extensions)
            .to eq [CalendariumRomanum::Temporale::Extensions::ChristEternalPriest]
        end
      end

      describe 'unsupported' do
        let(:xml) do
        "<ordodo>
           <temporale>
             <extension>Apparition of St. Michael</extension>
         </temporale></ordodo>"
        end

        it 'is loaded' do
          expect do
            described_class.from_xml xml
          end.to raise_exception(Ordodo::Config::Error, /unsupported temporale extension/)
        end
      end
    end

    describe 'calendars' do
      describe 'one' do
        let(:xml) do
        '<ordodo>
           <calendar title="General Roman Calendar">
             <artefact type="packaged" ref="universal-en" />
         </calendar></ordodo>'
        end

        it 'loads' do
          expect(config.calendars.name).to eq 'General Roman Calendar'
          expect(config.calendars.content).to be_a CalendariumRomanum::Sanctorale
        end
      end

      describe 'with multiple artefacts'do
        let(:xml) do
        '<ordodo>
           <calendar title="province of Bohemia">
             <artefact type="packaged" ref="czech-cs" />
             <artefact type="packaged" ref="czech-cechy-cs" />
         </calendar></ordodo>'
        end

        it 'loads' do
          expect(CalendariumRomanum::SanctoraleFactory)
            .to receive(:create_layered)

          config
        end
      end

      describe 'nested' do
        let(:xml) do
        '<ordodo>
           <calendar title="Czech Republic">
             <artefact type="packaged" ref="czech-cs" />
             <calendar title="province of Bohemia">
               <artefact type="packaged" ref="czech-cechy-cs" />
             </calendar>
         </calendar></ordodo>'
        end

        it 'loads' do
          root = config.calendars
          expect(root.name).to eq 'Czech Republic'

          child = root.children.first
          expect(child.name).to eq 'province of Bohemia'
        end

        describe 'child calendar' do
          let(:child_cal) do
            config.calendars['province of Bohemia'].content
          end

          it 'has celebrations from the parent' do
            celebrations = child_cal.get 7, 16
            expect(celebrations)
              .to eq([CR::Celebration.new(
                       'Panny Marie Karmelské',
                       CR::Ranks::MEMORIAL_OPTIONAL,
                       CR::Colours::WHITE
                     )])
          end

          it 'has proper celebrations' do
            celebrations = child_cal.get 7, 4
            expect(celebrations)
              .to eq([CR::Celebration.new(
                       'Sv. Prokopa, opata',
                       CR::Ranks::MEMORIAL_PROPER,
                       CR::Colours::WHITE
                     )])
          end
        end
      end

      describe 'invalid' do
        let(:xml) do
        '<ordodo>
           <calendar title="General Roman Calendar">
             <artefact type="packaged" ref="unknown-ref" />
         </calendar></ordodo>'
        end

        it 'fails' do
          expect do
            config
          end.to raise_exception(Ordodo::Config::Error, /unsupported packaged calendar reference/)
        end
      end

      describe 'data from file' do
        describe 'which exists' do
          let(:xml) do
            '<ordodo>
               <calendar title="General Roman Calendar">
                 <artefact type="file" path="spec/data/minimal.txt" />
             </calendar></ordodo>'
          end

          it 'loads' do
            expect(config.calendars.name).to eq 'General Roman Calendar'
            expect(config.calendars.content).to be_a CalendariumRomanum::Sanctorale
          end
        end

        describe 'which does not exist' do
          let(:xml) do
            '<ordodo>
               <calendar title="General Roman Calendar">
                 <artefact type="file" path="spec/unknown/file.txt" />
             </calendar></ordodo>'
          end

          it 'loads' do
            expect do
              config
            end.to raise_exception(Ordodo::Config::Error, /doesn't exist/)
          end
        end
      end
    end
  end
end
