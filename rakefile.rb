require File.join(File.dirname(__FILE__), 'Build/albacore/albacore.rb')
require 'find'
require 'fileutils'

task :default => [:rebuild]

PROJECT_NAME      = "Facebook C# SDK"
PROJECT_NAME_SAFE = "FacebookSDK"
LOG               = false                # TODO: enable albacore logging from ENV
#ENV['NIGHTLY']    = 'false'

build_config = nil

task :configure do
    # do configuration stuffs here
    Albacore.configure do |config|
        config.log_level = :verbose if LOG
    end
    
    root_path    = "#{File.dirname(__FILE__)}/"
    base_version = 0
    
    File.open("#{root_path}VERSION",'r') do |f|
        base_version = f.gets.chomp
    end
    
    build_config = {
        :log    => LOG,
        :paths  => {
            :root    => root_path,
            :src     => "#{root_path}Source/",
            :output  => "#{root_path}Bin/",
            :build   => "#{root_path}Build/",
            :dist    => "#{root_path}Dist/",
            :tools   => "#{root_path}Tools/",
            :working => "#{root_path}Working/",
            :doc     => "#{root_path}Doc/",
            :packages=> '',
            :nuget   => ''
        },
        :version => {
			:base => "#{base_version}",
            :full => "#{base_version}",
            :long => "#{base_version}"
		},
        :vcs => { # version control system
			:name         => '',		# version control name
			:rev_id       => '',		# revision number
            :short_rev_id => ''         # short revision id
		},        
        :ci => {
			:build_number_param_name => 'BUILD_NUMBER',
            :is_nightly              => true,
            :build_number            => 0
		},
        :configuration => :Release,
        :sln => {
            :wp7         => '',
            :sl4         => '',
            :net40		 => '',
            :net35		 => '',
            :shfb        => '', # sandcastle help file builder doc project
        }
    }
    
    build_config[:paths][:packages]  = "#{build_config[:paths][:src]}packages/"
    build_config[:paths][:nuget]  = "#{build_config[:paths][:packages]}NuGet.CommandLine.1.0.11220.26/Tools/NuGet.exe"
        
    build_config[:sln][:wp7]         = "#{build_config[:paths][:src]}Facebook-WP7.sln"
    build_config[:sln][:sl4]         = "#{build_config[:paths][:src]}Facebook-SL4.sln"
    build_config[:sln][:net40]		 = "#{build_config[:paths][:src]}Facebook-Net40.sln"
    build_config[:sln][:net35]		 = "#{build_config[:paths][:src]}Facebook-Net35.sln"
    build_config[:sln][:shfb]        = "#{build_config[:paths][:doc]}doc.shfbproj"
    
    begin
        build_config[:vcs][:rev_id] = `hg id -i`.chomp.chop # remove the +
        build_config[:vcs][:name] = 'hg'
        build_config[:vcs][:short_rev_id] = build_config[:vcs][:rev_id]
	rescue    
	end
    
    if(build_config[:vcs][:rev_id].length==0) then
        # if mercurial fails try git
        begin
            build_config[:vcs][:rev_id]	= `git log -1 --pretty=format:%H`.chomp
		    build_config[:vcs][:name] = 'git'
            build_config[:vcs][:short_rev_id] = build_config[:vcs][:rev_id][0..7]
        rescue
        end
    end
    
    build_config[:ci][:is_nightly]   = ENV['NIGHTLY'].nil? ? true : ENV['NIGHTLY'].match(/(true|1)$/i) != nil
    build_config[:ci][:build_number] = ENV[build_config[:ci][:build_number_param_name]] || 0
    
    build_config[:version][:full] = "#{build_config[:version][:base]}.#{build_config[:ci][:build_number]}"
    
    if(build_config[:ci][:is_nightly])
        build_config[:version][:long] = "#{build_config[:version][:full]}-nightly-#{build_config[:vcs][:short_rev_id]}"
    else
        build_config[:version][:long] = "#{build_config[:version][:full]}-#{build_config[:vcs][:short_rev_id]}"        
    end
    
	puts build_config if build_config[:log]
	puts
    puts "     Project Name: #{PROJECT_NAME}"
	puts "Safe Project Name: #{PROJECT_NAME_SAFE}"
    puts "          Version: #{build_config[:version][:full]} (#{build_config[:version][:long]})"
    puts "     Base Version: #{build_config[:version][:base]}"
    print "  CI Build Number: #{build_config[:ci][:build_number]}"
    print " (not running under CI mode)" if build_config[:ci][:build_number] == 0
    puts
	puts "        Root Path: #{build_config[:paths][:root]}"
    puts
	puts "              VCS: #{build_config[:vcs][:name]}"
	print "      Revision ID: #{build_config[:vcs][:rev_id]}"
	print "  (#{build_config[:vcs][:short_rev_id]})" if build_config[:vcs][:name] == 'git'
	puts	
	puts
    
