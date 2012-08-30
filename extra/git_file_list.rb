require 'rubygems'
require 'fileutils'

class FileFinder 

  @datapath

  def initialize(_datapath) 
    @datapath = _datapath
    @files = {}
  end
  
  def read_git_data
    f = File.open(@datapath,"r+")
    f.each do |line| 
      #next if line.split(" ").length > 1
      path = File.join(File.expand_path(File.dirname(__FILE__)),line).to_s
      path.gsub!(/\s/,"")
      if File.exist?(path) && @files[line.to_s].nil? 
          #puts "found #{line}"
          @files[line.to_s] = path 
        elsif !@files[line.to_s].nil?
          count = 0
          #puts "already listed #{line}"
      end
    end
  end 
  
  def copy_files_to_backup
    @backup_path = File.join(File.dirname(__FILE__),"backup")  
    if !File.directory?(@backup_path)
      FileUtils.mkdir(@backup_path)
    end
    
    @files.each do |v,k|
      cur_dir = create_dir_structure(k)
      puts "backup #{k}"
      FileUtils.cp(k,cur_dir)
    end
  end
    
  def create_dir_structure(path)
    dirs = File.basename(path)
    file_path = create_absolute_path(File.dirname(path),File.expand_path(@backup_path))
    FileUtils.mkdir_p(file_path)
    return file_path
  end
  
  def create_absolute_path(old_p,new_p)
    op = old_p.split(File::SEPARATOR).map{|m| m.gsub(/\W/,"")}
    np = new_p.split(File::SEPARATOR)
    if np.length > op.length 
      long = np 
      short = op 
    else
      long = op 
      short = np 
    end
    
    insert_long = 0 
    insert_short = 0 
    
    short.each_with_index do |s,sc| 
      next if long[sc] == s 
      insert_long = sc 
      insert_short = sc 
      break
    end
    long.insert(insert_long,short[insert_short])
    return long.join(File::SEPARATOR)
  end
  
  def gereate_file_list()
    system("git checkout #{commit_start}; git diff --oneline --name-only #{commit_end} > ./.change_log")
  end
end



if __FILE__ == $0
  
  if File.exist?(ARGV[0].to_s)
    f = FileFinder.new(ARGV[0].to_s)
    f.read_git_data
    f.copy_files_to_backup
  else 
    puts "No file found"
  end
end