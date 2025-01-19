import Config

for config_file <- Path.wildcard(Path.join([File.cwd!(), "config", "compile_time", "*.exs"])) do
  import_config(config_file)
end
