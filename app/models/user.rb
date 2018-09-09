class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  validates_presence_of :first_name, :last_name
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :hardware_checkouts, dependent: :destroy
  has_many :hardware_items, through: :hardware_checkouts
  has_one :event_application, dependent: :destroy
  has_one :mentorship_request, dependent: :destroy

  after_create :welcome_email

  # needed for slack integration
  require "net/http"
  require "uri"

  # slack workspace token for HackUMass VI
  $workspace_token = ***REMOVED***

  # Use type checkers
  def is_attendee?
  	user_type == 'attendee'
  end

  def is_admin?
  	user_type == 'admin'
  end

  def is_mentor?
  	user_type == 'mentor'
  end

  def is_organizer?
    user_type == 'organizer'
  end

  def full_name
    names = []
    names << first_name if first_name
    names << last_name if last_name
    names.join ' '
  end

  def has_applied?
    self.event_application.present?
  end

  def has_mentorship_requests?
    self.mentorship_request.present?
  end

  def is_accepted?
    if has_applied?
      self.event_application.application_status == 'accepted'
    end
  end

  def welcome_email
    UserMailer.welcome_email(self).deliver_now
  end



  def has_slack?
    url = URI("https://slack.com/api/users.lookupByEmail?token=" + $workspace_token + "&email=" + self.email)

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    req = Net::HTTP::Get.new(url)

    res = http.request(req)
    JSON.parse(res.body)["ok"]
  end

  def get_slack_username
    url = URI("https://slack.com/api/users.lookupByEmail?token=" + $workspace_token + "&email=" + self.email)

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    req = Net::HTTP::Get.new(url)

    res = JSON.parse(http.request(req).body)
    if res["ok"]
      return JSON.parse(res.body)["user"]["name"]
    else
      return false
    end
  end

  def get_slack_id
    url = URI("https://slack.com/api/users.lookupByEmail?token=" + $workspace_token + "&email=" + self.email)

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    req = Net::HTTP::Get.new(url)

    res = JSON.parse(http.request(req).body)
    if res["ok"]
      return JSON.parse(res.body)["user"]["id"]
    else
      return false
    end
  end


end
