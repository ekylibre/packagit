module Packagit

  class Specification
    attr_accessor :name, :version, :files, :loaded_from

    REQUIREDS = [:name, :version]

    def initialize(&block)
      unless block_given?
        raise ArgumentError, "Block must be given"
      end
      yield(self)
      for required in REQUIREDS
        if self.send(required).to_s =~ /\A[[:space:]]*\z/
          raise ArgumentError, "#{required} must be given (#{self.class.name})"
        end
      end
    end


    # Widely inspired from rubygems
    def self.load(file)
      code = if defined? Encoding
               File.read(file, :mode => 'r:UTF-8:-')
             else
               File.read(file)
             end
      
      code.untaint

      begin
        spec = eval(code, binding, file.to_s)

        if Packagit::Specification === spec
          spec.loaded_from = File.expand_path file.to_s
          return spec
        end
        
        warn "[#{file}] isn't a Packagit::Specification (#{spec.class} instead)."
      rescue SignalException, SystemExit
        raise
      rescue SyntaxError, Exception => e
        warn "Invalid packagit in [#{file}]: #{e}"
      end
      
      return nil
    end

  end

end
