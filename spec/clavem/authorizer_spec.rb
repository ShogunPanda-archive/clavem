# encoding: utf-8
#
# This file is part of the clavem gem. Copyright (C) 2013 and above Shogun <shogun_panda@me.com>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "spec_helper"

class ClavemDummyServer
  attr_accessor :started

  def start
    self.started = true
  end

  def shutdown
    self.started = false
  end
end

describe Clavem::Authorizer do
  describe ".instance" do
    it("should call .new with the passed arguments") do
      ::Clavem::Authorizer.should_receive(:new).with("URL", "IP", "PORT", "COMMAND", "TITLE", "TEMPLATE", "TIMEOUT")
      ::Clavem::Authorizer.instance("URL", "IP", "PORT", "COMMAND", "TITLE", "TEMPLATE", "TIMEOUT")
    end

    it("should return the same instance") do
      ::Clavem::Authorizer.stub(:new) do Time.now end
      instance = ::Clavem::Authorizer.instance("FIRST")
      expect(::Clavem::Authorizer.instance("SECOND")).to be(instance)
    end

    it("should return a new instance if requested to") do
      ::Clavem::Authorizer.stub(:new) do Time.now end
      instance = ::Clavem::Authorizer.instance("FIRST")
      expect(::Clavem::Authorizer.instance("URL", "IP", "PORT", "COMMAND", "TITLE", "TEMPLATE", "TIMEOUT", true)).not_to be(instance)
    end
  end

  describe "#initialize" do
    it("should handle default arguments") do
      instance = ::Clavem::Authorizer.new("URL")
      expect(instance.url).to eq("URL")
      expect(instance.ip).to eq("127.0.0.1")
      expect(instance.port).to eq(2501)
      expect(instance.command).to eq("open \"{{URL}}\"")
      expect(instance.title).to eq("Clavem Authorization")
      expect(instance.template).to eq(File.read(File.dirname(__FILE__) + "/../../lib/clavem/template.html.erb"))
      expect(instance.timeout).to eq(0)
      expect(instance.response_handler).to be_nil
    end

    it("should assign arguments") do
      instance = ::Clavem::Authorizer.new("URL", "IP", 2511, "COMMAND", "TITLE", "TEMPLATE", 2) do end
      expect(instance.ip).to eq("IP")
      expect(instance.port).to eq(2511)
      expect(instance.command).to eq("COMMAND")
      expect(instance.title).to eq("TITLE")
      expect(instance.template).to eq("TEMPLATE")
      expect(instance.timeout).to eq(2)
      expect(instance.response_handler).to be_a(Proc)
    end

    it("should correct wrong arguments") do
      instance = ::Clavem::Authorizer.new("URL", "IP", 30, nil, nil, "", -1)
      expect(instance.port).to eq(2501)
      expect(instance.timeout).to eq(0)
    end

    it("should setup internal status") do
      instance = ::Clavem::Authorizer.new("URL")
      expect(instance.token).to be_nil
      expect(instance.status).to eq(:waiting)
    end

    it("should return self") do
      expect(::Clavem::Authorizer.new("URL")).to be_a(::Clavem::Authorizer)
    end
  end

  describe "#authorize" do
    it("should call the correct authorize sequence and then return self") do
      sequence = []
      instance = ::Clavem::Authorizer.new("URL")
      server = ClavemDummyServer.new

      # Setup stuff
      instance.stub(:setup_webserver) do sequence << 1 end

      instance.instance_variable_set(:@server, server)
      instance.stub(:setup_interruptions_handling) do sequence << 2 end
      instance.stub(:setup_timeout_handling) do sequence << 3 end
      instance.stub(:open_endpoint) do sequence << 4 end

      server.should_receive(:start)
      expect(instance.authorize).to be(instance)
      expect(sequence).to eq([1, 2, 3, 4])
    end

    it("should raise an exception in case of timeout") do
      instance = ::Clavem::Authorizer.new("URL")
      instance.stub(:setup_webserver).and_raise(::Clavem::Exceptions::Timeout)
      expect { instance.authorize }.to raise_error(::Clavem::Exceptions::Timeout)
      expect(instance.status).to eq(:failure)
    end

    it("should raise an exception in case of errors") do
      instance = ::Clavem::Authorizer.new("URL")
      instance.stub(:setup_webserver).and_raise(ArgumentError)
      expect { instance.authorize }.to raise_error(::Clavem::Exceptions::Failure)
      expect(instance.status).to eq(:failure)
    end

    it("should always run #cleanup") do
      cleaned = false
      instance = ::Clavem::Authorizer.new("URL")
      instance.stub(:cleanup) do cleaned = true end
      instance.stub(:open_endpoint) do end
      instance.stub(:setup_webserver) do end
      instance.instance_variable_set(:@server, ClavemDummyServer.new)

      cleaned = false
      instance.authorize
      expect(cleaned).to be_true

      cleaned = false
      instance.stub(:setup_webserver).and_raise(ArgumentError)
      expect { instance.authorize }.to raise_error(::Clavem::Exceptions::Failure)
      expect(cleaned).to be_true

      cleaned = false
      instance.stub(:setup_webserver).and_raise(::Clavem::Exceptions::Timeout)
      expect { instance.authorize }.to raise_error(::Clavem::Exceptions::Timeout)
      expect(cleaned).to be_true
    end
  end

  describe "#default_response_handler" do

  end

  describe "#open_endpoint" do

  end

  describe "#setup_interruptions_handling" do

  end

  describe "#setup_timeout_handling" do

  end

  describe "#setup_webserver" do

  end

  describe "#cleanup" do

  end
end