end

Rake::Task["configure"].invoke

desc "Build .NET 4 binaries"
msbuild :net40 => [:assemblyinfo_facebook,:assemblyinfo_facebookweb,:assemblyinfo_facebookwebmvc] do |msb|
    msb.properties :configuration => build_config[:configuration]
    msb.solution = build_config[:sln][:net40]
    msb.targets :Build
end

msbuild :clean_net40 do |msb|
    msb.properties :configuration => build_config[:configuration]
    msb.solution = build_config[:sln][:net40]
    msb.targets :Clean
end

desc "Build .NET 3.5 binaries"
msbuild :net35 => [:assemblyinfo_facebook,:assemblyinfo_facebookweb,:assemblyinfo_facebookwebmvc] do |msb|
    msb.properties :configuration => build_config[:configuration]
    msb.solution = build_config[:sln][:net35]
    msb.targets :Build
    #msb.use :net35
end

# compile .net 3.5 libraries using msbuild 4.0 in order to generate the code contract libraries.
# seems like if we use .net 3.5, it does not generate the code contracts.
msbuild :clean_net35 do |msb|
    msb.properties :configuration => build_config[:configuration]
    msb.solution = build_config[:sln][:net35]
    msb.targets :Clean
    #msb.use :net35
end

desc "Build Silverlight 4 binaries"
msbuild :sl4 => [:assemblyinfo_facebook] do |msb|
    msb.properties :configuration => build_config[:configuration]
    msb.solution = build_config[:sln][:sl4]
    msb.targets :Build
end

msbuild :clean_sl4 do |msb|
    msb.properties :configuration => build_config[:configuration]
    msb.solution = build_config[:sln][:sl4]
    msb.targets :Clean
end

desc "Build Windows Phone 7 binaries"
msbuild :wp7 => [:assemblyinfo_facebook] do |msb|
   msb.properties :configuration => build_config[:configuration]
   msb.solution = build_config[:sln][:wp7]
   msb.use :net40
   msb.targets :Build
end

msbuild :clean_wp7 do |msb|
   msb.properties :configuration => build_config[:configuration]
   msb.solution = build_config[:sln][:wp7]
   msb.use :net40
   msb.targets :Clean
end

directory "#{build_config[:paths][:working]}"
directory "#{build_config[:paths][:working]}NuGet/Facebook"
directory "#{build_config[:paths][:working]}NuGet/FacebookWeb"
directory "#{build_config[:paths][:working]}NuGet/FacebookWebMvc"

