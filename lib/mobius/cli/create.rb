require "thor"

class Mobius::Cli::Create < Mobius::Cli::Base
  desc "dapp_account", "Create DApp Store account funded with MOBI and XLM (test network only)"
  method_option :application, type: :string, aliases: "-a"
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def dapp_account
    say "Calling Mobius FriendBot..."
    keypair = Stellar::KeyPair.random
    Mobius::Client::FriendBot.call(keypair.seed)
    say " * Public Key: #{keypair.address}"
    say " * Private Key: #{keypair.seed}"
    say " * MOBI balance: #{Mobius::Client::Blockchain::Account.new(keypair).balance}"
    if options["application"]
      say "Adding cosigner..."
      app_keypair = Mobius::Client.to_keypair(options["application"])
      Mobius::Client::Blockchain::AddCosigner.call(keypair, app_keypair)
    end
    say "Done!"
  rescue StandardError => e
    say "[ERROR] #{e.message}", :red
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  desc "account", "Create regular Stellar account funded with XLM only (test network only)"
  def account
    say "Calling Stellar FriendBot..."
    keypair = Stellar::KeyPair.random
    Mobius::Client::Blockchain::FriendBot.call(keypair)
    say " * Public Key: #{keypair.address}"
    say " * Private Key: #{keypair.seed}"
    say " * XLM balance: #{Mobius::Client::Blockchain::Account.new(keypair).balance(:native)}"
    say "Done!"
  rescue StandardError => e
    say "[ERROR] #{e.message}", :red
  end
end
