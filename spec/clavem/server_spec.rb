# encoding: utf-8
#
# This file is part of the clavem gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "spec_helper"

describe Clavem::Server do
  let(:authorizer) { Clavem::Authorizer.new }

  describe "#initialize", query: "oauth_token=TOKEN" do
    it "should save the authorizer" do
      allow_any_instance_of(Clavem::Server).to receive(:process_http_request)
      server = Clavem::Server.new(authorizer)
      expect(server.instance_variable_get(:@authorizer)).to be(authorizer)
    end
  end

  describe "#process_http_request" do
    before(:each) do |example|
      allow(Kernel).to receive(:system)

      socket = double(TCPSocket)
      expect(socket).to receive(:gets).and_return("GET /?#{example.metadata[:query]} HTTP/1.1")
      allow(socket).to receive(:print)
      allow(socket).to receive(:close)

      server = double(TCPServer)
      expect(server).to receive(:accept).and_return(socket)
      allow(server).to receive(:close)

      allow_any_instance_of(Clavem::Server).to receive(:create_server).and_return(server)
    end

    it "should save the token and report success", query: "oauth_token=TOKEN" do
      authorizer.authorize("URL")
      expect(authorizer.succeeded?).to be_truthy
      expect(authorizer.token).to eq("TOKEN")
    end

    it "should report failure", query: "notoken=TOKEN" do
      authorizer.authorize("URL")

      expect(authorizer.denied?).to be_truthy
      expect(authorizer.token).to eq(nil)
    end
  end
end