exec :nuget_facebook => [:net35, :net40, :sl4,:wp7,"#{build_config[:paths][:working]}NuGet/Facebook"] do |cmd|
    working_dir = build_config[:paths][:working]
    nuget_working_dir = "#{working_dir}NuGet/Facebook/#{build_config[:version][:full]}/"
    
    FileUtils.rm_rf "#{nuget_working_dir}"
    mkdir "#{nuget_working_dir}"
    mkdir "#{nuget_working_dir}lib/"
    
    nuget_dirs = [ "lib/Net35/",
                   "lib/Net40/",
                   "lib/SL4/",
                   "lib/WP7/" ]
        
    nuget_dirs.each do |d|
        mkdir "#{nuget_working_dir + d}"
        mkdir "#{nuget_working_dir + d}CodeContracts/"
    end
    
    output_path = "#{build_config[:paths][:output]}Release/" if build_config[:configuration] == :Release
    #output_path = "#{build_config[:paths][:output]}Debug/"   if build_config[:configuration] == :Debug
    
    [ "Facebook.dll", "Facebook.pdb", "Facebook.XML" ].each do |f|
        # copy these 3 files of each different framework
        cp "#{output_path}Net35/#{f}", "#{nuget_working_dir}lib/Net35/"
        cp "#{output_path}Net40/#{f}", "#{nuget_working_dir}lib/Net40/"
        cp "#{output_path}SL4/#{f}", "#{nuget_working_dir}lib/SL4/"
        cp "#{output_path}WP7/#{f}", "#{nuget_working_dir}lib/WP7/"
    end
    
    # temporarily copy Json.Net for SL and WP7
    cp "#{output_path}SL4/Newtonsoft.Json.Silverlight.dll", "#{nuget_working_dir}lib/SL4/"
    cp "#{output_path}SL4/Newtonsoft.Json.Silverlight.pdb", "#{nuget_working_dir}lib/SL4/"
    cp "#{output_path}SL4/Newtonsoft.Json.Silverlight.xml", "#{nuget_working_dir}lib/SL4/"
    cp "#{output_path}WP7/Newtonsoft.Json.WindowsPhone.dll", "#{nuget_working_dir}lib/WP7/"
    cp "#{output_path}WP7/Newtonsoft.Json.WindowsPhone.pdb", "#{nuget_working_dir}lib/WP7/"
    cp "#{output_path}WP7/Newtonsoft.Json.WindowsPhone.xml", "#{nuget_working_dir}lib/WP7/"
    
    [ "Facebook.Contracts.dll", "Facebook.Contracts.pdb" ].each do |f|
        # copy code contracts of each different framework
        cp "#{output_path}Net35/CodeContracts/#{f}", "#{nuget_working_dir}lib/Net35/CodeContracts/"
        cp "#{output_path}Net40/CodeContracts/#{f}", "#{nuget_working_dir}lib/Net40/CodeContracts/"
        cp "#{output_path}SL4/CodeContracts/#{f}", "#{nuget_working_dir}lib/SL4/CodeContracts/"
        cp "#{output_path}WP7/CodeContracts/#{f}", "#{nuget_working_dir}lib/WP7/CodeContracts/"
    end
    
    version = build_config[:version][:full]
    File.open("#{nuget_working_dir}Facebook.nuspec",'w+') do |f|
        f.puts File.read("#{build_config[:paths][:build]}Facebook.nuspec").gsub(/{version}/,version)
    end
    
    cmd.command = "#{build_config[:paths][:nuget]}"
    cmd.parameters = "pack \"#{nuget_working_dir}Facebook.nuspec\" -o \"#{build_config[:paths][:working]}NuGet\""
end

exec :nuget_facebookweb => [:net35, :net40,"#{build_config[:paths][:working]}NuGet/FacebookWeb"] do |cmd|
    working_dir = build_config[:paths][:working]
    nuget_working_dir = "#{working_dir}NuGet/FacebookWeb/#{build_config[:version][:full]}/"
    
    FileUtils.rm_rf "#{nuget_working_dir}"
    mkdir "#{nuget_working_dir}"
    mkdir "#{nuget_working_dir}lib/"
    
    nuget_dirs = [ "lib/Net35/",
                   "lib/Net40/" ]
                   
    nuget_dirs.each do |d|
        mkdir "#{nuget_working_dir + d}"
        mkdir "#{nuget_working_dir + d}CodeContracts/"
    end
    
    output_path = "#{build_config[:paths][:output]}Release/" if build_config[:configuration] == :Release
    #output_path = "#{build_config[:paths][:output]}Debug/"   if build_config[:configuration] == :Debug
                   
    [ "Facebook.Web.dll", "Facebook.Web.pdb", "Facebook.Web.XML" ].each do |f|
        # copy these 3 files of each different framework
        cp "#{output_path}Net35/#{f}", "#{nuget_working_dir}lib/Net35/"
        cp "#{output_path}Net40/#{f}", "#{nuget_working_dir}lib/Net40/"
    end
    
    [ "Facebook.Web.Contracts.dll", "Facebook.Web.Contracts.pdb" ].each do |f|
        # copy code contracts of each different framework
        cp "#{output_path}Net35/CodeContracts/#{f}", "#{nuget_working_dir}lib/Net35/CodeContracts/"
        cp "#{output_path}Net40/CodeContracts/#{f}", "#{nuget_working_dir}lib/Net40/CodeContracts/"
    end
    
    version = build_config[:version][:full]
    File.open("#{nuget_working_dir}FacebookWeb.nuspec",'w+') do |f|
        f.puts File.read("#{build_config[:paths][:build]}FacebookWeb.nuspec").gsub(/{version}/,version)
    end
    
    cmd.command = "#{build_config[:paths][:nuget]}"
    cmd.parameters = "pack \"#{nuget_working_dir}FacebookWeb.nuspec\" -o \"#{build_config[:paths][:working]}NuGet\""
    
