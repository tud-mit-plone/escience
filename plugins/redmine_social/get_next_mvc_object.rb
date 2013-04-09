 #!/usr/bin/env ruby
 # A script that will pretend to resize a number of images
 require 'optparse'
 require 'fileutils'
 require 'action_view'
 require 'yaml'
 require 'logger'

 @tasks = ["copy_model", "copy_controller", "copy_views", "copy_migrations", "copy_routes"]

@stored_tasks
@stored_views = {}
@stored_models = {}
@stored_controllers = {}
@stored_migrations = {}

@task_store_file
@start_time
@logger = Logger.new(STDOUT)
@logger.level = Logger::INFO


def load_stored_tasks() 
  @stored_tasks.each do |k,v| 
    next if v.class != Hash
    v.each do |tasks, files|
      hash = instance_variable_get("@stored_#{tasks}")
      unless hash.nil?
        if files.class == Array 
          files.each do |file| 
            hash[file] = true
          end
        else
          hash[files] = true  
        end
      end
    end
  end
end

def load_tasks(options)
  @task_store_file = File.join("#{options[:target_path]}",".mvc_import")
  @stored_tasks = {}

  if File.exist?(@task_store_file)
    @stored_tasks = YAML.load_file(@task_store_file)
    load_stored_tasks()
  end
end

def write_task(options)
  unless @task_store_file.nil?
    @logger.info @stored_tasks
    @stored_tasks[@start_time] = {} if @stored_tasks[@start_time].nil? 
    File.open(@task_store_file, 'w+') {|f| f.write(@stored_tasks.to_yaml) }
  end
end

def add_task(task,files)
  @logger.info "create #{files} to #{task}"
  @stored_tasks ||= {} 
  @stored_tasks[@start_time] ||= {}
  @stored_tasks[@start_time][task] ||= []
  @stored_tasks[@start_time][task] << files
  @stored_tasks[@start_time][task].flatten! 
end

def created_files_to_task(file,task)
  if (File.exist?(file))
    if File.directory?(file)
      add_task(task, Dir["#{file}/*"])
    else
      add_task(task,file)
    end
  end
end

def copy_views(options)
  #copy views
  target_path = File.join(options[:target_path],"views","#{options[:model_name].to_s.pluralize}")
  source_path = File.join(options[:source_path],"views","#{options[:model_name].to_s.pluralize}")

  unless File.directory?(target_path)
    FileUtils.mkdir_p(target_path)
    @logger.info "create #{target_path}"
  end

  Dir["#{source_path}/*"].each do |file|
    unless @stored_views[File.join(target_path,file.split('/').last)].nil? || options[:the_force] 
      @logger.info "skip #{File.join(target_path,file.split('/').last)} ... exists"
      next 
    end
    FileUtils.cp(file,target_path)
    created_files_to_task(File.join(target_path,file.split('/').last),"views")
  end
end

def copy_controller(options)
  #copy controller
  source_path = File.join(options[:source_path],"controllers","#{options[:model_name].to_s.pluralize}_controller.rb")
  unless File.exist?(source_path)
    @logger.warn "skip #{source_path} ... doesn't exist"
    return
  end
  target_path = File.join(options[:target_path],"controllers","#{options[:model_name].to_s.pluralize}_controller.rb")
  if @stored_controllers[target_path].nil? || options[:the_force] 
    FileUtils.cp(source_path, target_path)
    created_files_to_task(target_path,"controllers")
  else
    @logger.info "skip #{target_path} ... exists"
  end
end

def copy_model(options)
  if find_app_paths(options).nil? 
    return @logger.warn "target or source path are wrong"
  end
  
  source_path = File.join(options[:source_path],"models","#{options[:model_name].to_s.singularize}.rb")
  target_path = File.join(options[:target_path],"models","#{options[:model_name].to_s.singularize}.rb")

  if( (File.exist?(source_path)) && 
      (File.exists?(target_path) == false))
    if @stored_controllers[target_path].nil? || options[:the_force] 
      FileUtils.cp(source_path, target_path)
      created_files_to_task(target_path,"models")
    else
      @logger.info "skip #{File.join(target_path,file.split('/').last)} ... exists"
    end
  else 
    if (!(File.exist?(File.join(options[:source_path],"models","#{options[:model_name].to_s.singularize}.rb"))))
      @logger.warn "no model source file found with name \n #{options[:model_name].to_s.singularize}.rb"
    else
      @logger.warn "target model already exists try \nmeld #{File.join(options[:source_path],"models","#{options[:model_name].to_s.singularize}.rb")} #{File.join(options[:target_path],"models","#{options[:model_name].to_s.singularize}")}.rb"  
    end
  end 
end

def find_app_paths(options)
  unless options[:source_path].split('/').last.gsub('/','') == "app"
    return nil 
  end
  unless options[:target_path].split('/').last.gsub('/','') == "app"
    return nil
  end
  return true
end

