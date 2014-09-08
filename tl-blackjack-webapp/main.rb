require 'rubygems'
require 'sinatra'
require 'shotgun'
require 'pry'
require 'active_support/core_ext/object/blank'
require 'sinatra/flash'
require_relative 'model/blackjack'

set :sessions, true


helpers do
  def desplay_card(card)
    "<img src='images/cards/#{card.find_suit}_#{card.find_face_value}.jpg' style='margin:0px 5px 5px 0px'/>"
  end



  def declare_winner
    if session[:notice].present?
      "<div class='alert alert-#{session[:notice][:status]}'>#{session[:notice][:msg]}</div>"
    end
  end

      
  def display_player_message(player)
    "#{player.name} has #{player.total}. What would ryan  like to do?
      <small>#{player.name} has <strong>$#{player.money} </strong> total. Bet amount this round: <strong>$#{player.bet}</strong></small>"
  end

     
  def display_player_stay_message(player)
     "<h4>#{player.name} stayed at #{player.total}. #{player.name} has $#{player.money} and bet $#{player.bet} this round.</h4>"
  end
   
  def player_turn(game)
    if game.player.is_blackjack?
      game.player.money += game.player.bet
      session[:player_money] = game.player.money
      session[:player_turn] = false
      session[:notice][:status] = 'info'
      session[:notice][:msg] = "You win. you got blackjack. #{game.player.name} now has #{game.player.money}."
      session[:game_over] = true
    elsif game.player.is_busted?
      game.player.money -= game.player.bet
      session[:player_money] = game.player.money
      session[:player_turn] = false
      session[:notice][:status] = 'error'
      session[:notice][:msg] = "#{game.player.name} loses. It looks like #{game.player.name} busted at #{game.player.total}. #{game.player.name} now has #{game.player.money}."
      session[:game_over] = true
    end
  end

  def deaker_turn(game)
    if game.dealer.is_blackjack? 
      game.player.money -= game.player.bet
      session[:player_money] = game.player.money
      session[:notice][:status] = 'error'
      session[:notice][:msg] = "You lose. Delear got blackjack. #{game.player.name} now has #{game.player.money}."
      session[:dealer_turn] = false
      session[:game_over] = true
    elsif game.dealer.is_busted? 
      game.player.money += game.player.bet  
      session[:player_money] = game.player.money 
      session[:notice][:status] = 'info'
      session[:notice][:msg] = "You win. Delear busted. #{game.player.name} now has #{game.player.money}."
      session[:dealer_turn] = false
      session[:game_over] = true

    elsif game.dealer.over_hit_min?
      if game.player.total > game.dealer.total
        game.player.money += game.player.bet 
        session[:player_money] = game.player.money
        session[:notice][:status] = 'info'
        session[:notice][:msg] = "You win. Dealer has total #{game.dealer.total}. You has total #{game.player.total}. #{game.player.name} now has #{game.player.money}."
      elsif game.player.total < game.dealer.total
        game.player.money -= game.player.bet
        session[:player_money] = game.player.money 
        session[:notice][:status] = 'error' 
        session[:notice][:msg] = "You lose. Dealer has total #{game.dealer.total}. You has total #{game.player.total}. #{game.player.name} now has #{game.player.money}."
      else
        session[:notice][:status] = 'info' 
        session[:notice][:msg] = "It's a tie. #{game.player.name} now has #{game.player.money}."
      end
      session[:dealer_turn] = false
      session[:game_over] = true
    end
  end


end


get '/' do
  if session[:player_name].present?
    redirect '/bet'
  else
    redirect '/new_game'
  end

end

get '/new_game' do
  #@error = "Please input your name. Thanks!" 
  erb :new_game
end

post '/set_name' do
  
  if params[:player_name].present?
    session[:player_name] = params[:player_name]
    session[:player_money] = 500
    redirect '/bet'
  else
    flash[:error] = "Please enter your name. Thanks!"
    redirect '/new_game'
  end
end


get '/game' do

  if session[:game_engine].nil?

    #start a new game
    @game = Blackjack.new(session[:player_name], session[:player_money], session[:bet_amount])
    @game.deal_cards
    session[:game_engine] = @game 
    session[:player_turn] = true
    session[:dealer_turn] = false
    session[:game_over] = false
    session[:notice] = {}
    player_turn(@game)

  else
    #game is exist
    @game = session[:game_engine]

      #player turn
      if session[:player_turn]
        player_turn(@game)

      #dealer turn
      else
        deaker_turn(@game)
      end
  end

  erb :game
end

get '/bet' do
  @player_name = session[:player_name]
  @player_money = session[:player_money]
  session[:game_engine] = nil
  session[:notice] = nil
  erb :bet
end

post '/set_bet_amount' do
     bet_amount = params[:bet_amount].to_i
  if session[:player_money] >= bet_amount
      session[:bet_amount] = bet_amount
      redirect '/game'
  else
    flash[:error] = "Sorry, You don't have enough money"
    redirect '/bet'
  end

end

post '/game/player/hit' do
  @game = session[:game_engine]
  @game.player.add_card(@game.deck.deal_one)
  redirect '/game'
end


post '/game/player/stay' do
  session[:player_turn] = false
  session[:dealer_turn] = true
  redirect '/game'

end


post '/game/dealer/hit' do
  @game = session[:game_engine]
  @game.dealer.add_card(@game.deck.deal_one)
  redirect '/game'
end


get '/game_over' do
  erb :game_over
end




