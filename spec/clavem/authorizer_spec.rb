# encoding: utf-8
#
# This file is part of the clavem gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require "spec_helper"

describe Clavem::Authorizer do
  let(:subject){::Clavem::Authorizer.new}

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
      expect(authorizer.instance_variable_get(:@response_handler)).to be_nil
    end

    it "should assign arguments" do
      authorizer = ::Clavem::Authorizer.new("HOST", 7773, "COMMAND", 2) do end
      expect(authorizer.host).to eq("HOST")
      expect(authorizer.port).to eq(7773)
      expect(authorizer.command).to eq("COMMAND")
      expect(authorizer.timeout).to eq(2)
      expect(authorizer.instance_variable_get(:@response_handler)).to be_a(Proc)
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

  describe "#authorize" do
    it "should set authorization as waiting" do
      allow(subject).to receive(:perform_request)
      allow(subject).to receive(:process_response)
      subject.authorize("URL")
      expect(subject.waiting?).to be_true
    end

    it "should make a request" do
      allow(subject).to receive(:process_response)
      allow(subject).to receive(:callback_url).and_return("CALLBACK")

      expect(Kernel).to receive(:system).with("open \"URL?oauth_callback=CALLBACK\"")
      subject.authorize("URL")
      expect(Kernel).to receive(:system).with("open \"URL?&oauth_callback=CALLBACK\"")
      subject.authorize("URL?")
      subject.command = "browse {{URL}}"
      expect(Kernel).to receive(:system).with("browse URL?oauth_callback=CALLBACK")
      subject.authorize("URL")
    end

    it "should start a server" do
      allow(subject).to receive(:perform_request)
      subject.timeout = 1
      expect(EM).to receive(:start_server).with(subject.host, subject.port, Clavem::Server, subject)
      subject.authorize("URL")
    end

    it "should return the success" do
      allow(subject).to receive(:perform_request)

      allow(subject).to receive(:process_response) { subject.status = :succeeded }
      expect(subject.authorize("URL")).to be_true

      allow(subject).to receive(:process_response) { subject.status = :failed }
      expect(subject.authorize("URL")).to be_false
    end

    it "should handle errors" do
      allow(Kernel).to receive(:system).and_raise(RuntimeError.new)
      expect { subject.authorize("URL") }.to raise_error(Clavem::Exceptions::Failure)
      expect(subject.failed?).to be_true
    end

    it "should handle timeouts" do
      allow(subject).to receive(:perform_request)

      subject.timeout = 1
      expect(EM).to receive(:stop).and_call_original
      subject.authorize("URL")
    end
  end

  describe "#callback_url" do
    it "should return the correct callback" do
      expect(::Clavem::Authorizer.new.callback_url).to eq("http://localhost:7772/")
      expect(::Clavem::Authorizer.new("10.0.0.1", "80").callback_url).to eq("http://10.0.0.1:80/")
    end
  end

  describe "#response_handler" do
    it "should return the token as default implementation" do
      expect(subject.response_handler.call(nil)).to be_nil
      expect(subject.response_handler.call({"oauth_token" => "TOKEN"})).to eq("TOKEN")
      expect(subject.response_handler.call({"oauth_token" => ["TOKEN 1", "TOKEN 2"]})).to eq("TOKEN 1")
    end

    it "should work as a getter" do
      subject.response_handler = "FOO"
      expect(subject.response_handler).to eq("FOO")
    end
  end

  describe ".localize" do
    it "should set the right locale path" do
      expect(subject.instance_variable_get(:@i18n_locales_path)).to eq(File.absolute_path(::Pathname.new(File.dirname(__FILE__)).to_s + "/../../locales/"))
      subject.localize
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

  describe "#succeeded?" do
    it "should return the correct status" do
      subject.status = :other
      expect(subject.succeeded?).to be_false
      subject.status = :succeeded
      expect(subject.succeeded?).to be_true
    end
  end

  describe "#denied?" do
    it "should return the correct status" do
      subject.status = :other
      expect(subject.denied?).to be_false
      subject.status = :denied
      expect(subject.denied?).to be_true
    end
  end

  describe "#failed?" do
    it "should return the correct status" do
      subject.status = :other
      expect(subject.failed?).to be_false
      subject.status = :failed
      expect(subject.failed?).to be_true
    end
  end

  describe "#waiting?" do
    it "should return the correct status" do
      subject.status = :other
      expect(subject.waiting?).to be_false
      subject.status = :waiting
      expect(subject.waiting?).to be_true
    end
  end
end