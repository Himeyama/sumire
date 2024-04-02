# frozen_string_literal: true

require_relative "sumire/version"
require "ansi2txt"
require "fileutils"

module Sumire
  class Error < StandardError; end

  class Sumire # rubocop:disable Style/Documentation
    def self.remove_cr(text) # rubocop:disable Metrics/MethodLength
      chars = text.bytes
      remove_cr_chars = [0] * chars.length
      idx = 0
      chars.map do |chr|
        if chr.eql?(8)
          idx -= 1
          next
        end

        if chr.eql?(13)
          idx = 0
          next
        end
        remove_cr_chars[idx] = chr
        idx += 1
      end
      remove_cr_chars.filter { |e| e != 0 }.pack("C*")
    end

    def self.remove_crs(text, mode: false) # rubocop:disable Metrics/MethodLength
      if mode
        begin
          text.encode!("UTF-16", "UTF-8", invalid: :replace, replace: "")
          text = text.encode!("UTF-8", "UTF-16")
          text = text.gsub(/\r+/, "\r").gsub(/\r+\n\r+/, "\n").gsub("\r", "\n") if mode
        rescue StandardError
          nil
        end
        return text
      end

      text.split("\n").map { |e| remove_cr(e) }.join("\n")
    end

    # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity, Lint/MissingCopEnableDirective
    def self.exec(**kwargs)
      legacy = kwargs[:legacy] || false
      destination = kwargs[:destination]
      if destination.nil?
        uuid = SecureRandom.uuid
        FileUtils.mkdir_p("/tmp/sumire/#{uuid}")
        destination = "/tmp/sumire/#{uuid}/typescript"
      end
      target = kwargs[:target]
      target = "typescript" if target.nil?
      verbose = kwargs[:verbose] || false
      old_lines = 0
      list = []
      old_text = ""

      listen_dir = File.dirname(target)

      # rubocop:disable Metrics/BlockLength
      listener = Listen.to(listen_dir) do |modified, _added, _removed|
        if modified.include?(target)
          input = File.open(target)

          # txt: string
          txt = Ansi2txt::ANSI2TXT.from_io(input)

          # Add target text
          add_line_txt = txt[old_text.size...-1]
          add_line_txt = remove_crs(add_line_txt, mode: legacy)

          regex = /Script\sdone\son\s\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2}\+\d{2}:\d{2}\s\[COMMAND_EXIT_CODE="\d+"\]/
          begin
            match = add_line_txt.encode("utf-8", "utf-8").match(regex)
            exit if !add_line_txt.nil? && match
          rescue ArgumentError
            nil
          end
          next if add_line_txt.nil?

          add_line = add_line_txt.lines.map(&:chomp).map do |line|
            time = Time.now.strftime("%Y-%m-%d %H:%M:%S")
            "[#{time}] #{line}"
          end
          add_line_color = add_line_txt.lines.map(&:chomp).map do |line|
            time = Time.now.strftime("%Y-%m-%d %H:%M:%S")
            "\e[32m[#{time}]\e[0m #{line}"
          end

          input.seek(0)
          new_lines = input.read.lines.count

          # Add new line
          if old_lines < new_lines
            add_line.each do |line|
              list.append(line)
              File.open(destination, "a") do |f|
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
