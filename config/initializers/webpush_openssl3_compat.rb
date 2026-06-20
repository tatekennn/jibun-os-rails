# frozen_string_literal: true

# webpush 1.1.0 still uses mutable OpenSSL::PKey::EC APIs such as
# EC#generate_key!, EC#private_key=, and EC#public_key=. Those APIs raise
# OpenSSL::PKey::PKeyError on OpenSSL 3, which is what Render's Ruby runtime
# uses. Keep this initializer until webpush ships native OpenSSL 3 support.
require "openssl"
require "webpush"

module WebpushOpenSSL3Compat
  module_function

  def ec_key_from_raw(public_key, private_key)
    private_bytes = Webpush.decode64(private_key)
    public_bytes = Webpush.decode64(public_key)

    asn1 = OpenSSL::ASN1::Sequence([
      OpenSSL::ASN1::Integer(1),
      OpenSSL::ASN1::OctetString(private_bytes),
      OpenSSL::ASN1::ASN1Data.new([OpenSSL::ASN1::ObjectId("prime256v1")], 0, :CONTEXT_SPECIFIC),
      OpenSSL::ASN1::ASN1Data.new([OpenSSL::ASN1::BitString(public_bytes)], 1, :CONTEXT_SPECIFIC)
    ])

    OpenSSL::PKey::EC.new(asn1.to_der)
  end
end

module Webpush
  class VapidKey
    class << self
      def from_keys(public_key, private_key)
        key = allocate
        key.instance_variable_set(:@curve, WebpushOpenSSL3Compat.ec_key_from_raw(public_key, private_key))
        key.instance_variable_set(:@encoded_public_key, public_key)
        key.instance_variable_set(:@encoded_private_key, private_key)
        key
      end
    end

    def public_key
      @encoded_public_key || Webpush.encode64(curve.public_key.to_bn.to_s(2))
    end

    def public_key_for_push_header
      public_key.delete("=")
    end

    def private_key
      @encoded_private_key || Webpush.encode64(curve.private_key.to_s(2))
    end
  end

  module Encryption
    def encrypt(message, p256dh, auth)
      assert_arguments(message, p256dh, auth)

      group_name = "prime256v1"
      salt = Random.new.bytes(16)

      server = OpenSSL::PKey::EC.generate(group_name)
      server_public_key_bn = server.public_key.to_bn

      group = OpenSSL::PKey::EC::Group.new(group_name)
      client_public_key_bn = OpenSSL::BN.new(Webpush.decode64(p256dh), 2)
      client_public_key = OpenSSL::PKey::EC::Point.new(group, client_public_key_bn)

      shared_secret = server.dh_compute_key(client_public_key)
      client_auth_token = Webpush.decode64(auth)

      info = "WebPush: info\0" + client_public_key_bn.to_s(2) + server_public_key_bn.to_s(2)
      content_encryption_key_info = "Content-Encoding: aes128gcm\0"
      nonce_info = "Content-Encoding: nonce\0"

      prk = HKDF.new(shared_secret, salt: client_auth_token, algorithm: "SHA256", info: info).next_bytes(32)
      content_encryption_key = HKDF.new(prk, salt: salt, info: content_encryption_key_info).next_bytes(16)
      nonce = HKDF.new(prk, salt: salt, info: nonce_info).next_bytes(12)

      ciphertext = encrypt_payload(message, content_encryption_key, nonce)
      serverkey16bn = convert16bit(server_public_key_bn)
      rs = ciphertext.bytesize
      raise ArgumentError, "encrypted payload is too big" if rs > 4096

      aes128gcmheader = "#{salt}" + [rs].pack("N*") + [serverkey16bn.bytesize].pack("C*") + serverkey16bn
      aes128gcmheader + ciphertext
    end
  end
end
