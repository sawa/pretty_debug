#!ruby

gemspec "pretty_debug.gemspec"
manage "lib/pretty_debug.rb"

spec nil,
	"The MIT License (MIT)",
	"Copyright (c) 2013-2016 sawa",
	"Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:",
	"The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.",
	"THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.",
coda

class File
	spec ".expand_path_relative",
	coda
end

class Dir
	spec ".glob_relative",
	coda
end

module Kernel
	spec "#caller_location",
	coda
	spec "#load_relative",
	coda
end

class BasicObject
	hide spec "#intercept",
		expr("BasicObject.new").UT.succeed?,
	coda
end

class Object
	spec "#intercept",
		expr("%w[a b c].map(&:capitalize)").UT.succeed?,
	coda
	spec "#which",
		"a = Object.new".setup,
		expr("a").UT(:to_s) == expr("a"),
		expr("a").UT(:unknown_method) == expr("a"),
	coda
end

module Kernel
	spec "#class_check",
	coda
end

class Exception
	spec "#backtrace_locations",
	coda
	spec "#backtrace_locations=",
	coda
	hide spec "#complement_backtrace_locations",
	coda
	spec "#raise",
	coda
	spec ".raise",
	coda
end

class Thread::Backtrace::PseudoLocation
	hide spec "::Pattern",
	coda
	spec "#to_s",
	coda
	spec "#to_s=",
	coda
	spec "#absolute_path",
	coda
	spec "#absolute_path=",
	coda
	spec "#lineno",
	coda
	spec "#lineno=",
	coda
	spec "#label",
	coda
	spec "#label=",
	coda
	spec "#path",
	coda
	spec "#path=",
	coda
	spec "#base_label",
	coda
	spec "#base_label=",
	coda
	hide spec "#initialize",
	coda
	spec "#dirname",
	coda
	spec "#basename",
	coda
	spec "#realpath",
	coda
	spec "#realdirname",
	coda
	spec "#realbasename",
	coda
end

class Thread::Backtrace::Location
	spec "#to_s",
	coda
	spec "#dirname",
	coda
	spec "#basename",
	coda
	spec "#realpath",
	coda
	spec "#realdirname",
	coda
	spec "#realbasename",
	coda
end

module Kernel
	spec "#suppress_warning",
		"Suppresses warning message (`\"already initialized constants\"`, etc.).",
	coda
end

class PrettyDebug
	spec ".reject",
	coda
	spec ".select",
	coda
	spec ".format",
	coda
	spec ".message",
		"Format error messages",
		"* Capitalize the sentence",
		"* Ensures period at the end",
		"* Changes TeX-style \\`...\\' code citation to Markdown-style \\`...\\`.",
	coda
	spec ".backtrace_locations",
	coda
	spec ".caller_locations",
	coda
	spec "::Hook",
	coda
	spec ".beautify",
	coda
end

class PrettyArray
	spec "#initialize",
	coda
	spec "#to_puts",
	coda
	spec "#inspect",
	coda
end

class Proc
	spec "#inspect",
		Proc.new{}.UT =~ /Proc@.+:\d+/,
	coda
end

class Method
	spec "#inspect",
		expr("\"foo\".method(:to_s)").UT == "\"foo\".to_s",
	coda
end

class UnboundMethod
	spec "#inspect",
		expr("String.instance_method(:to_s)").UT == "String#to_s",
	coda
end

class BasicObject
	spec "#recursive?",
	coda
	spec "#inspect",
	coda
end

module Enumerable
	spec "#recursive?",
	coda
end

class Range
	spec "#recursive?",
	coda
end

class Array
	spec "::SingleLength",
	coda
	spec "#inspect",
	coda
	spec "#align",
		<<~'RUBY'.setup,
			a = [
				%w[f foo b],
				%w[fo f bar],
				%w[a fooooooooooooo b],
			]
		RUBY
		expr("a").UT ==
		[
			["f ", "foo           ", "b  "],
			["fo", "f             ", "bar"],
			["a ", "fooooooooooooo", "b  "]
		],
	coda
	spec "#common_prefix",
		%w[foobarabcdef foobarghijkl].UT == "foobar",
		%w[abcdeffoobar ghijklfoobar].UT == "",
	coda
	spec "#common_affix",
		%w[abcdeffoobar ghijklfoobar].UT == "foobar",
		%w[foobarabcdef foobarghijkl].UT == "",
	coda
end

class Hash
	spec "::SingleLength",
	coda
	spec "::KeyLengthMax",
	coda
	spec "#inspect",
		"!When `self == empty?`, `...max` becomes `nil`. `to_i` turns it to `0`.",
	coda
end

class BasicObject
	spec "#expand",
	coda
end

class String
	spec "#de_vt100",
	coda
	hide spec "#vt100",
	coda
	spec "#verbatim",
	coda
	spec "#terminal_escape",
	coda
	spec "#bf",
		<<~'RUBY'.setup,
			puts "normal", "bold".bf, "normal"
		RUBY
		"foo".UT == "\e[01mfoo\e[m",
	coda
	spec "#underline",
		<<~'RUBY'.setup,
			puts "underline".underline
		RUBY
		"foo".UT == "\e[04mfoo\e[m",
	coda
	spec "#color",
		<<~'RUBY'.setup,
			puts "red".color(:red)
			puts "green".color(:green)
			puts "blue".color(:blue)
		RUBY
		"foo".UT(:red) == "\e[31mfoo\e[m",
	coda
	spec "#bg",
		<<~'RUBY'.setup,
			puts "cyan".bg(:cyan)
			puts "magenta".bg(:magenta)
			puts "yellow".bg(:yellow)
		RUBY
		"foo".UT(:magenta) == "\e[45mfoo\e[m",
	coda
	spec "#indent",
		<<~'RUBY'.setup,
			puts "unindented", "indented".indent, "unindented"
		RUBY
		'ind = String.class_variable_get(:@@indent)'.setup,
		"foo\nbar".UT == expr('"#{ind}foo\n#{ind}bar"'),
		"foo\nbar".UT(4) == expr('"#{ind * 4}foo\n#{ind * 4}bar"'),
	coda
	spec "#unchomp",
		{return: String, raise: StandardError},
		"Ensures that the receiver ends with a single chomp modifier.",
		"? Trivial case",
		"abc\n".UT == "abc\n",
		RECEIVER == "abc\n",
		"? Non-trivial case",
		"abc".UT == "abc\n",
		RECEIVER == "abc",
	coda
	spec "#unchomp!",
		"Destructive counterpart to `unchomp`.",
		"? Trivial case",
		"abc\n".UT == "abc\n",
		RECEIVER == "abc\n",
		"? Non-trivial case",
		"abc".UT == "abc\n",
		RECEIVER == "abc\n",
	coda
	spec "#ellipsis",
		<<~'RUBY'.setup,
			s = "Hello World!" * 30
		RUBY
		expr("s").UT(10) == "Hel...rld!",
		expr("s").UT(400) == expr("s"),
	coda
end
