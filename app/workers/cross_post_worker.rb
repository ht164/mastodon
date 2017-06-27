# frozen_string_literal: true

class CrossPostWorker
  include Sidekiq::Worker

  def perform(status_id)
    status = Status.find(status_id)

    token = oauth_authentication(status.account.user)
    return true unless token

    client = twitter_client(token.token, token.token_secret)

    text = status.text
    return true if text =~ /\A@/

    regstr = '(https|http):\/\/' + Regexp.escape(ENV['LOCAL_DOMAIN']) + '\/media\/[a-zA-Z0-9_\-]+'
    text = text.gsub(Regexp.new(regstr), '')
    text = text.strip

    text_len = text.gsub(/(https|http):\/\/[a-zA-Z0-9\-_\.!\*'\(\)\/?#=\+$&,;~]+/,"https://x.xx/0123456789")
    if text_len.length > 140
      text_over = text_len.slice(139..-1)
      text = text.gsub(text_over, '…')
    end

    media_ids = []
    status.media_attachments.each do |media_attachment|
      open(media_attachment.file.path) do |media|
        media_ids << client.upload(media)
      end
    end

    if media_ids.empty?
      client.update(text)
    else
      client.update(text, {media_ids: media_ids.join(',')})
    end

  rescue ActiveRecord::RecordNotFound, Twitter::Error::Unauthorized
    true
  end

  private

  def twitter_client(token, token_secret)    
    Twitter::REST::Client.new do |config|
      config.consumer_key        = Rails.application.secrets[:oauth][:twitter][:key]
      config.consumer_secret     = Rails.application.secrets[:oauth][:twitter][:secret]
      config.access_token        = token
      config.access_token_secret = token_secret
    end
  end

  def oauth_authentication(user)
    user.oauth_authentications.find {|oauth_authentication| oauth_authentication.provider == 'twitter' }
  end
end
