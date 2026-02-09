# frozen_string_literal: true

# Syntax-highlighting exercise: mix of modules/classes, refinements, regex, heredoc, blocks,
# pattern matching, ranges, splats, symbols, keywords, and special global variables.

def foo a, **b
  ...
end

class クラス名
  def self.メソッド名(引数)
  end
end

module Demo
  VERSION = "1.2.3"
  DEFAULTS = {
    mode: :fast,
    limit: 10,
    flags: %i[a b c],
    threshold: 0.75,
  }.freeze

  class ParseError < StandardError; end

  module Utils
    module_function

    # Simple ANSI colorizer (kept small but varied)
    def color(text, code = 32)
      "\e[#{code}m#{text}\e[0m"
    end

    def indent(str, n = 2)
      pad = " " * n
      str.lines.map { |ln| pad + ln }.join
    end
  end

  class Tokenizer
    attr_reader :source

    # Required: regex literal included here
    TOKEN_RE = /
      (?<space>\s+) |
      (?<number>\d+(?:\.\d+)?) |
      (?<ident>[A-Za-z_]\w*) |
      (?<string>
        "(?:\\.|[^"])*" |
        '(?:\\.|[^'])*'
      ) |
      (?<op>==|!=|<=|>=|=>|[+\-*\/%=<>&|!?:.,()[\]{}])
    /x.freeze

    def initialize(source)
      @source = source
    end

    def tokens
      enum_for(:each_token).to_a
    end

    def each_token
      i = 0
      while i < source.length
        m = TOKEN_RE.match(source, i) or raise ParseError, "tokenize failed at #{i}"
        i = m.end(0)

        kind = m.named_captures.find { |_k, v| v }&.first
        next if kind == "space"
        yield [kind.to_sym, m[0]]
      end
    end
  end

  class Analyzer
    def initialize(text)
      @text = text
    end

    def scan
      t = Tokenizer.new(@text)
      counts = Hash.new(0)
      t.each_token { |(k, _)| counts[k] += 1 }

      {
        counts: counts,
        sample: t.tokens.first(12),
      }
    end

    def grep_words(words)
      # required: regex literal (second instance) with interpolation and options
      rx = /\b(?:#{words.map { |w| Regexp.escape(w) }.join("|")})\b/i
      @text.scan(rx).uniq.sort
    end
  end

  module Formatter
    module_function

    def format_report(result)
      counts = result[:counts].sort_by { |k, _| k.to_s }
      sample = result[:sample]

      lines = []
      lines << "Counts:"
      counts.each do |k, v|
        lines << "  - #{k}: #{v}"
      end
      lines << "Sample:"
      sample.each_with_index do |(k, tok), idx|
        lines << "  %02d. %-7s %p" % [idx + 1, k, tok]
      end
      lines.join("\n")
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  include Demo

  text = <<~'RUBY'
    # A tiny embedded Ruby snippet:
    name = "Ruby"
    puts "Hello, #{name}!"
    3.times { |i| puts i ** 2 }
    /a+(b|c)?/ =~ "aaab"
  RUBY

  analyzer = Demo::Analyzer.new(text)
  report = analyzer.scan
  puts Demo::Utils.color(Demo::Formatter.format_report(report), 36)

  words = %w[ruby puts times]
  found = analyzer.grep_words(words)
  puts Demo::Utils.color("Found words: #{found.inspect}", 33)

  # --- Required special global variables usage: $' and $" ---
  # Force a match to populate match-related globals:
  /(\w+),\s*(\w+)!/ =~ "Hello, Ruby!"
  after_match = $'   # post-match string (string after the last successful match)
  loaded = $"        # array of loaded feature paths (require'd files)

  puts Demo::Utils.color("Post-match ($'): #{after_match.inspect}", 35)
  puts Demo::Utils.color(%Q(Loaded features ($") sample: #{loaded.first(3).inspect}), 35)

  # Pattern matching (Ruby 2.7+), case/in, pin operator
  payload = { kind: :event, data: { id: 42, tags: %w[a b c] } }
  case payload
  in { kind: :event, data: { id: Integer => id, tags: [String, *rest] } }
    puts Demo::Utils.color("Matched event id=#{id}, rest=#{rest.inspect}", 32)
  else
    puts Demo::Utils.color("No match", 31)
  end

  # Refinement for extra syntax variety
  module StringExtras
    refine String do
      def squish
        gsub(/\s+/, " ").strip
      end
    end
  end

  using StringExtras
  messy = "  a\t b \n  c  "
  puts Demo::Utils.color("Squished: #{messy.squish.inspect}", 34)
end