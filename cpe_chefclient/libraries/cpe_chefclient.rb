module CPE
  class Chefclient
    def self.config_json(basedir)
      ::File.join(basedir, '.cpe_chefclient.json')
    end
  end
end
