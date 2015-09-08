# Install the AWS SDK
chef_gem "aws-sdk" do
  compile_time false
  action :install
end

# Create the directory to download too
directory "/files/default" do
  recursive true
  rights :full_control, 'Administrator', :applies_to_children => true
  action :create
end

# Download the update to the working location
ruby_block "download-object" do
  block do
    require 'aws-sdk'

    #1
    Aws.config[:ssl_ca_bundle] = 'C:/ProgramData/Git/bin/curl-ca-bundle.crt'

    #2
    query = Chef::Search::Query.new
    app = query.search(:aws_opsworks_app, "type:other").first
    s3region = app[0][:environment][:S3REGION]
    s3bucket = app[0][:environment][:BUCKET]
    s3filename = app[0][:environment][:FILENAME]

    #3
    s3_client = Aws::S3::Client.new(region: s3region)
    s3_client.get_object(bucket: s3bucket,
                         key: s3filename,
                         response_target: '/files/default/update.zip')
  end
  action :run
end

# Extract the application
windows_zipfile "/files/default" do
  source '/files/default/update.zip'
  action :unzip
end

# Stop the default website so we can update the files
iis_site "Default Web Site" do
  action :stop
end

# Sync the update with the default website
remote_directory "#{node['iis']['docroot']}" do
  source 'iis-application'
  purge true
  action :create
end

# Restart the default website 
iis_site "Default Web Site" do
  action :start
end
