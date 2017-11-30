require 'test/unit'
require 'yaml'
require 'rubygems/specification'
require 'capistrano'
require 'capistrano/ec2group'

class CapistranoTest < Test::Unit::TestCase
  def test_build_gem
    data = File.read(File.join(File.dirname(__FILE__), '..', 'capistrano-ec2group.gemspec'))
    spec = nil

    if data !~ %r{!ruby/object:Gem::Specification}
      Thread.new { spec = eval("$SAFE = 1\n#{data}") }.join
    else
      spec = YAML.load(data)
    end

    assert spec.validate
  end

  def test_instances_running_in_group
    wp2 = EC2Groups.instances_running_in_group('production-adminv', 'us-east-1', ENV['AWS_ACCESS_KEY'], ENV['AWS_SECRET_KEY'])
    puts wp2.to_json
    assert wp2.count == 1

    api = EC2Groups.instances_running_in_group('production-apiv', 'us-east-1', ENV['AWS_ACCESS_KEY'], ENV['AWS_SECRET_KEY'])
    puts api.to_json
    assert api.count == 2
  end
end
