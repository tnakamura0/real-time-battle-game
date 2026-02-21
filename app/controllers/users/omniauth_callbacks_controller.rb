class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # Googleからの直接POSTを許可
  skip_before_action :verify_authenticity_token, only: :google_oauth2

  def google_oauth2
    # IDトークンを検証してペイロードを取得
    payload = Google::Auth::IDTokens.verify_oidc(
      params[:credential],
      aud: Rails.application.credentials.dig(:google, :client_id)
    )

    # OmniAuthが作るデータ構造（AuthHash）を自作して擬似的に再現する
    auth_hash = OmniAuth::AuthHash.new({
      provider: "google_oauth2",
      uid: payload["sub"],
      info: {
        email: payload["email"],
        name: payload["name"],
        image: payload["picture"]
      }
    })
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    @user = User.from_omniauth(auth_hash)

    if @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", kind: "Google"
      sign_in_and_redirect @user, event: :authentication
    else
      # Useful for debugging login failures. Uncomment for development.
      # session['devise.google_data'] = request.env['omniauth.auth'].except('extra') # Removing extra as it can overflow some session stores
      redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
    end
  end
end
