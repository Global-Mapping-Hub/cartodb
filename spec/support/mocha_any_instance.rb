# rspec-rails defines Class#any_instance after Mocha loads. That version refuses
# to stub unless RSpec's own mock space is active. These specs use Mocha.
module CartodbMochaAnyInstance
  def any_instance
    if frozen?
      raise Mocha::StubbingError.new("can't stub method on frozen object: #{mocha_inspect}.any_instance", caller)
    end

    @any_instance ||= Mocha::ClassMethods::AnyInstance.new(self)
  end
end

Class.prepend(CartodbMochaAnyInstance) unless Class.ancestors.include?(CartodbMochaAnyInstance)
