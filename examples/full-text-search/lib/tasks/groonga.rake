# -*- ruby -*-

Rake::Task['db:test:prepare'].clear

$LOAD_PATH.unshift(File.expand_path("#{File.dirname(__FILE__)}/../../../../lib"))
require 'active_groonga/tasks'
