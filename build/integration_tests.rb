#  Phusion Passenger - https://www.phusionpassenger.com/
#  Copyright (c) 2010-2013 Phusion
#
#  "Phusion Passenger" is a trademark of Hongli Lai & Ninh Bui.
#
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in
#  all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#  THE SOFTWARE.

### Integration tests ###

desc "Run all integration tests"
task 'test:integration' => ['test:integration:apache2', 'test:integration:nginx'] do
end

dependencies = [:_apache2, NATIVE_SUPPORT_TARGET].compact
desc "Run Apache 2 integration tests"
task 'test:integration:apache2' => dependencies do
	if PlatformInfo.rspec.nil?
		abort "RSpec is not installed for Ruby interpreter '#{PlatformInfo.ruby_command}'. Please install it."
	else
		command = "#{PlatformInfo.rspec} -c -f s integration_tests/apache2_tests.rb"
		if boolean_option('SUDO')
			command = "#{PlatformInfo.ruby_sudo_command} -E #{command}"
		end
		if grep = string_option('E')
			require 'shellwords'
			command << " -e #{Shellwords.escape(grep)}"
		end
		sh "cd test && exec #{command}"
	end
end

dependencies = [:_nginx, NATIVE_SUPPORT_TARGET].compact
desc "Run Nginx integration tests"
task 'test:integration:nginx' => dependencies do
	if PlatformInfo.rspec.nil?
		abort "RSpec is not installed for Ruby interpreter '#{PlatformInfo.ruby_command}'. Please install it."
	else
		command = "#{PlatformInfo.rspec} -c -f s integration_tests/nginx_tests.rb"
		if boolean_option('SUDO')
			command = "#{PlatformInfo.ruby_sudo_command} -E #{command}"
		end
		if grep = string_option('E')
			require 'shellwords'
			command << " -e #{Shellwords.escape(grep)}"
		end
		repeat = true
		while repeat
			sh "cd test && exec #{command}"
			repeat = boolean_option('REPEAT')
		end
	end
end

dependencies = [:_nginx, NATIVE_SUPPORT_TARGET].compact
desc "Run Passenger Standalone integration tests"
task 'test:integration:standalone' => dependencies do
	if PlatformInfo.rspec.nil?
		abort "RSpec is not installed for Ruby interpreter '#{PlatformInfo.ruby_command}'. Please install it."
	else
		command = "#{PlatformInfo.rspec} -c -f s integration_tests/standalone_tests.rb"
		if grep = string_option('E')
			require 'shellwords'
			command << " -e #{Shellwords.escape(grep)}"
		end
		sh "cd test && exec #{command}"
	end
end

desc "Run native packaging tests"
task 'test:integration:native_packaging' do
	if PlatformInfo.rspec.nil?
		abort "RSpec is not installed for Ruby interpreter '#{PlatformInfo.ruby_command}'. Please install it."
	end
	command = "rspec -c -f s integration_tests/native_packaging_spec.rb"
	if boolean_option('SUDO')
		command = "#{PlatformInfo.ruby_sudo_command} -E #{command}"
	end
	if grep = string_option('E')
		require 'shellwords'
		command << " -e #{Shellwords.escape(grep)}"
	end
	case PlatformInfo.os_name
	when "linux"
		if PlatformInfo.linux_distro_tags.include?(:debian)
			command = "env NATIVE_PACKAGING_METHOD=deb " +
				"LOCATIONS_INI=/usr/lib/ruby/vendor_ruby/phusion_passenger/locations.ini " +
				command
		elsif PlatformInfo.linux_distro_tags.include?(:redhat)
			command = "env NATIVE_PACKAGING_METHOD=rpm " +
				"LOCATIONS_INI=/usr/lib/ruby/site_ruby/1.8/phusion_passenger/locations.ini " +
				command
		else
			abort "Unsupported Linux distribution"
		end
	when "macosx"
		# The tests put /usr/bin and /usr/sbin first in PATH, causing /usr/bin/ruby to be used.
		# We should run the tests in /usr/bin/ruby too, so that native_support is compiled for
		# the same Ruby.
		prefix = "env NATIVE_PACKAGING_METHOD=homebrew " +
			"LOCATIONS_INI=/usr/local/Cellar/passenger/#{VERSION_STRING}/libexec/lib/phusion_passenger/locations.ini"
		if PlatformInfo.in_rvm?
			prefix << " rvm-exec system /usr/bin/ruby -S"
		end
		command = "#{prefix} #{command}"
	else
		abort "Unsupported operating system"
	end
	sh "cd test && exec #{command}"
end

dependencies = [:_apache2, NATIVE_SUPPORT_TARGET].compact
desc "Run the 'apache2' integration test infinitely, and abort if/when it fails"
task 'test:restart' => dependencies do
	require 'shellwords'
	color_code_start = "\e[33m\e[44m\e[1m"
	color_code_end = "\e[0m"
	i = 1
	while true do
		puts "#{color_code_start}Test run #{i} (press Ctrl-C multiple times to abort)#{color_code_end}"
		command = "rspec -c -f s integration_tests/apache2_tests.rb"
		if grep = string_option('E')
			command << " -e #{Shellwords.escape(grep)}"
		end
		sh "cd test && exec #{command}"
		i += 1
	end
end
