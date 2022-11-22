require 'pathname'

module Gubg
    module Build
        @@root_dir = nil
        def self.root_dir(fn = nil)
            unless @@root_dir
                @@root_dir = find_root_()
                raise "This file is not part of a git repository" unless @@root_dir
            end
            dir = @@root_dir
            dir = File.join(dir, fn) if fn
            dir
        end

        private
        def self.find_root_()
            Pathname.new(File.dirname(__FILE__)).descend do |p|
                return p if (File.exists?(p + ".git"))
            end
            return nil
        end
    end
end
