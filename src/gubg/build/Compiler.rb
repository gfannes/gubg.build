module Build
    class Compiler
        def initialize(arch)
            @arch = arch
            @cpp_standard = nil
            @include_paths = []
            @defines = []
            @force_includes = []
            @library_paths = []
            @libraries = []
            @options = []
        end

        def set_cpp_standard(std)
            @cpp_standard = std
        end
        def add_include_path(path)
            @include_paths << path
        end
        def add_define(define)
            @defines << define
        end
        def add_force_include(fn)
            @force_includes << fn
        end
        def add_library_path(path)
            @library_paths << path
        end
        def add_library(lib)
            @libraries << lib
        end
        def add_option(option)
            @options << option
        end
    end
end
