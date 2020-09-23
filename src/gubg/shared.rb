require('fileutils')
require('pathname')
require('digest/md5')

module GUBG
    def self.shared(*parts)
        raise('ERROR: You have to specify the shared destination dir via the environment variable "gubg"') unless ENV.has_key?('gubg')
        File.join(ENV['gubg'], *parts.compact)
    end
    #Makes sure we can "include GUBG" to call shared() directly
    def shared(*parts)
        GUBG::shared(*parts)
    end

    def self.shared_file(*parts)
        fn = shared(*parts)
        raise("File \"#{fn}\" does not exist") unless File.exist?(fn)
        fn
    end
    def shared_file(*parts)
        GUBG::shared_file(*parts)
    end

    def self.shared_dir(*parts)
        dir = shared(*parts)
        FileUtils.mkdir_p(dir) unless File.exist?(dir)
        dir
    end
    def shared_dir(*parts)
        GUBG::shared_dir(*parts)
    end

    def self.home(*parts)
        File.join(ENV['HOME'], *parts.compact)
    end
    def self.home_file(*parts)
        fn = self.home(*parts)
        raise("File \"#{fn}\" does not exist") unless File.exist?(fn)
        fn
    end
    def self.home_dir(*parts)
        dir = self.home(*parts)
        FileUtils.mkdir_p(dir) unless File.exist?(dir)
        dir
    end

    def self.mkdir(*parts)
        dir = File.join(*parts.compact.map{|e|e.to_s})
        FileUtils.mkdir_p(dir) unless File.exist?(dir)
        dir
    end
    def mkdir(*parts)
        GUBG::mkdir(*parts)
    end

    class MissingSubmoduleError < StandardError
    end
    def self.each_submod(na = {submods: nil}, &block)
        require("gubg/naft/Parser")

        submods = na[:submods]

        infos = []
        info = nil
        p = GUBG::Naft::Parser.new(
            node: ->(tag){
                name = tag[/submodule "(.+)"/, 1]
                info = if (!submods || submods.include?(name))
                           {name: name}
                       else
                           puts("Skipping submodule \"#{name}\"")
                           nil
                       end
            },
            text: ->(text){
                text.each_line do |line|
                    if md = /\s*([^\s]+)\s*=\s*([^\s]+)\s*/.match(line)
                        key, value = md[1], md[2]
                        case key
                        when "branch" then info[:branch] = value
                        when "path" then info[:path] = value
                        end
                    end
                end if info
            },
            node_done: ->(){ infos << info if info },
        )
        p.process(File.read(".gitmodules"))

        infos.flatten.each do |info|
            puts(">>>> #{info[:name]}")
            path = info[:path]
            Rake.sh("git submodule update --init #{path}") if Dir[File.join(path, "*")].empty?
            Dir.chdir(path) do
                yield(info)
            end
            puts("<<<< #{info[:name]}\n\n")
        end
    end
    def each_submod(submods, &block)
        GUBG::each_submod(submods, &block)
    end

    def self.md5sum(fn)
        Digest::MD5.hexdigest(File.open(fn, 'rb'){|fi|fi.read})
    end
    def md5sum(fn)
        GUBG::md5sum(fn)
    end

    #The passed block allows you to change the destination filename
    def self.publish(src, na = {pattern: nil, dst: nil, mode: nil}, &block)
        dst_dir = na[:dst] || shared_dir()
        dst_dir = shared_dir(dst_dir) unless Pathname.new(dst_dir).absolute?
        FileUtils.mkdir_p(dst_dir) unless File.exist?(dst_dir)
        if File.directory?(src)
            patterns = [na[:pattern] || '*'].flatten
            Dir.chdir(src) do
                patterns.each do |pattern|
                    FileList.new(pattern).each do |fn|
                        dst_fn = File.join(dst_dir, fn)
                        new_fn = (block_given? ? block.call(dst_fn) : dst_fn)
                        if File.directory?(fn)
                            # puts("\"#{fn}\" is a directory, I will not publish this.") unless File.exist?(dst_fn)
                        else
                            my_dst_dir = File.dirname(dst_fn)
                            FileUtils.mkdir_p(my_dst_dir) unless File.exist?(my_dst_dir)
                            if (!File.exist?(new_fn) or !FileUtils.identical?(fn, new_fn))
                                puts("Installing \"#{fn}\" to \"#{new_fn}\"")
                                FileUtils.install(fn, my_dst_dir, mode: na[:mode])
                                FileUtils.mv(dst_fn, new_fn) if (dst_fn != new_fn)
                            end
                        end
                    end
                end
            end
        else
            dst_fn = File.join(dst_dir, src)
            new_fn = (block_given? ? block.call(dst_fn) : dst_fn)
            my_dst_dir = File.dirname(dst_fn)
            FileUtils.mkdir_p(my_dst_dir) unless File.exist?(my_dst_dir)
            if (!File.exist?(new_fn) or !FileUtils.identical?(src, new_fn))
                puts("Installing \"#{src}\" to \"#{new_fn}\"")
                FileUtils.install(src, my_dst_dir, mode: na[:mode])
                FileUtils.mv(dst_fn, new_fn) if (dst_fn != new_fn)
            end
        end
    end
    def publish(src, na = {}, &block)
        GUBG::publish(src, na, &block)
    end

    def self.link_unless_exists(old, new)
        if (!File.exist?(new) and !File.symlink?(new))
            puts("Linking #{new} to #{old}")
            FileUtils.ln_s(old, new)
        end
    end
    def link_unless_exists(old, new)
        GUBG::link_unless_exists(old, new)
    end

    def self.git_clone(uri, name, &block)
        if not File.exist?(name)
            Rake.sh("git clone #{uri}/#{name}")
        end
        Dir.chdir(name) {yield} if block_given?
    end
    def git_clone(uri, name, &block)
        GUBG::git_clone(uri, name, &block)
    end

    def self.os()
        case RUBY_PLATFORM
        when /mingw/ then :windows
        when /darwin/ then :macos
        else :linux
        end
    end
    def os()
        GUBG::os()
    end

    def self.which(program, &block)
        path = case os
               when :linux, :macos then `which #{program}`
               when :windows then `where #{program}`
               else raise("Unknown os #{os}") end
        path.chomp!
        return nil if (path.empty?)
        yield(path) if block_given?
        path
    end
    def which(program, &block)
        GUBG::which(program, &block)
    end

    def self.sandbox(na = {chdir: nil}, &block)
        base = case os
               when :linux, :macos then "/tmp/gubg/sandbox"
               when :windows then "C:\\temp\\gubg\\sandbox"
               else raise("Unknown os #{os}") end

        dir, ix = nil, 0
        loop do
            dir = "#{base}_#{ix}"
            break unless File.exist?(dir)
            puts("Sandbox #{dir} already exists")
            ix += 1
        end

        chdir = na[:chdir]||false
        GUBG::mkdir(dir)
        if chdir
            Dir.chdir(dir) do
                block.call(dir)
            end
        else
            block.call(dir)
        end
        puts "Removing #{dir}"
        FileUtils.rm_rf(dir)
    end
    def sandbox(na = {chdir: nil}, &block)
        GUBG::sandbox(na, &block)
    end
end