end

exec :nuget_facebookwebmvc => [:net35, :net40,"#{build_config[:paths][:working]}NuGet/FacebookWebMvc"] do |cmd|
    working_dir = build_config[:paths][:working]
    nuget_working_dir = "#{working_dir}NuGet/FacebookWebMvc/#{build_config[:version][:full]}/"
    
    FileUtils.rm_rf "#{nuget_working_dir}"
    mkdir "#{nuget_working_dir}"
    mkdir "#{nuget_working_dir}lib/"
    
    nuget_dirs = [ "lib/Net35/",
                   "lib/Net40/" ]
                   
    nuget_dirs.each do |d|
        mkdir "#{nuget_working_dir + d}"
        mkdir "#{nuget_working_dir + d}CodeContracts/"
    end
    
    output_path = "#{build_config[:paths][:output]}Release/" if build_config[:configuration] == :Release
    #output_path = "#{build_config[:paths][:output]}Debug/"   if build_config[:configuration] == :Debug
    
    [ "Facebook.Web.Mvc.dll", "Facebook.Web.Mvc.pdb", "Facebook.Web.Mvc.XML" ].each do |f|
        # copy these 3 files of each different framework
        cp "#{output_path}Net35/#{f}", "#{nuget_working_dir}lib/Net35/"
        cp "#{output_path}Net40/#{f}", "#{nuget_working_dir}lib/Net40/"
    end
    
    [ "Facebook.Web.Mvc.Contracts.dll", "Facebook.Web.Mvc.Contracts.pdb" ].each do |f|
        # copy code contracts of each different framework
        cp "#{output_path}Net35/CodeContracts/#{f}", "#{nuget_working_dir}lib/Net35/CodeContracts/"
        cp "#{output_path}Net40/CodeContracts/#{f}", "#{nuget_working_dir}lib/Net40/CodeContracts/"
    end
    
    version = build_config[:version][:full]
    File.open("#{nuget_working_dir}FacebookWebMvc.nuspec",'w+') do |f|
        f.puts File.read("#{build_config[:paths][:build]}FacebookWebMvc.nuspec").gsub(/{version}/,version)
    end
    
    cmd.command = "#{build_config[:paths][:nuget]}"
    cmd.parameters = "pack \"#{nuget_working_dir}FacebookWebMvc.nuspec\" -o \"#{build_config[:paths][:working]}NuGet\""
    
end

desc "Build help documentation"
msbuild :docs => [:net40] do |msb|
    msb.properties :configuration => build_config[:configuration]
    msb.properties :DocumentationSourcePath => "#{build_config[:paths][:output]}Release/Net40/" if build_config[:configuration] = :Release
    #msb.properties :DocumentationSourcePath => "#{build_config[:paths][:output]}Debug/Net40/" if build_config[:configuration] = :Debug
    msb.solution = build_config[:sln][:shfb]
    msb.targets [:Clean,:Rebuild]
    msb.properties
end

msbuild :clean_docs do |msb|
    msb.properties :configuration => build_config[:configuration]
    msb.properties :DocumentationSourcePath => "#{build_config[:paths][:output]}Release/Net40/" if build_config[:configuration] = :Release
    #msb.properties :DocumentationSourcePath => "#{build_config[:paths][:output]}Debug/Net40/" if build_config[:configuration] = :Debug                   
    msb.solution = build_config[:sln][:shfb]
    msb.targets [:Clean]
    msb.properties
end

desc "Build All"
task :all => [:net35, :net40, :sl4,:wp7,:nuget]

desc "Clean and Rebuild All (default)"
task :rebuild => [:clean,:all]

desc "Clean All"
task :clean => [:clean_net35, :clean_net40, :clean_sl4, :clean_wp7] do
    FileUtils.rm_rf build_config[:paths][:output]
    FileUtils.rm_rf build_config[:paths][:working]
    FileUtils.rm_rf build_config[:paths][:dist]    
end

