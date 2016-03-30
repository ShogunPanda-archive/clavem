# encoding: utf-8
#
# This file is part of the clavem gem. Copyright (C) 2013 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

module Clavem
  # A class to handle oAuth callbacks on the browser via HTTP.
  class Server
    # The template to send to the browser.
    TEMPLATE = <<~EOTEMPLATE
      <html>
        <head>
          <title>Clavem</title>
        </head>
        <body>
          %s
        </body>
      </html>
    EOTEMPLATE
      .freeze

    # Creates a new server.
    #
    # @param authorizer [Authorizer] The authorizer of this server.
    def initialize(authorizer)
      @authorizer = authorizer
      @i18n = Bovem::I18n.new(root: "clavem", path: ::Pathname.new(::File.dirname(__FILE__)).to_s + "/../../locales/")

      process_http_request
    end

    # Save the token and sends a response back to the user.
    def process_http_request
      server = create_server
      socket = server.accept

      # Get the request
      request = socket.gets.gsub(/^[A-Z]+\s(.+)\sHTTP.+$/, "\\1")
      querystring = Addressable::URI.parse(("%s%s" % [@authorizer.callback_url, request]).strip).query_values

      # Send the response and close the socket
      send_response(socket)

      # Handle the token
      token = @authorizer.response_handler.call(querystring)

      update_authorizer(token)
      server.close
    end

    private

    # :nodoc:
    def create_server
      server = TCPServer.new(@authorizer.host, @authorizer.port)
      server.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
      server.setsockopt(:SOCKET, :REUSEADDR, 1)
      server
    end

    # :nodoc:
    def send_response(socket)
      response = TEMPLATE % [@i18n.template]
      socket.print(["HTTP/1.1 200 OK", "Content-Type: text/html; charset=utf-8", "Content-Length: #{response.bytesize}", "Connection: close"].join("\r\n"))
      socket.print("\r\n\r\n" + response)
      socket.close
    end

    # :nodoc:
    def update_authorizer(token)
      if token
        @authorizer.token = token
        @authorizer.status = :succeeded
      else
        @authorizer.status = :denied
      end
    end
  end
end
