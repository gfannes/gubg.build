require('fileutils')

module GUBG
    def self.shared(*parts)
        raise('ERROR: You have to specify the shared destination dir via the environment vairable "gubg"') unless ENV.has_key?('gubg')
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

    def self.publish(src, pattern, na = {dst: nil, mode: nil})
        dst = shared(na[:dst])
        Dir.chdir(src) do
            FileList.new(pattern).each do |fn|
                dst_fn = File.join(dst, fn)
                dst_dir = File.dirname(dst_fn)
                FileUtils.mkdir_p(dst_dir) unless File.exist?(dst_dir)
                if (!File.exist?(dst_fn) or !FileUtils.identical?(fn, dst_fn))
                    puts("Installing \"#{fn}\" to \"#{dst_fn}\"")
                    FileUtils.install(fn, dst_dir, mode: na[:mode])
                end
            end
        end
    end
    def publish(src, pattern, na = {})
        GUBG::publish(src, pattern, na)
    end

    def self.link_unless_exists(old, new)
        ln_s(old, new) unless (File.exist?(new) or File.symlink?(new))
    end
    def link_unless_exists(old, new)
        GUBG::link_unless_exists(old, new)
    end

    def self.git_clone(uri, name)
        if not File.exist?(name)
            Rake.sh("git clone #{uri}/#{name}")
            Dir.chdir(name) {yield} if block_given?
        end
    end
    def git_clone(uri, name)
        GUBG::git_clone(uri, name)
    end
end

$LOAD_PATH << GUBG::shared('ruby')