desc "Create NuGet Packages"
task :nuget => [:nuget_facebook,:nuget_facebookweb,:nuget_facebookwebmvc]

directory "#{build_config[:paths][:dist]}"
directory "#{build_config[:paths][:dist]}NuGet"

desc "Create distribution packages"
task :dist => [:rebuild,:docs] do
    rm_rf "#{build_config[:paths][:dist]}"
    mkdir "#{build_config[:paths][:dist]}"
    
    rm_rf "#{build_config[:paths][:working]}Bin/"
    FileUtils.cp_r "#{build_config[:paths][:output]}Release", "#{build_config[:paths][:working]}Bin/"
    
    Find.find("#{build_config[:paths][:working]}Bin/.") do |f|
        ext = File.extname(f)
        if ext == '.sdf' or ext == '.old' then
            rm f
        end
    end
    
   sh "#{build_config[:paths][:tools]}7-zip/7za.exe a -tzip -r \"#{build_config[:paths][:dist]}#{PROJECT_NAME_SAFE}-#{build_config[:version][:long]}.bin.zip\" \"#{build_config[:paths][:working]}Bin/*\""
   
   sh "#{build_config[:paths][:tools]}7-zip/7za.exe a -tzip -r \"#{build_config[:paths][:dist]}#{PROJECT_NAME_SAFE}-#{build_config[:version][:long]}.docs.zip\" \"#{build_config[:paths][:working]}Documentation/*\""
   cp "#{build_config[:paths][:working]}Documentation/Documentation.chm", "#{build_config[:paths][:dist]}#{PROJECT_NAME_SAFE}-#{build_config[:version][:long]}.chm"
    
   sh "#{build_config[:paths][:tools]}7-zip/7za.exe a -tzip \"#{build_config[:paths][:dist]}#{PROJECT_NAME_SAFE}-#{build_config[:version][:long]}.nuget.packages.zip\" \"#{build_config[:paths][:working]}NuGet/*.nupkg\""
   sh "#{build_config[:paths][:tools]}7-zip/7za.exe a -tzip \"#{build_config[:paths][:dist]}#{PROJECT_NAME_SAFE}-#{build_config[:version][:long]}.nuget.nuspec.zip\" \"#{build_config[:paths][:working]}NuGet/*\" -x!*.nupkg"
   
   src_archive_name = "#{build_config[:paths][:dist]}#{PROJECT_NAME_SAFE}-#{build_config[:version][:long]}.src.zip"
   if (build_config[:vcs][:name] = 'git') then
    sh "git archive HEAD --format=zip > \"#{src_archive_name}\""
   elsif (build_config[:vcs][:name] = 'hg') then
    sh "hg archive -tzip \"#{src_archive_name}\""
   end
    
end

assemblyinfo :assemblyinfo_facebook do |asm|
	asm.output_file = "#{build_config[:paths][:src]}Facebook/Properties/AssemblyInfo.cs"
	asm.version = build_config[:version][:full]
	asm.title = "Facebook"
	asm.description = "Facebook C\# SDK"
	asm.product_name = "Facebook C\# SDK"
	asm.company_name = "Facebook C\# SDK"
	asm.copyright = "Microsoft Public License (Ms-PL)"
	asm.com_visible = false
end

assemblyinfo :assemblyinfo_facebookweb do |asm|
	asm.output_file = "#{build_config[:paths][:src]}Facebook.Web/Properties/AssemblyInfo.cs"
	asm.version = build_config[:version][:full]
	asm.title = "Facebook.Web"
	asm.description = "Facebook C\# SDK"
	asm.product_name = "Facebook C\# SDK"
	asm.company_name = "Facebook C\# SDK"
	asm.copyright = "Microsoft Public License (Ms-PL)"
	asm.com_visible = false
end

assemblyinfo :assemblyinfo_facebookwebmvc do |asm|
	asm.output_file = "#{build_config[:paths][:src]}Facebook.Web.Mvc/Properties/AssemblyInfo.cs"
	asm.version = build_config[:version][:full]
	asm.title = "Facebook.Web.Mvc"
	asm.description = "Facebook C\# SDK"
	asm.product_name = "Facebook C\# SDK"
	asm.company_name = "Facebook C\# SDK"
	asm.copyright = "Microsoft Public License (Ms-PL)"
	asm.com_visible = false
end