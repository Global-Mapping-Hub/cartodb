# Classic files are required explicitly and do not match Zeitwerk's file-to-constant map.
# These helper directories are organizational only, their constants omit Helpers.
# app/controllers/carto/helpers is not collapsed because table_locator.rb does use that namespace.

Rails.autoloaders.main.inflector.inflect(
  'markdown_render' => 'MarkdownRenderer',
  'user_db_service' => 'UserDBService'
)

Rails.autoloaders.main.collapse(
  Rails.root.join('app/controllers/helpers'),
  Rails.root.join('app/models/carto/helpers')
)

Rails.autoloaders.main.ignore(
  Rails.root.join('app/connectors/importer.rb'),
  Rails.root.join('app/controllers/carto/helpers/frame_options_helper.rb'),
  Rails.root.join('app/helpers/file_upload.rb'),
  Rails.root.join('app/model_factories/layer_factory.rb'),
  Rails.root.join('app/model_factories/map_factory.rb'),
  Rails.root.join('app/models/carto/helpers/url_validator.rb'),
  Rails.root.join('app/models/carto/license'),
  Rails.root.join('app/models/common'),
  Rails.root.join('app/models/common_data'),
  Rails.root.join('app/models/layer'),
  Rails.root.join('app/models/layer_group'),
  Rails.root.join('app/models/map'),
  Rails.root.join('app/models/named_map'),
  Rails.root.join('app/models/permission'),
  Rails.root.join('app/models/quota_checker.rb'),
  Rails.root.join('app/models/synchronization'),
  Rails.root.join('app/models/table'),
  Rails.root.join('app/models/table_registrar.rb'),
  Rails.root.join('app/models/user'),
  Rails.root.join('app/models/visualization'),
  Rails.root.join('app/models/visualization.rb'),
  Rails.root.join('app/services/visualization')
)
