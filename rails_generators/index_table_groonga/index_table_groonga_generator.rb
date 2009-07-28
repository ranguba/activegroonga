class IndexTableGroongaGenerator < Rails::Generator::NamedBase
  default_options :type => nil, :tokenizer => nil

  def manifest
    record do |m|
      m.migration_template 'migration.rb', 'db/groonga/migrate', :assigns => {
        :migration_name => "Create#{class_name.pluralize.gsub(/::/, '')}",
        :type => (options[:type] || :patricia_trie).inspect,
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
    opt.on("--type=TYPE", %w(array patricia_trie hash),
           "Use TYPE as a table type") do |value|
      options[:type] = value
    end

    opt.on("--tokenizer=TOKENIZER", %w(unigram bigram trigram mecab),
           "Use TOKENIZER as a default tokenizer") do |value|
      case value
      when "unigram"
        options[:tokenizer] = "TokenUnigram"
      when "bigram"
        options[:tokenizer] = "TokenBigram"
      when "trigram"
        options[:tokenizer] = "TokenTrigram"
      when "mecab"
        options[:tokenizer] = "TokenMacab"
      else
        options[:tokenizer] = value
      end
    end
  end
end
