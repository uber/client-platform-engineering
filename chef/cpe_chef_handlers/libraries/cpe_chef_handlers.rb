module CPE
  class ChefHandlers
    def self.config(basedir)
      ::File.join(basedir, 'client-handlers.rb')
    end
  end
end
