require 'spec_helper'

RSpec.describe RubySMB::SMB2::Tree do
  let(:sock)  { double("Socket", peeraddr: '192.168.1.5' ) }
  let(:dispatcher) { RubySMB::Dispatcher::Socket.new(sock) }

  let(:client) { RubySMB::Client.new(dispatcher, username: 'msfadmin', password: 'msfadmin') }
  let(:tree_id) { 2049 }
  let(:path) { '\\192.168.1.1\example' }
  let(:response) {
    packet = RubySMB::SMB2::Packet::TreeConnectResponse.new
    packet.smb2_header.tree_id = tree_id
    packet.maximal_access.read("\xff\x01\x1f\x00")
    packet.share_type = 0x01
    packet
  }

  let(:disco_req) { RubySMB::SMB2::Packet::TreeDisconnectRequest.new }
  let(:disco_resp) { RubySMB::SMB2::Packet::TreeDisconnectResponse.new }

  subject(:tree) {
    described_class.new(client:client, share:path, response:response )
  }

  it { is_expected.to respond_to :client }
  it { is_expected.to respond_to :permissions }
  it { is_expected.to respond_to :share }
  it { is_expected.to respond_to :id }

  it 'inherits the client that spawned it' do
    expect(tree.client).to eq client
  end

  it 'inherits the permissions from the response packet' do
    expect(tree.permissions).to eq response.maximal_access
  end

  it 'inherits the Tree id from the response packet' do
    expect(tree.id).to eq response.smb2_header.tree_id
  end

  describe '#disconnect!' do
    it 'sends a TreeDisconnectRequest with the Tree ID in the header' do
      allow(RubySMB::SMB2::Packet::TreeDisconnectRequest).to receive(:new).and_return(disco_req)
      modified_req = disco_req
      modified_req.smb2_header.tree_id = tree.id
      expect(client).to receive(:send_recv).with(modified_req).and_return(disco_resp.to_binary_s)
      tree.disconnect!
    end

    it 'returns the NTStatus code from the response' do
      allow(client).to receive(:send_recv).and_return(disco_resp.to_binary_s)
      expect(tree.disconnect!).to eq disco_resp.status_code
    end
  end

  describe '#set_header_fields' do
    let(:modified_request) { tree.set_header_fields(disco_req) }
    it 'adds the TreeID to the header' do
      expect(modified_request.smb2_header.tree_id).to eq tree.id
    end

    it 'sets the credit charge to 1' do
      expect(modified_request.smb2_header.credit_charge).to eq 1
    end

    it 'sets the credits to 256' do
      expect(modified_request.smb2_header.credits).to eq 256
    end
  end
end
