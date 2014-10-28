module Docsplit
  module FixImageExtractor
    def self.included(receiver)
      receiver.class_eval do
        # original: https://github.com/documentcloud/docsplit/blob/master/lib/docsplit/image_extractor.rb
        # modified for use on Windows
        # fixes assignment of enviroment variables
        def convert(pdf, size, format, previous=nil)
          tempdir = Dir.mktmpdir
          basename = File.basename(pdf, File.extname(pdf))
          directory = directory_for(size)
          pages = @pages || '1-' + Docsplit.extract_length(pdf).to_s
          escaped_pdf = ESCAPE[pdf]
          FileUtils.mkdir_p(directory) unless File.exists?(directory)
          memory_args = '-limit memory 256MiB -limit map 512MiB'
          common = "#{memory_args} -density #{@density} #{resize_arg(size)} #{quality_arg(format)}"
          if previous
            FileUtils.cp(Dir[directory_for(previous) + '/*'], directory)
            execute_command("SET MAGICK_TMPDIR=\"#{tempdir}\"")
            execute_command("SET OMP_NUM_THREADS=2")
            # "2>&1" redirects stderr (2) to stdout (1)
            result = execute_command("gm mogrify #{common} -unsharp 0x0.5+0.75 \"#{directory}/*.#{format}\" 2>&1").chomp
            raise ExtractionFailed, result if $? != 0
          else
            page_list(pages).each do |page|
              out_file = ESCAPE[File.join(directory, "#{basename}_#{page}.#{format}")]
              execute_command("SET MAGICK_TMPDIR=\"#{tempdir}\"")
              execute_command("SET OMP_NUM_THREADS=2")
              # "2>&1" redirects stderr (2) to stdout (1)
              result = execute_command("gm convert +adjoin -define pdf:use-cropbox=true #{common} \"#{escaped_pdf}\"[#{page - 1}] \"#{out_file}\" 2>&1").chomp
              raise ExtractionFailed, result if $? != 0
            end
          end
          ensure
            FileUtils.remove_entry_secure tempdir if File.exists?(tempdir)
        end
        
        def execute_command(cmd)
          Rails.logger.info "Execute #{cmd}"
          `#{cmd}`
        end
      end
    end
  end
end