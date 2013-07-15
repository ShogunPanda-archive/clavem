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

  def mount_proc(path, &handler)

  end
end

class ClavemDummyRequest
  attr_reader :query

  def initialize(token = nil)
    @query = {"oauth_token" => token}
  end
end

class ClavemDummyResponse
  attr_accessor :status
  attr_accessor :body
end

describe Clavem::Authorizer do
  let(:instance){::Clavem::Authorizer.new}

  describe ".instance" do
    it("should call .new with the passed arguments") do
      ::Clavem::Authorizer.should_receive(:new).with("IP", "PORT", "COMMAND", "TITLE", "TEMPLATE", "TIMEOUT")
      ::Clavem::Authorizer.instance("IP", "PORT", "COMMAND", "TITLE", "TEMPLATE", "TIMEOUT")
    end

    it("should return the same instance") do
      ::Clavem::Authorizer.stub(:new) { Time.now }
      authorizer = ::Clavem::Authorizer.instance("FIRST")
      expect(::Clavem::Authorizer.instance("SECOND")).to be(authorizer)
    end

    it("should return a new instance if requested to") do
      ::Clavem::Authorizer.stub(:new) { Time.now }
      authorizer = ::Clavem::Authorizer.instance("FIRST")
      expect(::Clavem::Authorizer.instance("IP", "PORT", "COMMAND", "TITLE", "TEMPLATE", "TIMEOUT", true)).not_to be(authorizer)
    end
  end

  describe "#initialize" do
    it("should handle default arguments") do
      authorizer = ::Clavem::Authorizer.new
      expect(authorizer.ip).to eq("127.0.0.1")
      expect(authorizer.port).to eq(2501)
      expect(authorizer.command).to eq("open \"{{URL}}\"")
      expect(authorizer.title).to eq("Clavem Authorization")
      expect(authorizer.template).to eq(File.read(File.dirname(__FILE__) + "/../../lib/clavem/template.html.erb"))
      expect(authorizer.timeout).to eq(0)
      expect(authorizer.response_handler).to be_nil
    end

    it("should assign arguments") do
      authorizer = ::Clavem::Authorizer.new("IP", 2511, "COMMAND", "TITLE", "TEMPLATE", 2) do end
      expect(authorizer.ip).to eq("IP")
      expect(authorizer.port).to eq(2511)
      expect(authorizer.command).to eq("COMMAND")
      expect(authorizer.title).to eq("TITLE")
      expect(authorizer.template).to eq("TEMPLATE")
      expect(authorizer.timeout).to eq(2)
      expect(authorizer.response_handler).to be_a(Proc)
    end

    it("should correct wrong arguments") do
      authorizer = ::Clavem::Authorizer.new("IP", -10, nil, nil, "", -1)
      expect(authorizer.port).to eq(2501)
      expect(authorizer.timeout).to eq(0)
    end

    it("should setup internal status") do
      authorizer = ::Clavem::Authorizer.new
      expect(authorizer.token).to be_nil
      expect(authorizer.status).to eq(:waiting)
    end

    it("should return self") do
      expect(::Clavem::Authorizer.new).to be_a(::Clavem::Authorizer)
    end
  end

  describe "#authorize" do
    it("should call the correct authorize sequence and then return self") do
      sequence = []
      instance = ::Clavem::Authorizer.new
      server = ::ClavemDummyServer.new

      # Setup stuff
      instance.stub(:setup_webserver) do sequence << 1 end

      instance.instance_variable_set(:@server, server)
      instance.stub(:setup_interruptions_handling) do sequence << 2 end
      instance.stub(:setup_timeout_handling) do sequence << 3 end
      instance.stub(:open_endpoint) do sequence << 4 end

      server.should_receive(:start)
      expect(instance.authorize("URL")).to be(instance)
      expect(sequence).to eq([1, 2, 3, 4])
    end

    it("should raise an exception in case of timeout") do
      instance = ::Clavem::Authorizer.new
      instance.stub(:setup_webserver).and_raise(::Clavem::Exceptions::Timeout)
      expect { instance.authorize("URL") }.to raise_error(::Clavem::Exceptions::Timeout)
      expect(instance.status).to eq(:failure)
    end

    it("should raise an exception in case of errors") do
      instance = ::Clavem::Authorizer.new
      instance.stub(:setup_webserver).and_raise(ArgumentError)
      expect { instance.authorize("URL") }.to raise_error(::Clavem::Exceptions::Failure)
      expect(instance.status).to eq(:failure)
    end

    it("should always run #cleanup") do
      cleaned = false
      instance = ::Clavem::Authorizer.new
      instance.stub(:cleanup) do cleaned = true end
      instance.stub(:open_endpoint) do end
      instance.stub(:setup_webserver) do
        instance.instance_variable_set(:@server, ::ClavemDummyServer.new)
      end

      cleaned = false
      instance.authorize("URL")
      expect(cleaned).to be_true

      cleaned = false
      instance.stub(:setup_webserver).and_raise(ArgumentError)
      expect { instance.authorize("URL") }.to raise_error(::Clavem::Exceptions::Failure)
      expect(cleaned).to be_true

      cleaned = false
      instance.stub(:setup_webserver).and_raise(::Clavem::Exceptions::Timeout)
      expect { instance.authorize("URL") }.to raise_error(::Clavem::Exceptions::Timeout)
      expect(cleaned).to be_true
    end
  end

  describe "#callback_url" do
    it("should return the correct callback") do
      expect(::Clavem::Authorizer.new.callback_url).to eq("http://127.0.0.1:2501/")
      expect(::Clavem::Authorizer.new("10.0.0.1", "80").callback_url).to eq("http://10.0.0.1:80/")
    end
  end

  describe "#default_response_handler" do
    it("should return the token") do
      instance = ::Clavem::Authorizer.new
      expect(instance.default_response_handler(instance, ::ClavemDummyRequest.new("TOKEN"), nil)).to eq("TOKEN")
    end

    it("should return an empty string by default") do
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
      R18n::I18n.should_receive(:new).with([:en, ENV["LANG"], R18n::I18n.system_locale].compact, File.absolute_path(::Pathname.new(File.dirname(__FILE__)).to_s + "/../../locales/")).and_call_original
      authorizer.localize
    end

    it "should set the requested locale" do
      authorizer = ::Clavem::Authorizer.new
      R18n::I18n.should_receive(:new).with([:it, ENV["LANG"], R18n::I18n.system_locale].compact, File.absolute_path(::Pathname.new(File.dirname(__FILE__)).to_s + "/../../locales/")).and_call_original
      authorizer.localize(:it)
    end
  end

  # PRIVATE
  describe "#open_endpoint" do
    it("should call system with the right command") do
      Kernel.should_receive(:system).with("open \"URL\"")
      instance.instance_variable_set(:@url, "URL")
      instance.send(:open_endpoint)

      Kernel.should_receive(:system).with("COMMAND")
      ::Clavem::Authorizer.new("IP", "PORT", "COMMAND").send(:open_endpoint)
    end

    it("should raise exception in case of failures") do
      Kernel.stub(:system).and_raise(RuntimeError)
      expect { instance.send(:open_endpoint) }.to raise_error(::Clavem::Exceptions::Failure)
    end
  end

  describe "#setup_interruptions_handling" do
    it("should add handler for SIGINT, SIGTERM, SIGKILL") do
      Kernel.should_receive(:trap).with("USR2")
      Kernel.should_receive(:trap).with("INT")
      Kernel.should_receive(:trap).with("TERM")
      Kernel.should_receive(:trap).with("KILL")
      instance.send(:setup_interruptions_handling)
    end
  end

  describe "#setup_timeout_handling" do
    it("should not set a timeout handler by default") do
      authorizer = ::Clavem::Authorizer.new
      authorizer.stub(:open_endpoint) do end
      authorizer.stub(:setup_webserver) do authorizer.instance_variable_set(:@server, ::ClavemDummyServer.new) end
      authorizer.authorize("URL")
      expect(authorizer.instance_variable_get(:@timeout_handler)).to be_nil
    end

    it("should set and execute a timeout handler") do
      Process.should_receive(:kill).with("USR2", 0)
      Kernel.should_receive(:sleep).with(0.5)

      server = ::ClavemDummyServer.new
      server.stub(:start) do sleep(1) end

      authorizer = ::Clavem::Authorizer.new("IP", "PORT", "COMMAND", "TITLE", "TEMPLATE", 500)
      authorizer.stub(:open_endpoint) do end
      authorizer.stub(:setup_webserver) do authorizer.instance_variable_set(:@server, server) end
      expect { authorizer.authorize("URL") }.to raise_error(::Clavem::Exceptions::Timeout)

      thread = authorizer.instance_variable_get(:@timeout_thread)
      expect(thread).to be_a(Thread)
      expect(authorizer.instance_variable_get(:@timeout_expired)).to be_true
    end
  end

  describe "#setup_webserver" do
    it "should initialize a web server with correct arguments" do
      logger = WEBrick::Log.new("/dev/null")
      WEBrick::Log.stub(:new).and_return(logger)

      ::WEBrick::HTTPServer.should_receive(:new).with(BindAddress: "10.0.0.1", Port: 80, Logger: logger, AccessLog: [nil, nil]).and_return(::ClavemDummyServer.new)
      authorizer = ::Clavem::Authorizer.new("10.0.0.1", 80)
      authorizer.send(:setup_webserver)
    end

    it "should setup a single request handler on /" do
      server = ::ClavemDummyServer.new
      ::WEBrick::HTTPServer.stub(:new).and_return(server)
      authorizer = ::Clavem::Authorizer.new("IP", "PORT")
      server.should_receive(:mount_proc).with("/")
      authorizer.send(:setup_webserver)
    end
  end

  describe "#dispatch_request" do
    let(:request) { ::ClavemDummyRequest.new }
    let(:response) { ::ClavemDummyResponse.new }
    let(:server) { ::ClavemDummyServer.new }

    it "should call the correct handler" do
      instance.instance_variable_set(:@server, ::ClavemDummyServer.new)
      instance.should_receive(:default_response_handler).with(instance, request, response)
      instance.send(:dispatch_request, request, response)

      authorizer = ::Clavem::Authorizer.new do end
      authorizer.instance_variable_set(:@server, ::ClavemDummyServer.new)
      authorizer.response_handler.should_receive(:call).with(authorizer, request, response)
      authorizer.send(:dispatch_request, request, response)
    end

    it "should handle request only if the status is still :waiting" do
      authorizer = ::Clavem::Authorizer.new
      authorizer.instance_variable_set(:@server, server)
      authorizer.status = :waiting
      server.should_receive(:shutdown)
      authorizer.send(:dispatch_request, request, response)

      authorizer = ::Clavem::Authorizer.new
      authorizer.instance_variable_set(:@server, server)
      authorizer.status = :success
      server.should_not_receive(:shutdown)
      authorizer.send(:dispatch_request, request, response)
    end

    it "should correctly set status" do
      authorizer = ::Clavem::Authorizer.new
      authorizer.instance_variable_set(:@server, server)
      authorizer.send(:dispatch_request, ::ClavemDummyRequest.new("TOKEN"), response)
      expect(authorizer.status).to eq(:success)
      expect(response.status).to eq(200)

      authorizer = ::Clavem::Authorizer.new
      authorizer.instance_variable_set(:@server, server)
      authorizer.send(:dispatch_request, request, response)
      expect(authorizer.status).to eq(:denied)
      expect(response.status).to eq(403)
    end

    it "should render the body of the response" do
      authorizer = ::Clavem::Authorizer.new
      authorizer.instance_variable_set(:@server, server)
      authorizer.instance_variable_get(:@compiled_template).should_receive(:result).and_return("TEMPLATE")
      authorizer.send(:dispatch_request, request, response)
      expect(response.body).to eq("TEMPLATE")
    end
  end

  describe "#cleanup" do
    it "should shutdown the server and cleanup signal handling" do
      server = ::ClavemDummyServer.new
      server.stub(:start) do sleep(1) end

      authorizer = ::Clavem::Authorizer.new("IP", "PORT", "COMMAND", "TITLE", "TEMPLATE")
      authorizer.stub(:open_endpoint) do end
      authorizer.stub(:setup_webserver) do authorizer.instance_variable_set(:@server, server) end
      authorizer.authorize("URL")

      Kernel.should_receive(:trap).with("USR2", "DEFAULT")
      Kernel.should_receive(:trap).with("INT", "DEFAULT")
      Kernel.should_receive(:trap).with("TERM", "DEFAULT")
      Kernel.should_receive(:trap).with("KILL", "DEFAULT")
      server.should_receive(:shutdown)
      authorizer.send(:cleanup)
    end

    it "should exit timeout handling thread if active" do
      thread = nil
      server = ::ClavemDummyServer.new
      server.stub(:start) do sleep(1) end

      authorizer = ::Clavem::Authorizer.new("IP", "PORT", "COMMAND", "TITLE", "TEMPLATE", 5000)
      authorizer.send(:setup_timeout_handling)
      thread = authorizer.instance_variable_get(:@timeout_thread)
      thread.should_receive(:exit)
      authorizer.send(:cleanup)
    end
  end
end