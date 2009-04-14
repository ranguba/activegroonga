# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_full-text-search_session',
  :secret      => 'd07327845c8512677f352dd75e858fd0a645638d311d7ed93a2e5ce54c7616ff0f9f46055c849c4790d3e63b1b99ef3e2580993b9f90090da4e234c825e6c6e1'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
