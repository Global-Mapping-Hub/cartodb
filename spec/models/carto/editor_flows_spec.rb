require_relative '../../spec_helper_min'
require_relative '../../../lib/carto/domain_patcher_request_proxy'

describe 'editor flows fixed for users, datasets, and maps' do
  describe 'organization admin creation' do
    it 'grants CREATEROLE before the organization owner role is created' do
      user = Object.new
      user.define_singleton_method(:organization_admin?) { true }
      user.define_singleton_method(:organization_owner?) { true }

      service = CartoDB::UserModule::DBService.new(user)
      order = []
      %i[
        reset_schema_owner
        set_user_privileges_at_db
        set_user_as_organization_member
        rebuild_quota_trigger
        create_ghost_tables_event_trigger
        install_and_configure_geocoder_api_extension
        install_odbc_fdw
      ].each do |method_name|
        service.define_singleton_method(method_name) { nil }
      end
      service.define_singleton_method(:grant_admin_permissions) { order << :grant }
      service.define_singleton_method(:setup_organization_owner) { order << :owner }

      service.setup_organization_user_schema

      order.should eq [:grant, :owner]
    end
  end

  describe 'dataset and map presentation' do
    it 'accepts presenter options as keywords when listing datasets' do
      visualization = Carto::Visualization.new(name: 'stores', type: Carto::Visualization::TYPE_CANONICAL)
      options = { show_table: true, show_stats: true }

      presenter = Carto::Api::VisualizationPresenter.new(visualization, nil, nil, **options.merge(show_stats: false))

      presenter.instance_variable_get(:@show_table).should eq true
      presenter.instance_variable_get(:@show_stats).should eq false
    end
  end

  describe 'map options' do
    it 'stores each option once so the map can be serialized' do
      map = Carto::Map.new
      map.options = {
        'dashboard_menu' => nil,
        'layer_selector' => nil,
        'legends' => false,
        'scrollwheel' => nil
      }

      map.ensure_options

      expect { map.options.to_json }.not_to raise_error
      map.options[:dashboard_menu].should eq true
      map.options['dashboard_menu'].should eq true
      JSON.parse(map.options.to_json).keys.count { |key| key == 'dashboard_menu' }.should eq 1
    end
  end

  describe 'map slide transitions' do
    it 'reads transition options that were stored as json' do
      visualization = Carto::Visualization.new
      visualization.transition_options = { time: 400 }

      stored = visualization.slide_transition_options
      loaded = Carto::Visualization.new
      loaded.slide_transition_options = stored.to_json

      loaded.transition_options.should eq(time: 400)
    end

    it 'accepts transition options from request parameters' do
      options = ActionController::Parameters.new('time' => 400, 'ease' => 'linear')

      Carto::Visualization.normalize_transition_options(options).should eq(time: 400, ease: 'linear')
    end

    it 'uses an empty transition when the stored value is not json' do
      Carto::Visualization.normalize_transition_options('not-json').should eq({})
      Carto::Visualization.normalize_transition_options(nil).should eq({})
    end
  end

  describe 'map widget options' do
    it 'loads json option strings saved on a map' do
      loaded = Carto::CartoJsonSerializer.load('{"dashboard_menu":true}')

      loaded[:dashboard_menu].should eq true
      loaded['dashboard_menu'].should eq true
    end

    it 'leaves an unreadable option string unchanged' do
      Carto::CartoJsonSerializer.load('not-json').should eq 'not-json'
    end

    it 'symbolizes nested widget options' do
      loaded = Carto::CartoJsonSymbolizerSerializer.load('{"style":{"color":"#fff"}}')

      loaded[:style][:color].should eq '#fff'
    end
  end

  describe 'organization details' do
    it 'loads saml configuration stored as a json string' do
      organization = Carto::Organization.new
      organization.auth_saml_configuration = { enabled: true }.to_json.to_json

      organization.send(:ensure_auth_saml_configuration)

      organization.auth_saml_configuration.should eq('enabled' => true)
    end

    it 'clears saml configuration that is not json' do
      organization = Carto::Organization.new
      organization.auth_saml_configuration = 'not-json'

      organization.send(:ensure_auth_saml_configuration)

      organization.auth_saml_configuration.should eq({})
    end
  end

  describe 'public organization map list' do
    it 'recognizes a Rails request when signing the maps request' do
      request = ActionDispatch::Request.new(Rack::MockRequest.env_for('http://localhost/maps'))

      OAuth::RequestProxy.available_proxies[ActionDispatch::Request].should eq(
        OAuth::RequestProxy::ActionDispatchRequest
      )
      OAuth::RequestProxy.proxy(request).should be_a(OAuth::RequestProxy::ActionDispatchRequest)
    end
  end
end
