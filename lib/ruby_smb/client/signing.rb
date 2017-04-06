module RubySMB
  class Client

    # Contains the methods for handling packet signing
    module Signing

      # The NTLM Session Key used for signing
      # @!attribute [rw] session_key
      #   @return [String]
      attr_accessor :session_key

      # Take an SMB1 packet and checks to see if it should be signed.
      # If signing is enabled and we have a session key already, then
      # it will sign the packet appropriately.
      #
      # @param packet [RubySMB::GenericPacket] the packet to sign
      # @return [RubySMB::GenericPacket] the packet, signed if needed
      def smb1_sign(packet)
        if self.signing_required && !self.session_key.empty?
          packet.smb_header.security_features = self.sequence_counter
          signature = OpenSSL::Digest::MD5.digest(self.session_key + packet.to_binary_s)[0,8]
          packet.smb_header.security_features = signature
          self.sequence_counter += 1
          packet
        else
          packet
        end
      end

      # Take an SMB2 packet and checks to see if it should be signed.
      # If signing is enabled and we have a session key already, then
      # it will sign the packet appropriately.
      #
      # @param packet [RubySMB::GenericPacket] the packet to sign
      # @return [RubySMB::GenericPacket] the packet, signed if needed
      def smb2_sign(packet)
        if self.signing_required && !self.session_key.empty?
          hmac = OpenSSL::HMAC.digest(OpenSSL::Digest::SHA256.new, self.session_key, packet.to_binary_s)
          packet.smb2_header.signature = hmac
          packet
        else
          packet
        end
      end

    end
  end
end