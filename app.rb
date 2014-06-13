require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/flash'
require 'omniauth-github'
require 'pry'
require_relative 'config/application'

Dir['app/**/*.rb'].each { |file| require_relative file }

helpers do
  def current_user
    user_id = session[:user_id]
    @current_user ||= User.find(user_id) if user_id.present?
  end

  def signed_in?
    current_user.present?
  end
end

def set_current_user(user)
  session[:user_id] = user.id
end

def authenticate!
  unless signed_in?
    flash[:notice] = 'You need to sign in if you want to do that!'
    redirect '/'
  end
end

get '/' do
  @meetups = Meetup.all.order("name ASC")
  @title = "List of All meetups"
  erb :index
end

get '/auth/github/callback' do
  auth = env['omniauth.auth']

  user = User.find_or_create_from_omniauth(auth)
  set_current_user(user)
  flash[:notice] = "You're now signed in as #{user.username}!"

  redirect '/'
end

get '/sign_out' do
  session[:user_id] = nil
  flash[:notice] = "You have been signed out."

  redirect '/'
end

get '/example_protected_page' do
  authenticate!
end

get '/meetups/new' do
  authenticate!
  erb :'meetups/new.html'
end

get '/meetups/:id' do
  user_id = session['user_id']
  binding.pry
  @username = User.where("id = #{user_id}").first.username
  @avatar = User.where("id = #{user_id}").first.avatar_url
  meetup = Meetup.where("id = ?", params[:id]).first
  @meetup_name = meetup.name
  @meetup_description = meetup.description
  @meetup_location = meetup.location
  @meetup_id = meetup.id

  if !Membership.where("meetup_id = #{@meetup_id} AND user_id = #{user_id}").first.nil?
    @joined = true
  else
    @joined = false
  end
  erb :'meetups/show'
end

post '/meetups/join/:id' do
  authenticate!
  meetup_id = params[:id]
  user_id = session['user_id']
  new_membership = Membership.new(user_id: User.find(user_id).id, meetup_id: Meetup.find(meetup_id).id, role: 'member')
  if !new_membership.valid?
    flash[:notice] = "Error: you have already joined this meetup!"
    redirect "/meetups/#{meetup_id}"
  else
    new_membership.save
    flash[:notice] = "You have successfully joined this meetup!"
    redirect "/meetups/#{meetup_id}"

  end

end

post '/meetups' do
  meetup_info = params['meetup']
  meetup = Meetup.new(name: meetup_info['name'], location: meetup_info['location'], description: meetup_info['description'])
  if !meetup.valid?
    flash[:notice] = meetup.errors.messages.inject([]) { |errors, (input, message)| errors << message }.join(";  ")
    redirect '/meetups/new'
  else
    meetup.save
    flash[:notice] = "Your Meetup has been made!"
    redirect "/meetups/#{meetup.id}"
  end
end