def copy_migrations(options)
  cmd = "grep -r \':#{options[:model_name]}\' #{options[:source_path]}../db/migrate/ | awk -F \': \'  \'{print $1 }\'"
  out =  `#{cmd}`
  out = out.split("\n")
  out.uniq! 
  out.each do |file|
    if File.exist?(File.join(options[:target_path],"../db/migrate","#{file.split("/").last}"))
      @logger.warn "skip: #{file.split("/").last} ... exists"
      dir = File.join(options[:target_path],"../db/migrate","#{file.split("/").last}")
      next 
    end
    if @stored_migrations[File.join(options[:target_path],"../db/migrate","#{file.split("/").last}")].nil? || options[:the_force]
      FileUtils.cp(file.to_s, 
                      File.join(options[:target_path],"../db/migrate","#{file.split("/").last}"))
      created_files_to_task(File.join(options[:target_path],"../db/migrate","#{file.split("/").last}"),"migrate")
    end
  end
end

def copy_routes(options)
  cmd = "grep -r \' :#{options[:model_name]}\' #{options[:source_path]}../config/routes.rb | awk -F \': \'  \'{print $1 }\'"
  out = `#{cmd}`
  #@logger.info "#{cmd}"
  out = out.split("\n")
  out.uniq! 

  if out.nil? || out.empty?
    return 
  end 

  route_insert ||= []
  route_insert << "\# automatic insertion for #{options[:model_name]} model"

  out.each do |app|
    if app.include?(" do ") || app.include?("{")
      #nested_route more todo here anyway 
      #...
    else
      route_insert << app 
    end
  end
  new_routes = File.open("#{options[:target_path]}../config/routes.rb","r")
  routes = []
  while (line = new_routes.gets)
    routes << line.gsub("\n","")
  end
  new_routes.close 

  #looking for the last 'end' -> place for insertion
  insert_at = -1
  routes.reverse.each_with_index do |route,i|
    if route.include?('end')
      insert_at = i + 1 
    end
  end
  
  if insert_at < 0 
    @logger.warn("new route file is corrupted, no place for insert found")
    return 
  end

  routes.insert(routes.length - (insert_at), route_insert)
  routes.flatten!
  File.open("#{options[:target_path]}../config/routes.rb","w"){|f| f.write(routes.join("\n"))}
end

def get_model_appearance(options)
  cmd = "grep -r -n \' :#{options[:model_name]}\' #{options[:source_path]}../"
  out = `#{cmd}`
  #@logger.info "#{cmd}"
  out = out.split("\n")
  out.uniq! 
  out.each do |line| 
    @logger.info "#{line}"
  end
  return
end

def redo_stored_task(options)
  p "todo"
  #options[:redo_stored_task]
  #@stored_tasks
  
end

def show_history(options)
  @stored_tasks.each do |k,v|
    p "#{k}: "
    if v.class == Hash
        v.each do |k,itm| 
          printf("\t%s\n\t\t%s\n",k,itm)
        end
      else
        printf("\t%s\n", v)
    end
  end
end

if __FILE__ == $0 
    @start_time = Time.now.to_i
    options = {}
   
    optparse = OptionParser.new do|opts|
      # Set a banner, displayed at the top
      # of the help screen.
      opts.banner = "Usage: #{__FILE__} --model <model_name> --source_path <PATH/app> --target_path <PATH/app>"
   
      # Define the options, and what they do
      options[:verbose] = false
      opts.on( '-v', '--verbose', 'Output more information' ) do
        options[:verbose] = true
      end
   
      options[:quick] = false
      opts.on( '-q', '--quick', 'Perform the task quickly' ) do
        options[:quick] = true
      end
      options[:model_name] = nil
      opts.on( '-m', '--model_name FILE', 'select the model you want to select' ) do |file|
        options[:model_name] = file
      end
      options[:source_path] = nil
      opts.on( '-s', '--source_path PATH', 'path to the model you want to select' ) do |path|
        options[:source_path] = path
      end
      
      options[:the_force] = nil
      opts.on( '-f', '--force', 'may the force be with you, ignore only history files and copy once again, if they
                      exist no copy is done' ) do 
        options[:the_force] = true
      end

      opts.on( '-q', '--quiet', 'all info and debug messages' ) do 
        @logger.level = Logger::WARN
      end

      opts.on('-r', '--routes_extract', 'search for routes in source_path and copy them into routes in target_path' ) do 
        @tasks = ["copy_routes"]
      end

      options[:target_path] = "./"
      opts.on( '-t', '--target_path PATH', 'path to target project [./]' ) do |path|
        options[:target_path] = path
      end

      opts.on('-i','--information', 'get all files in source_path which involve model_name')  do 
        @tasks = ["get_model_appearance"]
      end

      options[:redo_stored_task] = "./"
      opts.on('', '--redo_task TIMESTAMP', 'remove the file which belong to one task' ) do |time|
        options[:redo_stored_task] = time
        @tasks = ["redo_stored_task"]
      end
      opts.on( '', '--show_history', 'show the history of files' ) do |time|
        @tasks = ["show_history"]
      end
   
      # This displays the help screen, all programs are
      # assumed to have this option.
      opts.on( '-h', '--help', 'Display this screen' ) do
        puts opts
        exit
      end
    end
   optparse.parse!
   load_tasks(options)
   @tasks.each do |t| 
    __send__("#{t}",options)
   end
   write_task(options)
end