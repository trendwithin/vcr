require 'vcr/structs'

module VCRHelpers
  YAML_REGEX_FOR_1_9_1 = Regexp.union(*[
    '  request',
    '    method',
    '    uri',
    '    body',
    '    headers',
    '  response',
    '    status',
    '      code',
    '      message',
    '    body',
    '    http_version'
  ].uniq)

  def normalize_cassette_structs(content)
    if RUBY_VERSION == '1.9.1'
      # Ruby 1.9.1 serializes YAML a bit different, so
      # we deal with that difference and add leading colons here.
      content = content.gsub(YAML_REGEX_FOR_1_9_1) do |match|
        match.sub(/^ +/, '\0:')
      end
    end

    structs = YAML.load(content)

    # Remove non-deterministic headers
    structs.each do |s|
      s.response.headers.reject! { |k, v| %w[ server date ].include?(k) }
    end

    structs
  end
end
World(VCRHelpers)

Given /the following files do not exist:/ do |files|
  check_file_presence(files.raw.map{|file_row| file_row[0]}, false)
end

Given /^the directory "([^"]*)" does not exist$/ do |dir|
  check_directory_presence([dir], false)
end

Then /^the file "([^"]*)" should exist$/ do |file_name|
  check_file_presence([file_name], true)
end

Then /^it should (pass|fail) with "([^"]*)"$/ do |pass_fail, partial_output|
  assert_exit_status_and_partial_output(pass_fail == 'pass', partial_output)
end

Then /^the output should contain each of the following:$/ do |table|
  table.raw.flatten.each do |string|
    assert_partial_output(string)
  end
end

Then /^the file "([^"]*)" should contain YAML like:$/ do |file_name, expected_content|
  actual_content = in_current_dir { File.read(file_name) }
  normalize_cassette_structs(actual_content).should == normalize_cassette_structs(expected_content)
end

