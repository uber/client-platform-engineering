module CPE
  class Environment
    # This *must* end with a newline character or everything will break.
    CHEF_MANAGED_TAG = "# Managed by Chef\n"

    def self.chef_managed?(config_path)
      return false unless ::File.exist?(config_path)

      read_config(config_path).include?(CHEF_MANAGED_TAG)
    end

    def self.zsh_chef_managed?(config_path, cpe_config_path)
      return false unless ::File.exist?(config_path)

      # Make sure the include lines exists somewhere in the file
      lines = read_config(config_path)
      return lines.each_cons(2).any? { |line1, line2| zsh_config_lines(cpe_config_path) == [line1, line2] }
    end

    def self.profile_chef_managed?(config_path, cpe_profiled_file)
      return false unless ::File.exist?(config_path)

      # Make sure the include lines exists somewhere in the file
      lines = read_config(config_path)
      return lines.each_cons(2).any? { |line1, line2| bash_config_lines(cpe_profiled_file) == [line1, line2] }
    end

    def self.read_config(config_path)
      return [] unless ::File.exist?(config_path)

      lines = ::File.readlines(config_path)
      return lines
    end

    def self.zsh_config_lines(cpe_config_path)
      [
        CHEF_MANAGED_TAG,
        "source #{cpe_config_path}\n",
      ]
    end

    def self.bash_config_lines(cpe_profiled_file)
      [
        CHEF_MANAGED_TAG,
        "[ -r #{cpe_profiled_file} ] && . #{cpe_profiled_file}\n",
      ]
    end
  end
end
