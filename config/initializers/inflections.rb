# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format
# (all these examples are active by default):
# ActiveSupport::Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Zeitwerk camelizes each filename segment
# These acronyms keep VizJSON class names aligned with files such as layer_vizjson_adapter.rb and vizjson3_presenter.rb
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym 'VizJSON'
  inflect.acronym 'VizJSON3'
end
