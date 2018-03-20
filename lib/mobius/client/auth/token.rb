class Mobius::Client::Auth::Token
  # Raised if transaction one of transaction signatures is wrong.
  class Unauthorized < StandardError; end

  # Raised if transaction is invalid or time bounds are missing.
  class Invalid < StandardError; end

  # Raised if transaction has expired.
  class Expired < StandardError; end

  extend Dry::Initializer

  # @!method initialize(seed)
  # @param seed [String] Developers private key.
  # @param xdr [String] Auth transaction XDR.
  # @param address [String] User public key.
  # @!scope instance
  param :seed
  param :xdr
  param :address

  # Returns time bounds for given transaction.
  #
  # @return [Stellar::TimeBounds] Time bounds for given transaction (`.min_time` and `.max_time`).
  # @raise [Unauthorized] if one of the signatures is invalid.
  # @raise [Invalid] if transaction is malformed or time bounds are missing.
  def time_bounds
    bounds = envelope.tx.time_bounds

    raise Unauthorized unless signed_correctly?
    raise Invalid if bounds.nil?

    bounds
  end

  # Validates transaction signed by developer and user.
  #
  # @return [Boolean] true if transaction is valid, raises exception otherwise
  # @raise [Unauthorized] if one of the signatures is invalid
  # @raise [Invalid] if transaction is malformed or time bounds are missing
  # @raise [Expired] if transaction is expired (current time outside it's time bounds)
  def validate!
    bounds = time_bounds
    raise Expired unless time_now_covers?(bounds)
    true
  end

  private

  # @return [Stellar::KeyPair] Stellar::KeyPair object for given seed
  def keypair
    @keypair ||= Stellar::KeyPair.from_seed(seed)
  end

  # @return [Stellar::KeyPair] Stellar::KeyPair of user being authorized
  def their_keypair
    @their_keypair ||= Stellar::KeyPair.from_address(address)
  end

  # @return [Stellar::TrnansactionEnvelope] Stellar::TrnansactionEnvelope of challenge transaction
  def envelope
    @envelope ||= Stellar::TransactionEnvelope.from_xdr(xdr, "base64")
  end

  # @return [Bool] true if transaction is signed by both parties
  def signed_correctly?
    envelope.signed_correctly?(keypair, their_keypair)
  end

  def time_now_covers?(time_bounds)
    (time_bounds.min_time..time_bounds.max_time).cover?(Time.now.to_i)
  end
end