require 'security'
require 'highline/import' # to hide the entered password

module CredentialsManager
  class AccountManager
    def initialize(user: nil, password: nil)
      @user = user
      @password = password
    end

    def user
      @user ||= ENV["FASTLANE_USER"]
      @user ||= ENV["DELIVER_USER"]
      @user ||= AppfileConfig.try_fetch_value(:apple_id)
      ask_for_login if @user.to_s.length == 0
      return @user
    end

    def password
      @password ||= ENV["FASTLANE_PASSWORD"]
      @password ||= ENV["DELIVER_PASSWORD"]
      unless @password
        item = Security::InternetPassword.find(server: server_name)
        @password ||= item.password if item
      end
      ask_for_login if @password.to_s.length == 0
      return @password
    end

    # Call this method to ask the user to re-enter the credentials
    # @param force: if false the user is asked before it gets deleted
    def invalid_credentials(force: false)
      puts "The login credentials for '#{user}' seem to be wrong".red
      if force || agree("Do you want to re-enter your password? (y/n)", true)
        puts "Removing Keychain entry for user '#{user}'...".yellow
        remove_from_keychain
        ask_for_login
      end
    end

    private

    def ask_for_login
      puts "-------------------------------------------------------------------------------------".green
      puts "The login information you enter will be stored in your Mac OS Keychain".green
      puts "More information about it on GitHub: https://github.com/fastlane/CredentialsManager".green
      puts "-------------------------------------------------------------------------------------".green

      @user = ask("Username: ") while @user.to_s.length == 0
      while @password.to_s.length == 0
        @password = ask("Password (for #{@user}): ") { |q| q.echo = "*" }
      end

      return if ENV["FASTLANE_DONT_STORE_PASSWORD"]

      # Now we store this information in the keychain
      if Security::InternetPassword.add(server_name, user, password)
        return true
      else
        puts "Could not store password in keychain".red
        return false
      end
    end

    def remove_from_keychain
      Security::InternetPassword.delete(server: server_name)
    end

    def server_name
      "deliver.#{user}"
    end
  end
end
