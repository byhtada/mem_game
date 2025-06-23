class ApplicationController < ActionController::API
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    include ActionController::HttpAuthentication::Token::ControllerMethods
  
    puts "APPLICATION_CONTROLLER"
    before_action :authenticate_user_from_token, except: [:health, :telegram_callback, :test_telegram, :set_webhook, :index]
  
    TELEGRAM_BOT_TOKEN = '8198065333:AAEaS26LaEq5kVoM1moxvvmuNI22tNEC_cM'


    @@avatars = [
      1,2,10,11,13,15,17,20,29,32,37,42,43,50,51,
      54,57,62,70,75,
      77,85,88,105,114
     ]

    def index
      # Обслуживание фронтенда SPA
      render file: Rails.public_path.join('index.html'), layout: false
    end

    def get_payment_link
      params = { 
        title: "Premium", 
        description: "Премиум аккаунт в MemCulture",
        payload: @user.id,
        currency: 'XTR',
        prices: [{label: 'Цена', amount: 1}]
      }

      response = telegram_request("createInvoiceLink", params)

      render json: {link: response["result"] }
    end

    def set_webhook
      params = { 
        url: "https://memgame-api.fly.dev/telegram_callback"
      }

      response =  telegram_request("setWebhook", params)
      render json: {link: response["result"] }
    end

    def telegram_callback
      puts "payment_callback123 #{params}"
      #@user.update(premium: true)
      if params.dig(:pre_checkout_query, :id)
        telegram_request("answerPreCheckoutQuery", {ok: true, pre_checkout_query_id: params[:pre_checkout_query][:id]})
      end

      if params.dig(:message, :successful_payment, :invoice_payload)
        user_id = params.dig(:message, :successful_payment, :invoice_payload)
        User.find(user_id).update(premium: true, energy_max: 750)
      end

      if params.dig(:message, :text)&.include?('/start')
        user = User.find_by(tg_id: params["message"]["from"]["id"])
        unless user.present?
          user = User.create(tg_id: params["message"]["from"]["id"], name: params["message"]["from"]["username"], ava: @@avatars.sample)

          inviter_info = params["message"]["text"].split('/start ')[1]
          set_inviter(inviter_info, user)
        end
      end

      if params.dig(:message, :text)&.include?('/start')
        data = {
          chat_id: params["message"]["from"]["id"],
          photo: 'AgACAgIAAxkBAANAZ3_jgz0H-zGrHw2RsCcF-neW6tcAAsboMRsmkwABSOKlMcVaJl12AQADAgADeAADNgQ',
          caption: "MemCulture - новый шаг в развитии крипто-проектов.

В отличии от \"кликеров\" и \"хэшей\" взаимодействие пользователя с проектом создает реальную ценность - BigData о взаимодействии людей с мем-культурой

В этих данных заинтересованны большие компании и корпорации для выстраивания своих маркетинговых компаний и они готовы за них платить

Таким образом, MemCulture посредник между теми кто создает BigData и теми, кто её использует. Мы создали win-win-win бизнес-модель. Подробнее в приложении https://t.me/mem_culture_bot/start"
        }
        telegram_request("sendPhoto", data)
      end

      render json: {status: 'ok'}, status: :ok
    end

    def set_inviter(info, user)
      return unless info

      channel = info.split("_")[0]
      inviter_id = info.split("_")[1]

      case channel
      when 'in'
        inviter = User.find_by(tg_id: inviter_id)

        UserFriend.create(user_id: inviter.id, friend_id: user.id)

        inviter.update(coins: inviter.coins + 500)
        user.update(coins: user.coins + 500, source_channel: channel, source_id: inviter_id)
      when 'tg'
        user.update(source_channel: channel, source_id: inviter_id)
      end
    end

    def create_tg_message
      text = "Давай вместе майнить $MEMC в MemCulture

В отличии от кликеров и игровых хэшей, токены $MEMC имеют реальную ценность, которую создают пользователи проекта взаимодействуя с интерфесом проекта MemCulture

По моей ссылке ты получишь +500 $MEMC

https://t.me/mem_culture_bot?start=in_#{@user.tg_id}"

      data =  {
        type: 'article', 
        id: @user.tg_id,
        title: 'Share message',
        input_message_content: {message_text: text}}

      responce = telegram_request('savePreparedInlineMessage', {user_id: @user.tg_id, allow_user_chats: true, result: data})

      render json: {message: responce}
    end

    def test_telegram
      data = {
        chat_id: 317600571,
        photo: 'AgACAgIAAxkBAANAZ3_jgz0H-zGrHw2RsCcF-neW6tcAAsboMRsmkwABSOKlMcVaJl12AQADAgADeAADNgQ',
        caption: "MemCulture - новый шаг в развитии крипто-проектов.

В отличии от \"кликеров\" и \"хэшей\" взаимодействие пользователя с проектом создает реальную ценность - BigData о взаимодействии людей с мем-культурой

В этих данных заинтересованны большие компании и корпорации для выстраивания своих маркетинговых компаний и они готовы за них платить

Таким образом MemCulture посредник между теми, кто создает BigData и теми, кто её использует. Мы создали win-win-win бизнес-модель. Подробнее в приложении https://t.me/mem_culture_bot/start"
       
      }
      responce = telegram_request("sendPhoto", data)

      render json: {responce: }
    end


    def health
      render json: { 
        status: 'ok', 
        timestamp: Time.current.iso8601,
        version: Rails.application.class.module_parent_name,
        database: database_status,
        redis: redis_status
      }
    end

    private

    def telegram_request(method, params)
      bot_token = TELEGRAM_BOT_TOKEN
      link = "https://api.telegram.org/bot#{bot_token}/#{method}"

      url = URI(link)

      headers = { 'Content-Type': 'application/json' }
      response = Net::HTTP.post(url, params.to_json, headers)
      JSON.load(response.body)
    end
 
    def parse_init_data(init_data)
      query = URI.decode_www_form(init_data).to_h

      hash = query.delete('hash')

      sorted_entries = query.sort
      data_check_string = sorted_entries.map { |key, value| "#{key}=#{value}" }.join("\n")

      { hash: hash, data_check_string: data_check_string }
    end

    def check_signature(init_data)
      bot_token = TELEGRAM_BOT_TOKEN
      parsed_data = parse_init_data(init_data)
      hash = parsed_data[:hash]
      data_check_string = parsed_data[:data_check_string]

      secret_key = OpenSSL::HMAC.digest('sha256', 'WebAppData', bot_token)
      key = OpenSSL::HMAC.hexdigest('sha256', secret_key, data_check_string)

      key == hash
    end


    
    def authenticate_user_from_token
      puts "HELLO"
      puts "authenticate_user_from_token #{ TELEGRAM_BOT_TOKEN }"

      data = request.headers['TelegramData']

      if check_signature(data)
        user_data = URI.decode_www_form(data).to_h['user']
        user_tg_id = JSON.parse(CGI.unescape(user_data))["id"]

        @user = User.find_by(tg_id: user_tg_id)

        unless @user.present?
          render json: { error: 'Bad Token'}, status: 401
        end
      else
        render json: { error: 'Bad Token'}, status: 401
      end
    end



    def database_status
      ActiveRecord::Base.connection.execute('SELECT 1')
      'connected'
    rescue StandardError
      'disconnected'
    end

    def redis_status
      Sidekiq.redis(&:ping)
      'connected'
    rescue StandardError
      'disconnected'
    end
end
