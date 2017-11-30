require 'aws-sdk-ec2'

unless Capistrano::Configuration.respond_to?(:instance)
  abort "capistrano/ec2group requires Capistrano 2"
end

class EC2Groups
  class << self
    def instances_running_in_group(group_name, region, aws_access_key_id = nil, aws_secret_access_key = nil, private_dns = false)
      creds = if aws_access_key_id && aws_secret_access_key
                ::Aws::Credentials.new(aws_access_key_id, aws_secret_access_key)
              else
                ::Aws::InstanceProfileCredentials.new
              end

      client = ::Aws::EC2::Client.new(credentials: creds, region: region)

      result = client.describe_instances(filters: [{name: 'instance-state-name', values: ['running']}]).reservations.flat_map do |reservation|
        reservation.instances.map do |instance|
          if instance.security_groups.any? {|group| group.group_name == group_name.to_s}
            private_dns ? instance.private_dns_name : instance.public_dns_name
          end
        end
      end
      result.compact
    end
  end
end

module Capistrano
  class Configuration
    module Groups
      # Associate a group of EC2 instances with a role. In order to use this, you
      # must use the security groups feature in Amazon EC2 to group your servers
      # by role.
      #
      # First, specify the security group name, then the roles and params:
      #
      #   group :webserver, :web
      #   group :app_myappname, :app
      #   group "MySQL Servers", :db, :port => 22000
      def group(which, *args)
        instances = EC2Groups.instances_running_in_group(which, fetch(:aws_region), fetch(:aws_access_key_id), fetch(:aws_secret_access_key), fetch(:aws_pvt_dns))
        instances.each {|instance|server(instance, *args)}
      end
    end

    include Groups
  end
end
