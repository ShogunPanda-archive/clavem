# encoding: utf-8
#
# This file is part of the clavem gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "spec_helper"

describe Clavem::Server do
  let(:authorizer) { Clavem::Authorizer.new }

  around(:each) do |example|
    EM.run do
      EM.start_server("localhost", 7772, Clavem::Server, authorizer)
      EM.add_timer(0.1) do
        @request = EventMachine::HttpRequest.new("http://localhost:7772/?#{example.metadata[:query]}").get
        @request.callback { example.call }
      end
    end
  end

  describe "#initialize", query: "oauth_token=TOKEN" do
    it "should save the authorizer" do
      server = Clavem::Server.new("UNUSED", authorizer)
      expect(server.instance_variable_get(:@authorizer)).to be(authorizer)
    end
  end

  describe "#process_http_request" do
    it "should save the token and report success", query: "oauth_token=TOKEN" do
      expect(authorizer.succeeded?).to be_true
      expect(authorizer.token).to eq("TOKEN")
    end

    it "should save the token and report failure", query: "notoken=TOKEN" do
      expect(authorizer.denied?).to be_true
      expect(authorizer.token).to eq(nil)
    end
  end
end