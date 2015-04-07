class UsersController < ApplicationController
  def auth
    username = params[:username]
    password = params[:password]
    auth_status = User.authenticate(username, password)

    if auth_status
      render json: {auth: true}
    else
      render json: {auth: false}, status: 401
    end
  end
end
