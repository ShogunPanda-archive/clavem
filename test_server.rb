#!/usr/bin/env ruby

require "webrick"

server = ::WEBrick::HTTPServer.new(Port: 2502, Logger: WEBrick::Log.new("/dev/null"), AccessLog: [nil, nil])
['INT', 'TERM', 'KILL'].each { |signal| trap(signal) { server.shutdown } }

server.mount_proc '/' do |request, response|
  url = request.query["url"] && request.query["url"].to_s.strip.length > 0 ? request.query["url"].to_s.strip : ""
  token = request.query["token"] && request.query["token"].to_s.strip.length > 0 ? request.query["token"].to_s.strip : nil
  wait = request.query["wait"].to_i
  sleep wait if wait > 0
  response.set_redirect(WEBrick::HTTPStatus::TemporaryRedirect, url + "?" + (token ? "oauth_token=#{token}" : "failure=FAILURE"))
end

server.start
