
require 'optparse'
require "#{ENV['ZSYS_ROOT']}/buildsys/tools/cmock/lib/cmock"

output_path_desc = "Path where to put the mocked files. Default=[CWD]"
prefix_desc = "Prefix to use for generated files, default=mock_<INPUT_HEADER>[.h|.c]"

usage_banner = "Usage: create_mock.rb -i INPUT_HEADER [options]\n
  options:\n
  -o OUTPUT_PATH  #{output_path_desc}\n
  -p PREFIX       #{prefix_desc}\n
  \n"

# Parse the options given to create_mock.rb
options = {}
OptionParser.new do |opts|
  opts.banner = usage_banner 
  opts.on("-i", "--input HEADER", "Header file to mock") do |v|
    options[:input] = v
  end
  opts.on("-o", "--output PATH", output_path_desc) do |v|
    options[:output] = v
  end
  opts.on("-p", "--prefix PREFIX", prefix_desc) do |v|
    options[:prefix] = v
  end
end.parse!

begin
  header_to_mock = options.fetch(:input)
rescue
  raise "ERROR! No header file supplied:\n#{usage_banner}"
end

mock_out = options.fetch(:output, "./")
mock_prefix = options.fetch(:prefix, "mock_")
cmock = CMock.new({:plugins => [:ignore, :return_thru_ptr], :mock_prefix => mock_prefix, :mock_path => mock_out})
cmock.setup_mocks(header_to_mock)



