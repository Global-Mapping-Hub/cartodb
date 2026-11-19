# Compatibility surface for code written against Rails 4.2 / Ruby 2.4.

class Module
  def alias_method_chain(target, feature)
    without_method = "#{target}_without_#{feature}"
    with_method = "#{target}_with_#{feature}"
    alias_method without_method, target
    alias_method target, with_method
  end
end

if defined?(FactoryBot) && !defined?(FactoryGirl)
  FactoryGirl = FactoryBot
end

unless TOPLEVEL_BINDING.receiver.respond_to?(:shared_context, true)
  module Kernel
    def shared_context(*)
    end

    def include_context(*)
    end
  end
end

if defined?(FactoryBot::DefinitionProxy)
  module FactoryBotStaticAttributeCompat
    def method_missing(name, *args, &block)
      if args.length == 1 && block.nil?
        value = args.first
        association_options = value.is_a?(Hash) && __valid_association_options?(value)
        return __declare_attribute__(name, ::Proc.new { value }) unless association_options
      end
      super
    end
  end
  FactoryBot::DefinitionProxy.prepend(FactoryBotStaticAttributeCompat)
end

ActionController::Base.singleton_class.class_eval do
  {
    before_filter: :before_action,
    after_filter: :after_action,
    around_filter: :around_action,
    prepend_before_filter: :prepend_before_action,
    append_before_filter: :append_before_action,
    prepend_after_filter: :prepend_after_action,
    skip_before_filter: :skip_before_action,
    skip_after_filter: :skip_after_action,
    skip_around_filter: :skip_around_action,
    skip_filter: :skip_before_action
  }.each do |legacy_name, modern_name|
    alias_method legacy_name, modern_name if method_defined?(modern_name) && !method_defined?(legacy_name)
  end
end

ActiveRecord::Base.class_eval do
  alias_method :update_attributes, :update unless method_defined?(:update_attributes)
  alias_method :update_attributes!, :update! unless method_defined?(:update_attributes!)
end

module LegacySerialize
  def serialize(attr_name, coder = nil, **kwargs)
    kwargs[:coder] = coder if coder && !kwargs.key?(:coder)
    super(attr_name, **kwargs)
  end
end
ActiveRecord::Base.singleton_class.prepend(LegacySerialize)

module LegacyRenderText
  def render(*args, **kwargs, &block)
    if kwargs.key?(:text)
      kwargs[:plain] = kwargs.delete(:text)
    elsif args.last.is_a?(Hash) && args.last.key?(:text)
      args[-1] = args.last.dup
      args[-1][:plain] = args[-1].delete(:text)
    end
    super(*args, **kwargs, &block)
  end
end

ActionController::Base.prepend(LegacyRenderText)

module LegacyRedirectBack
  def redirect_to(options = {}, response_options = {})
    if options == :back
      redirect_back(fallback_location: '/', **response_options)
    else
      super
    end
  end
end

ActionController::Base.prepend(LegacyRedirectBack)
