#!ruby
#frozen-string-literal: true

# File

class File
	def self.expand_path_relative f; expand_path(f, caller_location.realdirname) end
end

class Dir
	def self.glob_relative f; glob(File.expand_path(f, caller_location.realdirname)) end
end

module Kernel
	def caller_location i = 1; caller_locations(i + 1, 1).first end
	def load_relative f, *rest; load(File.expand_path(f, caller_location.realdirname), *rest) end
end

# Debug

class BasicObject
	def intercept; self ensure
		::Kernel.puts "[Debug] ?:?".bf.color(:yellow), "#<Basic Object>"
	end
end

class Object
	def intercept; self ensure
		l = caller_location
		puts \
			"[Debug] #{"#{l.realpath}:#{l.lineno}"}".bf.color(:yellow),
			inspect.verbatim
	end
	def which m; self ensure
		l = caller_location
		m = :method_missing unless self.class.method_defined?(m)
		mt = method(m)
		puts \
			"[Debug] #{"#{l.realpath}:#{l.lineno}"}".bf.color(:yellow),
			"#{self.class}(#{mt.owner})\##{m}@#{mt.source_location.to_a.join(":")}"
	end
end

module Kernel
	def class_check *klass, v
		case v
		when *klass
		else
			ArgumentError.raise(
				"#{yield + " " if block_given?}should be #{klass.map(&:expand).join(", ")} instance "\
				"but is #{v.expand}")
		end
	end
end

class Exception
	attr_accessor :backtrace_locations
	def complement_backtrace_locations
		@backtrace_locations ||=
		(backtrace || caller).map{|l| Thread::Backtrace::PseudoLocation.new(l)}
	end
	def raise; Kernel.__send__(:raise, self) end
	def self.raise *args; Kernel.__send__(:raise, new(*args)) end
end

