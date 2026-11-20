require 'spec_helper_min'
require_relative '../../../lib/carto/basemaps_api_key'

describe Carto::BasemapsApiKey do
  let(:voyager) { 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png' }
  let(:voyager_2x) { 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png' }
  let(:labels) { 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager_only_labels/{z}/{x}/{y}.png' }
  let(:fastly) { 'https://cartocdn_{s}.global.ssl.fastly.net/base-eco/{z}/{x}/{y}.png' }
  let(:stamen) { 'https://stamen-tiles-{s}.a.ssl.fastly.net/toner/{z}/{x}/{y}.png' }

  describe '.apply_to_url' do
    it 'appends the key to cartocdn basemap urls' do
      described_class.apply_to_url(voyager, 'OUR_KEY').should eq "#{voyager}?key=OUR_KEY"
    end

    it 'keeps an existing query string' do
      url = "#{voyager}?foo=1"
      described_class.apply_to_url(url, 'OUR_KEY').should eq "#{url}&key=OUR_KEY"
    end

    it 'replaces a key already present on the url' do
      described_class.apply_to_url("#{voyager}?key=old&x=1", 'OUR_KEY').should eq "#{voyager}?key=OUR_KEY&x=1"
    end

    it 'leaves the url unchanged when no key is configured' do
      described_class.apply_to_url(voyager, nil).should eq voyager
      described_class.apply_to_url(voyager, '').should eq voyager
    end

    it 'leaves other tile providers unchanged' do
      described_class.apply_to_url(fastly, 'OUR_KEY').should eq fastly
      described_class.apply_to_url(stamen, 'OUR_KEY').should eq stamen
    end

    it 'escapes the key' do
      described_class.apply_to_url(voyager, 'a b').should eq "#{voyager}?key=a+b"
    end
  end

  describe '.apply_to_options' do
    it 'adds the key to template urls and label urls without changing the original' do
      options = {
        'urlTemplate' => voyager,
        'urlTemplate2x' => voyager_2x,
        'labels' => { 'urlTemplate' => labels },
        'name' => 'Voyager'
      }

      updated = described_class.apply_to_options(options, 'OUR_KEY')

      updated['urlTemplate'].should eq "#{voyager}?key=OUR_KEY"
      updated['urlTemplate2x'].should eq "#{voyager_2x}?key=OUR_KEY"
      updated['labels']['urlTemplate'].should eq "#{labels}?key=OUR_KEY"
      updated['name'].should eq 'Voyager'
      options['urlTemplate'].should eq voyager
    end

    it 'updates symbol keys' do
      options = { urlTemplate: voyager }
      described_class.apply_to_options(options, 'OUR_KEY')[:urlTemplate].should eq "#{voyager}?key=OUR_KEY"
    end
  end

  describe '.apply_to_basemaps!' do
    it 'updates every cartocdn template in the basemap catalog' do
      basemaps = {
        'CARTO' => {
          'voyager' => { 'urlTemplate' => voyager, 'labels' => { 'url' => labels } },
          'eco' => { 'urlTemplate' => fastly }
        },
        'Stamen' => {
          'toner' => { 'urlTemplate' => stamen }
        }
      }

      described_class.apply_to_basemaps!(basemaps, 'OUR_KEY')

      basemaps['CARTO']['voyager']['urlTemplate'].should eq "#{voyager}?key=OUR_KEY"
      basemaps['CARTO']['voyager']['labels']['url'].should eq "#{labels}?key=OUR_KEY"
      basemaps['CARTO']['eco']['urlTemplate'].should eq fastly
      basemaps['Stamen']['toner']['urlTemplate'].should eq stamen
    end

    it 'does nothing when the key is blank' do
      basemaps = { 'CARTO' => { 'voyager' => { 'urlTemplate' => voyager } } }
      described_class.apply_to_basemaps!(basemaps, '')
      basemaps['CARTO']['voyager']['urlTemplate'].should eq voyager
    end
  end

  describe 'configured key' do
    it 'uses carto_basemaps_api_key from the application config' do
      Cartodb.with_config(carto_basemaps_api_key: 'OUR_KEY') do
        described_class.apply_to_url(voyager).should eq "#{voyager}?key=OUR_KEY"
      end
    end
  end
end
