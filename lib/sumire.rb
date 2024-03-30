# frozen_string_literal: true

require_relative "sumire/version"
require "ansi2txt"

module Sumire
  class Error < StandardError; end

  class Sumire # rubocop:disable Style/Documentation
    class << self
      attr_accessor :directory
    end

    # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity, Lint/MissingCopEnableDirective
    def self.exec(**kwargs)
      directory = kwargs[:directory]
      directory = "." if directory.nil?
      target = kwargs[:target]
      target = "typescript" if target.nil?
      verbose = kwargs[:verbose] || false
      old_lines = 0
      list = []
      old_text = ""
      start_time = Time.now.strftime("%Y%m%d_%H%M%S")

      # rubocop:disable Metrics/BlockLength
      listener = Listen.to(".") do |modified, _added, _removed|
        if modified.map { |file| File.basename(file) }.include?(target)
          input = File.open(target)

          # txt: string
          txt = Ansi2txt::ANSI2TXT.from_io(input)

          # Add target text
          add_line_txt = txt[old_text.size...-1]

          regex = /Script\sdone\son\s\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}\+\d{2}:\d{2}\s\[COMMAND_EXIT_CODE="\d+"\]/
          exit if !add_line_txt.nil? && add_line_txt.match(regex)
          next if add_line_txt.nil?

          add_line = add_line_txt.gsub("\n\r", "\n").lines.map(&:chomp).map do |line|
            time = Time.now.strftime("%Y-%m-%d %H:%M:%S")
            "[#{time}] #{line}"
          end
          add_line_color = add_line_txt.gsub("\n\r", "\n").lines.map(&:chomp).map do |line|
            time = Time.now.strftime("%Y-%m-%d %H:%M:%S")
            "\e[32m[#{time}]\e[0m #{line}"
          end

          input.seek(0)
          new_lines = input.read.lines.count

          # Add new line
          if old_lines < new_lines
            add_line.each do |line|
              list.append(line)
              File.open("#{directory}/#{start_time}.log", "a") do |f|
                f.puts(line)
              end
            end

            if verbose
              add_line_color.each do |line|
                puts(line)
              end
            end

            old_text = txt
          end

          old_lines = new_lines
        end
      end
      listener.start

      begin
        sleep
      rescue Interrupt
        nil
      rescue NoMethodError
        nil
      end
    end
  end
end
