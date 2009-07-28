class IndexTableGroongaGenerator < Rails::Generator::NamedBase
  default_options :tokenizer => nil

  def manifest
    record do |m|
      m.migration_template 'migration.rb', 'db/groonga/migrate', :assigns => {
        :migration_name => "Create#{class_name.pluralize.gsub(/::/, '')}",
        :default_tokenizer_name => (options[:tokenizer] || "TokenBigram").inspect,
      }, :migration_file_name => "create_#{file_path.gsub(/\//, '_').pluralize}"
    end
  end

  private
  def banner
    "Usage: #{$0} #{spec.name} index_table_name\n" +
    " e.g.: #{$0} #{spec.name} terms"
  end

  def add_options!(opt)
    opt.separator ''
    opt.separator 'Options:'
    opt.on("--tokenizer=TOKENIZER",
           "Use TOKENIZER as a default tokenizer") do |value|
      options[:tokenizer] = value
    end
  end
end
