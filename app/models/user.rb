require "open-uri" # URLを開くために必要

class User < ApplicationRecord
  has_one_attached :image
  has_one :owned_room, class_name: "Room", foreign_key: "owner_id", dependent: :destroy
  has_many :player_1_matches, class_name: "Match", foreign_key: "player_1_id", dependent: :nullify
  has_many :player_2_matches, class_name: "Match", foreign_key: "player_2_id", dependent: :nullify

  # Deviseの設定の前にnameカラムのバリデーションを書くとバリデーションエラーの際に上に表示される
  validates :name, presence: true, length: { maximum: 20 }

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  def self.from_omniauth(access_token)
    data = access_token.info
    user = User.where(email: data["email"]).first

    unless user
      user = User.new(
        name: data["name"],
        email: data["email"],
        password: Devise.friendly_token[0, 20]
      )

      # 画像URLがある場合、ダウンロードしてアタッチする
      if data["image"].present?
        begin
          file = URI.open(data["image"])
          user.image.attach(
            io: file,
            filename: "user_#{Time.current.to_i}.jpg",
            content_type: "image/jpg"
          )
        rescue => e
          logger.error "Failed to attach image from Google: #{e.message}"
        end
      end

      user.save
    end
    user
  end
end
