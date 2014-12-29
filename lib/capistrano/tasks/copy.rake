namespace :copy do

  archive_name = "archive.tar.gz"
  include_dir  = fetch(:include_dir) || "*"
  exclude_dir  = Array(fetch(:exclude_dir))
  base_dir = fetch(:base_dir) || "."

  exclude_args = exclude_dir.map { |dir| "--exclude '#{dir}'"}

  # Defalut to :all roles
  tar_roles = fetch(:tar_roles, 'all')

  desc "Archive files to #{archive_name}"
  file archive_name => FileList[File.join(base_dir, include_dir)].exclude(archive_name) do |t|
    cmd = ["tar -cvz -C #{base_dir} -f #{t.name}", *exclude_args, *t.prerequisites.map { |f| f.gsub %r{^#{base_dir}/}, '' }]
    sh cmd.join(' ')
  end

  desc "Deploy #{archive_name} to release_path"
  task :deploy => archive_name do |t|
    tarball = t.prerequisites.first

    on roles(tar_roles) do
      # Make sure the release directory exists
      puts "==> release_path: #{release_path} is created on #{tar_roles} roles <=="
      execute :mkdir, "-p", release_path

      # Create a temporary file on the server
      tmp_file = capture("mktemp")

      # Upload the archive, extract it and finally remove the tmp_file
      upload!(tarball, tmp_file)
      execute :tar, "-xzf", tmp_file, "-C", release_path
      execute :rm, tmp_file
    end

    Rake::Task["copy:clean"].invoke
  end

  task :clean do |t|
    # Delete the local archive
    File.delete archive_name if File.exists? archive_name
  end

  task :create_release => :deploy
  task :check
  task :set_current_revision

end
