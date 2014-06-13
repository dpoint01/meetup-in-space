class Membership < ActiveRecord::Base
  validates :user_id, presence: true
  validates :meetup_id, presence: true
  validates :role, presence: true
  validates :user_id, uniqueness: {scope: :meetup_id}
  belongs_to :user
  belongs_to :meetup
end
