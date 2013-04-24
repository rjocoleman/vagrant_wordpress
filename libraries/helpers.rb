module LampHelper
  def get_php_version
    phpv = Versionomy.parse(node['php']['version'])
    "#{phpv.major}.#{phpv.minor}"
  end
  
  def get_php_extension_dir
    system("/usr/bin/php-config --extension-dir")
  end
end