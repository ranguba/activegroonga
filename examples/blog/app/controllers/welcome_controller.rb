class WelcomeController < ApplicationController
  def index
    @posts = Post.all
  end
end
