# encoding: utf-8
#
# This file is part of the clavem gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "spec_helper"

describe Clavem::Authorizer do
  # TODO@SP: Not needed anymore
  class ClavemDummyServer
    attr_accessor :started

    def start
      self.started = true
    end

    def shutdown
      self.started = false
    end

    def mount_proc(path, &handler)

    end
  end

  # TODO@SP: Not needed anymore
  class ClavemDummyRequest
    attr_reader :query

    def initialize(token = nil)
      @query = {"oauth_token" => token}
    end
  end

  # TODO@SP: Not needed anymore
  class ClavemDummyResponse
    attr_accessor :status
    attr_accessor :body
  end

  let(:instance){::Clavem::Authorizer.new}

  describe ".instance" do
    it "should call .new with the passed arguments" do
      expect(::Clavem::Authorizer).to receive(:new).with("HOST", "PORT", "COMMAND", "TIMEOUT")
      ::Clavem::Authorizer.instance("HOST", "PORT", "COMMAND", "TIMEOUT")
    end

    it "should return the same instance" do
      allow(::Clavem::Authorizer).to receive(:new) { Time.now }
      authorizer = ::Clavem::Authorizer.instance("FIRST")
      expect(::Clavem::Authorizer.instance("SECOND")).to be(authorizer)
    end

    it "should return a new instance if requested to" do
      allow(::Clavem::Authorizer).to receive(:new) { Time.now }
      authorizer = ::Clavem::Authorizer.instance("FIRST")
      expect(::Clavem::Authorizer.instance("HOST", "PORT", "COMMAND", "TIMEOUT", true)).not_to be(authorizer)
    end
  end

  describe "#initialize" do
    it "should handle default arguments" do
      authorizer = ::Clavem::Authorizer.new
      expect(authorizer.host).to eq("localhost")
      expect(authorizer.port).to eq(7772)
      expect(authorizer.command).to eq("open \"{{URL}}\"")
      expect(authorizer.timeout).to eq(0)
      expect(authorizer.response_handler).to be_nil
    end

    it "should assign arguments" do
      authorizer = ::Clavem::Authorizer.new("HOST", 7773, "COMMAND", 2) do end
      expect(authorizer.host).to eq("HOST")
      expect(authorizer.port).to eq(7773)
      expect(authorizer.command).to eq("COMMAND")
      expect(authorizer.timeout).to eq(2)
      expect(authorizer.response_handler).to be_a(Proc)
    end

    it "should correct wrong arguments" do
      authorizer = ::Clavem::Authorizer.new("IP", -10, "", -1)
      expect(authorizer.port).to eq(7772)
      expect(authorizer.timeout).to eq(0)
    end

    it "should setup internal status" do
      authorizer = ::Clavem::Authorizer.new
      expect(authorizer.token).to be_nil
      expect(authorizer.status).to eq(:waiting)
    end

    it "should return self" do
      expect(::Clavem::Authorizer.new).to be_a(::Clavem::Authorizer)
    end
  end

  # TODO@SP: Change this
  describe "#authorize" do
    it "should call the correct authorize sequence and then return self" do
      sequence = []
      instance = ::Clavem::Authorizer.new
      server = ::ClavemDummyServer.new

      # Setup stuff
      allow(instance).to receive(:setup_webserver) do sequence << 1 end

      instance.instance_variable_set(:@server, server)
      allow(instance).to receive(:setup_interruptions_handling) do sequence << 2 end
      allow(instance).to receive(:setup_timeout_handling) do sequence << 3 end
      allow(instance).to receive(:open_endpoint) do sequence << 4 end

      expect(server).to receive(:start)
      expect(instance.authorize("URL")).to be(instance)
      expect(sequence).to eq([1, 2, 3, 4])
    end

    it "should raise an exception in case of timeout" do
      instance = ::Clavem::Authorizer.new
      allow(instance).to receive(:setup_webserver).and_raise(::Clavem::Exceptions::Timeout)
      expect { instance.authorize("URL") }.to raise_error(::Clavem::Exceptions::Timeout)
      expect(instance.status).to eq(:failure)
    end

    it "should raise an exception in case of errors" do
      instance = ::Clavem::Authorizer.new
      allow(instance).to receive(:setup_webserver).and_raise(ArgumentError)
      expect { instance.authorize("URL") }.to raise_error(::Clavem::Exceptions::Failure)
      expect(instance.status).to eq(:failure)
    end

    it "should always run #cleanup" do
      cleaned = false
      instance = ::Clavem::Authorizer.new
      allow(instance).to receive(:cleanup) do cleaned = true end
      allow(instance).to receive(:open_endpoint) do end
      allow(instance).to receive(:setup_webserver) do
        instance.instance_variable_set(:@server, ::ClavemDummyServer.new)
      end

      cleaned = false
      instance.authorize("URL")
      expect(cleaned).to be_true

      cleaned = false
      allow(instance).to receive(:setup_webserver).and_raise(ArgumentError)
      expect { instance.authorize("URL") }.to raise_error(::Clavem::Exceptions::Failure)
      expect(cleaned).to be_true

      cleaned = false
      allow(instance).to receive(:setup_webserver).and_raise(::Clavem::Exceptions::Timeout)
      expect { instance.authorize("URL") }.to raise_error(::Clavem::Exceptions::Timeout)
      expect(cleaned).to be_true
    end
  end

  describe "#callback_url" do
    it "should return the correct callback" do
      expect(::Clavem::Authorizer.new.callback_url).to eq("http://localhost:7772/")
      expect(::Clavem::Authorizer.new("10.0.0.1", "80").callback_url).to eq("http://10.0.0.1:80/")
    end
  end

  # TODO@SP: Change this
  describe "#default_response_handler" do
    it "should return the token" do
      instance = ::Clavem::Authorizer.new
      expect(instance.default_response_handler(instance, ::ClavemDummyRequest.new("TOKEN"), nil)).to eq("TOKEN")
    end

    it "should return an empty string by default" do
      instance = ::Clavem::Authorizer.new
      expect(instance.default_response_handler(instance, ::ClavemDummyRequest.new(nil), nil)).to eq("")
    end
  end

  describe ".localize" do
    it "should set the right locale path" do
      expect(instance.instance_variable_get(:@i18n_locales_path)).to eq(File.absolute_path(::Pathname.new(File.dirname(__FILE__)).to_s + "/../../locales/"))
      instance.localize
    end

    it "should set using English if called without arguments" do
      authorizer = ::Clavem::Authorizer.new
      expect(R18n::I18n).to receive(:new).with([:en, ENV["LANG"], R18n::I18n.system_locale].compact, File.absolute_path(::Pathname.new(File.dirname(__FILE__)).to_s + "/../../locales/")).and_call_original
      authorizer.localize
    end

    it "should set the requested locale" do
      authorizer = ::Clavem::Authorizer.new
      expect(R18n::I18n).to receive(:new).with([:it, ENV["LANG"], R18n::I18n.system_locale].compact, File.absolute_path(::Pathname.new(File.dirname(__FILE__)).to_s + "/../../locales/")).and_call_original
      authorizer.localize(:it)
    end
  end
end