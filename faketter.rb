#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'rubygems'
require 'highline'

$settings = {
  :name => 'name',
  :pass => 'pass',
}

class AccessDenied < StandardError; end

module Faketter

  def self.set(name, pass)
    @name = name
    @pass = pass.crypt('fake')
  end

  def self.login!
    puts "Username: #{@name}"
    pass = HighLine.new.ask('Password: ') {|q| q.echo = '*' }
    raise AccessDenied unless pass.crypt(@pass) == @pass
    puts 'logged in'
    Client.new @name
  end

  class Client

    attr_reader :user

    def initialize(name)
      @user    = name
      @console = HighLine.new
      @tweets  = []
    end

    def run
      while cmd = @console.ask('> ')
        do_command cmd
        puts
      end
    end

    private
    def do_command(command)
      sleep rand # network delay
      case command
      when /\Au(?:pdate)?\s(.*)/
        puts 'updated => "' << $1 << '"'
        @tweets << remove_user_name_from($1)
      when /\Al(?:ist)?(?:\s(.*))?/
        show_list $1
      when /\Ae(?:xit)?\z/
        puts 'finalizing...'
        exit
      else
        warn 'Invalid command.'
      end
    end

    def remove_user_name_from(update)
      update.gsub(/@\w.*\s/, '')
    end

    def name_gen
      (('a'..'z').to_a + ('A'..'Z').to_a).shuffle[0..(2 + rand(8))].join
    end

    def show_list(name = nil)
      list       = list_to_show(name)
      max_length = max_length_in(list)

      list.each do |name, tweet|
        reply = (rand(10) == 0) ? "@#{user} " : ''
        name  = name.rjust(max_length)

        puts "#{name}: #{reply}#{tweet}"
      end
    end

    def list_to_show(name)
      @tweets.shuffle[0..10].map do |tweet|
        [name || name_gen, tweet]
      end
    end

    def max_length_in(list)
      list.map(&:first).map(&:length).max
    end
  end
end

def error(message)
  warn message
  exit -1
end

if $0 == __FILE__

  # Initialize
  name, pass = ARGV
  name = name || $settings[:name]
  pass = pass || $settings[:pass]

  if [name, pass].any? {|e| e.empty? }
    error 'Need to set Name and Password'
  end

  # Create fake client
  Faketter.set(name, pass)

  # Authorize
  begin
    client = Faketter.login!
  rescue AccessDenied
    error 'Invalid Name or Password'
  end

  # Run!
  client.run
end

