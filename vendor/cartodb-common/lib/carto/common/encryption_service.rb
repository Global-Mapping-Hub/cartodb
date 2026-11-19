require 'active_support/security_utils'
require 'argon2'
require 'digest'
require 'securerandom'

module Carto
  module Common
    # Password hashing compatible with the historical cartodb-common API:
    # Argon2id (with an optional pepper) for stored passwords, and SHA digests
    # when sha_class is given (legacy passwords and invitation tokens).
    class EncryptionService
      def self.encrypt(password:, sha_class: nil, salt: nil, secret: nil)
        if sha_class
          digest = sha_class.new
          digest.update(String(password))
          digest.update(String(salt)) unless salt.nil?
          digest.hexdigest
        else
          options = {}
          options[:secret] = secret unless secret.nil?
          Argon2::Password.new(**options).create(password.to_s)
        end
      end

      def self.verify(password:, secure_password:, salt: nil, secret: nil)
        return false if password.nil? || secure_password.nil?

        if argon2?(secure_password)
          Argon2::Password.verify_password(password.to_s, secure_password.to_s, secret)
        else
          sha_class = secure_password.to_s.length <= 40 ? Digest::SHA1 : Digest::SHA256
          computed = encrypt(password: password, sha_class: sha_class, salt: salt)
          return false unless computed.bytesize == secure_password.to_s.bytesize

          ActiveSupport::SecurityUtils.secure_compare(computed, secure_password.to_s)
        end
      rescue Argon2::ArgonHashFail, ArgumentError
        false
      end

      def self.argon2?(secure_password)
        secure_password.to_s.start_with?('$argon2')
      end

      def self.hex_digest(value)
        Digest::SHA256.hexdigest(value.to_s)
      end

      def self.make_token(length: 32)
        SecureRandom.hex(length / 2)
      end
    end
  end
end
