# encoding: utf-8
#
# This file is part of the clavem gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at https://choosealicense.com/licenses/mit.
#

Lazier.load!(:object)

# A local callback server for oAuth web-flow.
module Clavem
  # Exceptions used by {Authorizer Authorizer}.
  module Exceptions
    # This exception is raised whether an error occurs.
    class Failure < ::StandardError
    end
  end

  # A class to handle oAuth authorizations.
  #
  # @attribute url
  #   @return [String] The URL where to send the user to start authorization..
  # @attribute host
  #   @return [String] The host address on which listening for replies. Default is `localhost`.
  # @attribute port
  #   @return [Fixnum] The port on which listening for replies. Default is `7772`.
  # @attribute command
  #   @return [String] The command to open the URL. `{{URL}}` is replaced with the specified URL. Default is `open "{{URL}}"`.
  # @attribute timeout
  #   @return [Fixnum] The amount of seconds to wait for response from the remote endpoint before returning a failure. Default is `0`, which means *disabled*.
  # @attribute response_handler
  #   @return [Proc] A Ruby block to handle response and check for success.
  #     The block must accept a querystring hash (which all values are arrays) and return a token or `nil` if the authentication was denied.
  # @attribute token
  #   @return [String] The token obtained by the remote endpoint.
  # @attribute status
  #   @return [Symbol] The status of the request. Can be `:succeeded`, `:denied`, `:failed` and `:waiting`.
  # @attribute [r] :i18n
  #   @return [Bovem::I18n] A localizer object.
  class Authorizer
    attr_accessor :url
    attr_accessor :host
    attr_accessor :port
    attr_accessor :command
    attr_accessor :timeout
    attr_accessor :response_handler
    attr_accessor :token
    attr_accessor :status
    attr_reader :i18n

    # Returns a unique (singleton) instance of the authorizer.
    #
    # @param host [String] The host address on which listening for replies. Default is `localhost`.
    # @param port [Fixnum] The port on which listening for replies. Default is `7772`.
    # @param command [String|nil] The command to open the URL. `{{URL}}` is replaced with the specified URL. Default is `open "{{URL}}"`.
    # @param timeout [Fixnum] The amount of seconds to wait for response from the remote endpoint before returning a failure.
    #   Default is `0`, which means *disabled*.
    # @param response_handler [Proc] A Ruby block to handle response and check for success. See {#response_handler}.
    # @param force [Boolean] If to force recreation of the instance.
    # @return [Authorizer] The unique (singleton) instance of the authorizer.
    def self.instance(host: "localhost", port: 7772, command: nil, timeout: 0, force: false, &response_handler)
      @instance = nil if force
      @instance ||= Clavem::Authorizer.new(host: host, port: port, command: command, timeout: timeout, &response_handler)
      @instance
    end

    # Creates a new authorizer.
    #
    # @param host [String] The host address on which listening for replies. Default is `localhost`.
    # @param port [Fixnum] The port on which listening for replies. Default is `7772`.
    # @param command [String|nil] The command to open the URL. `{{URL}}` is replaced with the specified URL. Default is `open "{{URL}}"`.
    # @param timeout [Fixnum] The amount of seconds to wait for response from the remote endpoint before returning a failure.
    #   Default is `0`, which means *disabled*.
    # @param response_handler [Proc] A Ruby block to handle response and check for success. See {#response_handler}.
    # @return [Authorizer] The new authorizer.
    def initialize(host: "localhost", port: 7772, command: nil, timeout: 0, &response_handler)
      @i18n = Bovem::I18n.new(root: "clavem.errors", path: ::Pathname.new(::File.dirname(__FILE__)).to_s + "/../../locales/")
      @host = host.ensure_string
      @port = port.to_integer
      @command = command.ensure_string
      @timeout = timeout.to_integer
      @response_handler = response_handler
      @token = nil
      @status = :waiting

      sanitize_arguments
      self
    end

    # Starts the authorization flow.
    #
    # @param url [String] The URL where to send the user to start authorization.
    # @param append_callback [Boolean] If to append the callback to the url using `oauth_callback` parameter.
    # @return [Boolean] `true` if authorization succeeded, `false` otherwise.
    def authorize(url, append_callback = true)
      url = Addressable::URI.parse(url)
      url.query_values = (url.query_values || {}).merge({oauth_callback: callback_url}) if append_callback

      @url = url.to_s
      @status = :waiting
      @token = nil

      begin
        perform_request
        process_response
      rescue => e
        @status = :failed
        raise(Clavem::Exceptions::Failure, @i18n.response_failure(e.to_s))
      end

      succeeded?
    end

    # Returns the callback_url for this authorizer.
    #
    # @return [String] The callback_url for this authorizer.
    def callback_url
      Addressable::URI.new(scheme: "http", host: host, port: port).to_s
    end

    # Returns the response handler for the authorizer.
    #
    def response_handler
      @response_handler || ->(querystring) { (querystring || {})["oauth_token"] }
    end

    # Checks if authentication succeeded.
    #
    # @return [Boolean] `true` if authorization succeeded, `false otherwise`.
    def succeeded?
      @status == :succeeded
    end

    # Checks if authentication was denied.
    #
    # @return [Boolean] `true` if authorization was denied, `false otherwise`.
    def denied?
      @status == :denied
    end

    # Checks if authentication failed (which means that some error occurred).
    #
    # @return [Boolean] `true` if authorization failed, `false otherwise`.
    def failed?
      @status == :failed
    end

    # Checks if authentication is still pending.
    #
    # @return [Boolean] `true` if authorization is still pending, `false otherwise`.
    def waiting?
      @status == :waiting
    end

    private

    # :nodoc:
    def sanitize_arguments
      @host = "localhost" if @host.blank?
      @port = 7772 if @port.to_integer < 1
      @command = "open \"{{URL}}\"" if @command.blank?
      @timeout = 0 if @timeout < 0
    end

    # :nodoc:
    def perform_request
      # Open the oAuth endpoint into the browser
      Kernel.system(@command.gsub("{{URL}}", @url.ensure_string))
    rescue => e
      raise(Clavem::Exceptions::Failure, @i18n.open_failure(@url.ensure_string, e.to_s))
    end

    # :nodoc:
    def process_response
      server = Thread.new do
        Clavem::Server.new(self)
      end

      @timeout > 0 ? server.join(@timeout) : server.join
    rescue Interrupt
      raise(Clavem::Exceptions::Failure, @i18n.interrupted)
    end
  end
end
