# The app_config plugin allows easy setup of 
# application specific configuration.
#
# There is support for different sections, where 
# common is default for all sections.
#
# The variables defined are available from Conf.
# 
# Example: 
#  # config/config.yml
#  common:
#    x: 1
#    y: 20
#  production:
#    y: 40
#
#  # In some code:
#   ... Conf.x ...
#
#  The value of Conf.y will be 40 in the production environment.
#
# There is support for local overrides by creating a file
#  config/config.local.yml
#
# The plugin app_config is responsible for loading the config files.

class AppConfig
  
  def initialize(file = nil)
    @sections = {}
    @params = {}
    use_file!(file) if file
  end
  
  def use_file!(file)
    begin
      hash = YAML::load(ERB.new(IO.read(file)).result) 
      if hash then 
        @sections.merge!(hash) do |key, old_val, new_val|
          case [old_val.class,new_val.class] 
          when [Hash,Hash] then old_val.merge new_val
          when [nil.class,Hash] then new_val
          when [Hash,nil.class] then old_val
          when [nil.class,nil.class] then nil
          else raise "Semantic error in #{file}." 
          end 
        end
      end
      @params.merge!(@sections['common'])
    rescue Errno::ENOENT
      # Gracefully handle missing file.; 
    end    
  end
  
  def use_section!(section)
    # Only do merge if there is a section, and 
    # it contains a hash.
    # An empty section will be nil, and not a hash.
    case @sections[section.to_s] 
    when Hash then 
      @params.merge!(@sections[section.to_s]) 
    end
  end
  
  def method_missing(param)
    param = param.to_s
    if @params.key?(param)
      @params[param]
    else
      raise "Invalid AppConfig Parameter " + param
    end
  end
  
end
