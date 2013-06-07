found_gem = false
gem_name = "docsplit"

gem_installed = `bundle show | #{gem_name}`
unless gem_installed.to_s.include?(gem_name)

  pkg_install = []
  {"gm" => "graphicsmagick", "pdfinfo" => ["poppler-utils","poppler-data"]}.each do |cmd,package|
    `command -v #{cmd} >/dev/null 2>&1 || { echo >&2 \"I require #{cmd} but it's not installed.  Aborting.\"; exit 1;}`
    unless $? == 0
      package = package.join(" ") if package.respond_to?("join")
      pkg_install << "please install #{package} with:"
      pkg_install << "apt-get install #{package}"
    end
  end

  unless pkg_install.empty?
    puts pkg_install.join("\n")
    exit 1
  end

  f = File.open("#{File.join(Rails.root,"Gemfile")}","r+")
  while(line = f.gets)
     found_gem = true if line.include?("docsplit")
  end
  f.close

  unless found_gem 
  
    File.open("#{File.join(Rails.root,"Gemfile")}", 'a') { |file| file.write("\ngem 'docsplit'") }
    puts "run bundle install" 
    exit 1
  end
end