class Thread::Backtrace::PseudoLocation
	Pattern = /\A(?'f'[^:]+)(?::(?'l'\d+))?(?::in `(?'m'.+)'|(?'m'.+))?\z/m
	attr_accessor :to_s, :absolute_path, :lineno, :label, :path, :base_label
	def initialize to_s
		@to_s = to_s
		m = @to_s.match(Pattern)
		@absolute_path, @lineno, @label = m[:f], m[:l] ? m[:l].to_i : nil, m[:m].to_s
		@path = File.basename(@absolute_path)
		@base_label = @label
	end
	def dirname; File.dirname(absolute_path) end
	def basename; File.basename(absolute_path) end
	def realpath
		case absolute_path
		when "-e", "(eval)" then absolute_path
		else File.realpath(absolute_path) 
		end
	end
	def realdirname; File.dirname(realpath) end
	def realbasename; File.basename(realpath) end
end

class Thread::Backtrace::Location
	def to_s; "#{realpath}:#{lineno}" end
	def dirname; File.dirname(absolute_path) end
	def basename; File.basename(absolute_path) end
	def realpath
		case absolute_path
		when "-e", "(eval)" then absolute_path
		else File.realpath(absolute_path) 
		end
	end
	def realdirname; File.dirname(realpath) end
	def realbasename; File.basename(realpath) end
end

module Kernel
	def suppress_warning
		original_verbose, $VERBOSE = $VERBOSE, nil
		result = yield
		$VERBOSE =  original_verbose
		result
	end
	at_exit do
		#!Gotcha: Terminated iterations (such as in `Sass::SyntaxError.backtrace`) overwrite `$!`.
		e = $!
		case e
		when nil, SystemExit, Interrupt
		else
			puts \
			PrettyDebug.message(e).bf.color(:red),
			PrettyDebug.backtrace_locations(e).to_puts
		end
		$stderr.reopen(IO::NULL)
		$stdout.reopen(IO::NULL)
	end
end

class PrettyDebug
	def self.reject &pr
		@reject = pr
		@select = ->f, m{true}
	end
	def self.select &pr
		@select = pr
		@reject = ->f, m{false}
	end
	def self.format &pr; @format = pr end
	def self.message e
		e.complement_backtrace_locations
		e.message.to_s.sub(/./, &:upcase).sub(/(?<=[^.])\z/, ".").tr("'", "`")
	end
	def self.backtrace_locations e
		e.complement_backtrace_locations
		PrettyArray.new(beautify(e.backtrace_locations))
	end
	def self.caller_locations
		PrettyArray.new(beautify(Kernel.caller_locations))
	end
	Hook = %w[
		at_exit
		set_trace_func
		initialize
		coerce
		method_missing
		singleton_method_added
		singleton_method_removed
		singleton_method_undefined
		respond_to_missing?
		extended
		included
		method_added
		method_removed
		method_undefined
		const_missing
		inherited
		intitialize_copy
		intitialize_clone
		intitialize_dup
		prepend
		append_features
		extend_features
		prepend_features
	]
	def self.beautify a
		a
		.map{|l| [l.realpath, l.lineno, l.label]}
		.transpose.tap do
			|_, _, ms|
			ms.map! do
				|m|
				case m
				when *Hook then "(#{m})"
				when /\A(rescue in )?block( .*)? in / then "(entered block)"
				when /\Arescue in / then ""
				else m
				end
			end
			ms[-1] = ""; ms.rotate!(-1)
		end.transpose
	end
end

PrettyDebug.select{|f, m| true}
PrettyDebug.format{|row| "#{row.join(" | ")} ".bg(:white).color(:black)}

# Inspection

class PrettyArray < Array
	def initialize a
		super(a)
		reject!{
			|f, l, m|
			f == __FILE__ or
			m =~ /\A<.*>\z/ #Purpose# Such as `<top (required)>`, `<module:Foo>`.
		}
		reject, select =
		[:@reject, :@select].map{|sym| PrettyDebug.instance_variable_get(sym)}
		reject!{|f, l, m| reject.call(f, m)} rescue nil
		select!{|f, l, m| select.call(f, m)} rescue nil
	end
	def to_puts; align.map(&PrettyDebug.instance_variable_get(:@format)) end
	def inspect; to_puts.join($/) end
end

class Proc
	def inspect; f, l = source_location; "Proc@#{f}:#{l}"
	rescue; "Proc@source_unknown"
	end
end

class Method; def inspect; "#{receiver.inspect}.#{name}" end end

class UnboundMethod; def inspect; "#{owner}\##{name}" end end

class BasicObject
	def recursive? *; false end
	def inspect; "" end
end

module Enumerable
	def recursive? known = {}
		return true if known.include?(self)
		known[self] = true
		begin
			any?{|*args| args.any?{|item| item.recursive?(known)}}
		ensure
			known[self] = false
		end
	end
end

class Range
	def recursive? *; false end
end

class Array
	module PrettyInspect
		SingleLength = 50
		def inspect
			return super if recursive?
			s = map(&:inspect)
			length < 2 || s.map(&:length).inject(:+) < SingleLength ?
				"[#{s.join(", ")}]" : "[#$/#{s.join(",#$/").indent}#$/]"
		end
	end
	prepend PrettyInspect
end

class Hash
	module PrettyInspect
		SingleLength = 50
		KeyLengthMax = 30
		def inspect
			return super if recursive?
			keys = keys().map(&:inspect)
			#!Purpose: When `self == empty?`, `...max` becomes `nil`. `to_i` turns it to `0`.
			w = keys.map(&:length).max.to_i
			w = w > KeyLengthMax ? KeyLengthMax : w
			s = [keys, values].transpose.map{|k, v| "#{k.ljust(w)} => #{v.inspect}"}
			length < 2 || s.map(&:length).inject(:+) < SingleLength ?
				"{#{s.join(", ")}}" :  "{#$/#{s.join(",#$/").indent}#$/}"
		end
	end
	prepend PrettyInspect
end

# Terminal

class BasicObject
	def expand; inspect.verbatim end
end

class String
	def verbatim; bg(:blue) end
	def terminal_escape; "\"#{self}\"" end
	def bf; "#{vt100("01")}#{self}#{vt100}" end
	def underline; "#{vt100("04")}#{self}#{vt100}" end
	def color sym; "#{vt100(30+
		{black: 0, red: 1, green: 2, yellow: 3, blue: 4, magenta: 5, cyan: 6, white: 7}[sym.to_sym]
		)}#{self}#{vt100}" end
	def bg sym; "#{vt100(40+
		{black: 0, red: 1, green: 2, yellow: 3, blue: 4, magenta: 5, cyan: 6, white: 7}[sym.to_sym]
		)}#{self}#{vt100}" end
	def de_vt100; gsub(/\e\[\d*m/, "") end
	private def vt100 s = ""; "\e[#{s}m" end
end

# String Formatting

class Array
	def align ellipsis_limit = nil
		transpose.map do
			|col|
			just = case col.first; when Numeric then :rjust; else :ljust end
			width = col.map{|cell| cell.to_s.length}.max
			max = ellipsis_limit || width
			col.map{|cell| cell.to_s.ellipsis(max).__send__(just, width > max ? max : width)}
		end.transpose
	end
	def common_prefix
		each{|e| class_check(String, e){"All elements must be a String"}}
		first, *others = self
		i = 0
		i += 1 while first[i] and others.all?{|s| first[i] == s[i]}
		first[0, i]
#! This is more elegant, but cannot be generalized to `common_affix`.
#		first[0, (0...first.length).find{|i| first[i].! or others.any?{|s| first[i] != s[i]}}.to_i]
	end
	def common_affix
		each{|e| class_check(String, e){"All elements must be a String"}}
		first, *others = self
		i = - 1
		i -= 1 while first[i] and others.all?{|s| first[i] == s[i]}
		first[i + 1, -(i + 1)]
	end
end

class String
	@@indent = "  "
	def indent n = 1; gsub(/^/, @@indent * n) end
	def unchomp; sub(/#$/?\z/, $/) end
	def unchomp!; sub!(/#$/?\z/, $/) end
	def ellipsis n
		if length <= n then self
		elsif n.odd? then "#{slice(0..n/2-3)}...#{slice(-n/2+2..-1)}"
		else "#{slice(0..n/2-3)}...#{slice(-n/2+1..-1)}"
		end
	end
end
