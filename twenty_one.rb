require 'yaml'

MESSAGES = YAML.load_file("game_messages.yml")

module Clearable
  def clear
    system('clear') || system('cls')
  end
end

module Interruptable
  def type_to_continue
    puts
    puts "Press enter to continue".center(80)
    gets
  end

  def display_pending
    2.times do
      print '.'
      sleep(0.6)
    end
    puts '.'
    sleep(1)
  end
end

module Centerable
  def center_cursor
    print " " * 38
  end
end

module EasilyEnterable
  def find_full_length(char, options)
    options.find { |option| option.start_with?(char) }
  end
end

### Twenty-One Orchestration Class
class TOGame
  POINT_LIMIT = 21
  GAME_MESSAGES = MESSAGES['TOGame_messages']

  include Clearable, Interruptable, Centerable, EasilyEnterable

  attr_reader :human, :dealer, :table_displayer

  def initialize
    @human = Player.new
    @dealer = Dealer.new
    @table_displayer = TableDisplayer.new(human, dealer)
    @rules = Rules.new
  end

  def play
    display_welcome_message
    @rules.run_rules_loop
    game_loop
    display_goodbye_message
  end

  private

  def game_loop
    loop do
      loop do
        execute_round
        break if dealer.deck.been_cycled?
      end
      close_out_game
      break unless play_again?
      reset_game
      display_play_again_message
    end
  end

  def execute_round
    deal_cards
    human_turn
    dealer_turn unless human.bust?
    winner = find_winner
    display_result(winner)
    update_wins(winner)
    update_table
  end

  def deal_cards
    2.times do
      dealer.deal_card_to(human)
      dealer.deal_card_to(dealer)
    end
    dealer.hide_first_card
  end

  def human_turn
    table_displayer.display_table
    choice = hit_stay_or_card_count
    case choice
    when 'stay'       then display_stay_message(human)
    when 'card count' then card_count_table_sequence && human_turn
    when 'hit'
      dealer.deal_card_to(human)
      display_hit_message(human)
      human.bust? ? bust_display_sequence(human) : human_turn
    end
  end

  def hit_stay_or_card_count
    valid_inputs = ['h', 'hit', 's', 'stay', 'c', 'card', 'card count']

    choice = nil
    loop do
      puts GAME_MESSAGES['choice_prompt']
      center_cursor
      choice = gets.chomp.downcase
      break if valid_inputs.include?(choice)
      puts GAME_MESSAGES['choice_invalid_input']
    end
    find_full_length(choice, ['hit', 'stay', 'card count'])
  end

  def card_count_table_sequence
    data, mystery_cards = card_count_data
    table_displayer.display_card_count_table(data, mystery_cards)
  end

  def card_count_data
    known_card_attributes = find_known_card_attributes
    card_count_data = instantiate_card_count_data(known_card_attributes)
    mystery_cards = number_of_mystery_cards(known_card_attributes)
    [card_count_data, mystery_cards]
  end

  def find_known_card_attributes
    find_discarded_card_attributes + find_player_hand_attributes
  end

  def find_discarded_card_attributes
    dealer.discard_pile.map { |card| [card.value, card.suit] }
  end

  def find_player_hand_attributes
    [human.hand, dealer.hand].each_with_object([]) do |hand, obj|
      obj.push(*hand.map { |card| [card.value, card.suit] })
    end
  end

  def instantiate_card_count_data(known_card_attributes)
    card_count_data = {}

    Deck::VALUES.each do |rank|
      card_count_data[rank] = {}
      Deck::SUITS.each do |suit|
        known_card = known_card_attributes.include? [rank, suit]
        card_count_data[rank][suit] = (known_card ? '✔' : ' ')
      end
    end

    card_count_data
  end

  def number_of_mystery_cards(known_card_attributes)
    known_card_attributes.count { |card| card.first == '?' }
  end

  def bust_display_sequence(player)
    table_displayer.display_table
    display_bust_message(player)
  end

  def dealer_turn
    dealer_reveal_sequence
    loop do
      break if dealer.hand_value >= 17
      dealer.deal_card_to(dealer)
      display_hit_message(dealer)
      break if dealer.bust?
      table_displayer.display_table
      type_to_continue
    end
    close_out_dealer_turn
  end

  def dealer_reveal_sequence
    dealer.reveal_first_card
    table_displayer.display_table
  end

  def close_out_dealer_turn
    dealer.bust? ? bust_display_sequence(dealer) : display_stay_message(dealer)
  end

  def find_winner
    return dealer if human.bust?
    return human if dealer.bust?

    case human.hand_value <=> dealer.hand_value
    when 1  then human
    when -1 then dealer
    when 0  then :tie
    end
  end

  def update_wins(winner)
    case winner
    when human  then human.wins += 1
    when dealer then dealer.wins += 1
    end
  end

  def update_table
    discard_cards
    return if find_grand_winner
    table_displayer.showdown = true if dealer.deck.been_cycled?
  end

  def discard_cards
    dealer.discard_hand_of(human)
    dealer.discard_hand_of(dealer)
  end

  def close_out_game
    until find_grand_winner
      execute_round
    end
    grand_winner_display_sequence
  end

  def find_grand_winner
    return human  if human.wins > dealer.wins + 1
    return dealer if dealer.wins > human.wins + 1
    nil
  end

  def grand_winner_display_sequence
    grand_winner = find_grand_winner
    display_grand_winner_buffer(grand_winner)
    40.times do
      print_name_to_screen_width(grand_winner)
    end
    sleep(3)
    clear
  end

  def play_again?
    choice = nil
    loop do
      puts GAME_MESSAGES['play_again_prompt']
      center_cursor
      choice = gets.chomp.downcase
      break if %w(yes y no n).include?(choice)
      puts GAME_MESSAGES['play_again_invalid_input']
    end
    choice.start_with?('y')
  end

  def reset_game
    discard_cards
    human.wins = 0
    dealer.wins = 0
    dealer.prepare_deck
    table_displayer.showdown = false
  end

  ### TOGame Displaying Methods
  def display_welcome_message
    clear
    puts GAME_MESSAGES['welcome_message']
    sleep(1.5)
  end

  def display_goodbye_message
    clear
    puts GAME_MESSAGES['goodbye_message']
    sleep(1.5)
  end

  def display_play_again_message
    clear
    puts GAME_MESSAGES['play_again']
    sleep(1.5)
  end

  def display_stay_message(player)
    case player
    when human
      puts GAME_MESSAGES['stay_message']['human']
    when dealer
      puts GAME_MESSAGES['stay_message']['dealer']
    end
    sleep(1.5)
  end

  def display_hit_message(player)
    case player
    when human
      puts GAME_MESSAGES['hit_message']['human']
    when dealer
      puts GAME_MESSAGES['hit_message']['dealer']
    end
    sleep(1.5)
  end

  def display_bust_message(player)
    message =  case player
               when human  then "You "
               when dealer then "The dealer "
               end
    message << "went bust with a total of #{player.hand_value} points!"
    puts message.center(80)
    sleep(1.5)
  end

  def display_result(winner)
    table_displayer.display_table
    puts case winner
         when human  then GAME_MESSAGES['result_message']['human_win']
         when dealer then GAME_MESSAGES['result_message']['dealer_win']
         when :tie   then GAME_MESSAGES['result_message']['tie']
         end
    sleep(1)
    type_to_continue
  end

  def display_grand_winner_buffer(grand_winner)
    clear
    print "With a GRAND total of #{grand_winner.wins} wins"
    display_pending
    print GAME_MESSAGES['grand_winner_announcer']
    display_pending
    clear
  end

  def print_name_to_screen_width(grand_winner)
    formatted_name = grand_winner.name.upcase + ' '
    times_to_print = 80 / formatted_name.length
    (times_to_print - 1).times do
      print formatted_name
      sleep(0.002)
    end
    puts formatted_name
  end
end

### General player attributes, behaviours to show the value of the player's
### hand, and to check to see whether they've gone bust
class Player
  attr_accessor :hand, :wins
  attr_reader :name

  include Clearable, Centerable

  def initialize
    @hand = []
    @wins = 0
    @name = set_name
  end

  def hand_value
    points = hand.sum(&:point_value)
    number_of_aces = hand.count { |card| card.value == "Ace" }
    number_of_aces.times do
      break if points <= TOGame::POINT_LIMIT
      points -= 10
    end
    points
  end

  def bust?
    hand_value > TOGame::POINT_LIMIT
  end

  private

  def set_name
    clear
    n = ""
    loop do
      puts MESSAGES['human_messages']['name_prompt']
      center_cursor
      n = gets.chomp
      break if (1..9).include?(n.size)
      puts MESSAGES['human_messages']['name_invalid_input']
    end
    @name = n
  end
end

### Subclass of player with additional responsibilities associated with
### dealing, discarding, and hiding / revealing their first card
class Dealer < Player
  attr_reader :deck

  def initialize
    super
    prepare_deck
  end

  def prepare_deck
    @deck = Deck.new
  end

  def discard_pile
    deck.discard_pile
  end

  def deal_card_to(player)
    reshuffle_deck if deck.empty?
    player.hand << deck.pop
  end

  def discard_hand_of(player)
    discard_pile.push(*player.hand)
    player.hand = []
  end

  def hide_first_card
    hand[0].hide
  end

  def reveal_first_card
    hand[0].reveal
  end

  private

  def set_name
    @name = 'Dealer'
  end

  def reshuffle_deck
    deck.shuffle_discards_back_in
  end
end

class Deck
  VALUES = %w(Ace King Queen Jack 10 9 8 7 6 5 4 3 2)
  SUITS = %w(spades diamonds clubs hearts)

  attr_reader :stack_order, :discard_pile

  def initialize
    @stack_order = default_shuffled_deck
    @cycled = false
    @discard_pile = []
  end

  def size
    stack_order.size
  end

  def empty?
    stack_order.empty?
  end

  def pop
    stack_order.pop
  end

  def been_cycled?
    @cycled
  end

  def shuffle_discards_back_in
    @stack_order = @discard_pile.map do |card|
      card.reveal
      card
    end.shuffle
    @discard_pile = []
    @cycled = true
  end

  private

  def default_shuffled_deck
    VALUES.map do |value|
      SUITS.map do |suit|
        Card.new(value, suit)
      end
    end.flatten.shuffle
  end
end

class Card
  def initialize(value, suit)
    @value = value
    @suit = suit
    @hidden = false
  end

  def value
    if @hidden
      '?'
    else
      @value
    end
  end

  def suit
    if @hidden
      'unknown'
    else
      @suit
    end
  end

  def point_value
    if ('2'..'10').include?(value)
      value.to_i
    elsif %w(Jack Queen King).include?(value)
      10
    elsif value == "Ace"
      11
    else
      0
    end
  end

  def hide
    @hidden = true
  end

  def reveal
    @hidden = false
  end
end

### Responsible for displaying the "table" (hands of both users), as well as
### displaying the card counting table.
class TableDisplayer
  TABLE_DISPLAY_STRINGS = MESSAGES['table_display_strings']

  include Clearable, Interruptable

  def initialize(human, dealer)
    @human  = human
    @dealer = dealer
    @showdown = false
  end

  attr_writer :showdown

  def display_table
    clear
    display_title(dealer)
    display_hand(dealer.hand)
    display_middle_banner
    display_title(human)
    display_hand(human.hand)
    puts
    sleep(1)
  end

  def display_card_count_table(data, mystery_cards)
    clear
    1.upto(8) do |line|
      puts TABLE_DISPLAY_STRINGS['card_count_header_lines'][line]
    end
    display_card_count(data)
    display_mystery_cards_cell(mystery_cards)
    puts TABLE_DISPLAY_STRINGS['card_count_footer']
    type_to_continue
  end

  private

  attr_reader :human, :dealer

  def display_title(player)
    puts " #{player.name} ".center(15, '/')
    puts
    puts "=> WINS: #{player.wins}"
    puts "=> HAND VALUE: #{player.hand_value}"
  end

  def display_hand(hand)
    top_row, bottom_row = hand.partition.with_index { |_, i| i < 5 }
    display_card_row(top_row)
    display_card_row(bottom_row) unless bottom_row.empty?
  end

  def display_card_row(row)
    number_of_cards = row.size
    display_card_headers(number_of_cards)
    display_card_values(row, :head)
    display_card_suits(row)
    display_card_values(row, :foot)
    display_card_footers(number_of_cards)
  end

  def display_card_headers(number_of_cards)
    full_line = ([TABLE_DISPLAY_STRINGS['card_header']] * number_of_cards)
    full_line = full_line.join(' ')
    puts full_line
  end

  def display_card_values(row, position)
    if position == :head
      full_line = row.map do |card|
        "| #{card.value.ljust(12)}|"
      end.join(' ')
    elsif position == :foot
      full_line = row.map do |card|
        "|#{card.value.rjust(12)} |"
      end.join(' ')
    end
    puts full_line
  end

  def display_card_suits(row)
    1.upto(9) do |line|
      full_line = row.map { |card| TABLE_DISPLAY_STRINGS[card.suit][line] }
      full_line = full_line.join(' ')
      puts full_line
    end
  end

  def display_card_footers(number_of_cards)
    full_line = ([TABLE_DISPLAY_STRINGS['card_footer']] * number_of_cards)
    full_line = full_line.join(' ')
    puts full_line
  end

  def display_middle_banner
    puts "\n\n\n"

    if @showdown
      display_showdown_banner
    elsif dealer.deck.been_cycled?
      display_cycled_deck_banner
    else
      display_deck_size_banner
    end

    puts "\n\n\n"
  end

  def display_deck_size_banner
    cards_remaining = ("▤" * dealer.deck.size)
    cards_remaining << " #{dealer.deck.size} cards left "
    cards_remaining = cards_remaining.ljust(67, "□")
    puts cards_remaining
  end

  def display_cycled_deck_banner
    puts TABLE_DISPLAY_STRINGS['cycled_deck_banner']
  end

  def display_showdown_banner
    puts (("FINAL___SHOWDOWN____" * 4).chars.rotate(rand(20))).join
  end

  def display_card_count(data)
    data.each do |rank, _|
      total_still_in_deck = data[rank].count { |_, status| status == ' ' }
      line = ''
      line << rank.rjust(8) + '|'
      data[rank].each { |_, status| line << " #{status} |" }
      line << (('꩜ ' * total_still_in_deck).ljust(9) + '|')
      puts line.rjust(53)
    end
  end

  def display_mystery_cards_cell(mystery_cards)
    puts "         ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾|#{mystery_cards.to_s.center(9)}"\
         "| << \# of Mystery Cards".rjust(75)
  end
end

### Responsible for displaying rules to the user at the beginning of execution
class Rules
  include Clearable, Interruptable, EasilyEnterable

  RULES = MESSAGES['rule_messages']

  def initialize
    @rules_prompt_grammar = 'the'
  end

  # rubocop:disable Metrics/MethodLength
  def run_rules_loop
    while open_rules?
      display_rules_menu
      user_input = retrieve_rules_menu_input
      case user_input
      when 'Introduction' then display_introduction_messages
      when 'Gameplay'     then display_gameplay_messages
      when 'Card Values'  then display_card_values_messages
      when 'Strategy'     then display_strategy_messages
      when 'Return'       then break
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  private

  def open_rules?
    answer = nil
    loop do
      puts "Would you like to take a look at #{@rules_prompt_grammar} "\
           "rules? (y/n)".center(80)
      answer = gets.chomp.downcase
      break if %w(yes no y n).include?(answer)
      puts RULES["open_rules_invalid_input"]
    end
    @rules_prompt_grammar = 'any other'
    answer.start_with?('y')
  end

  def display_rules_menu
    clear
    puts RULES["display_menu"]
  end

  def retrieve_rules_menu_input
    options = ['Introduction', 'Gameplay', 'Card Values', 'Strategy', 'Return']
    choice = nil
    loop do
      choice = gets.chomp.upcase
      break if %w(I G C S R).include?(choice)
      puts RULES["rules_menu_invalid_input"]
    end
    find_full_length(choice, options)
  end

  def display_introduction_messages
    clear
    print_message_sequence('introduction_messages')
  end

  def display_gameplay_messages
    clear
    print_message_sequence('gameplay_messages', print_speed: :fast)
  end

  def display_card_values_messages
    clear
    print_message_sequence('card_values_messages', print_speed: :turbo)
  end

  def display_strategy_messages
    clear
    print_message_sequence('strategy_messages')
    clear
    print_message_sequence('dealer_advantage_messages')
    clear
    print_message_sequence('how_to_win_messages')
    clear
    print_message_sequence('deck_weighting_messages')
  end

  def print_message_sequence(rule_type, print_speed: :regular)
    sleep_duration = find_intermessage_sleep_duration(print_speed)
    amount_of_messages = RULES[rule_type].size
    puts RULES[rule_type][1]
    sleep(1)
    2.upto(amount_of_messages) do |number|
      puts RULES[rule_type][number]
      sleep(sleep_duration)
    end
    type_to_continue
  end

  def find_intermessage_sleep_duration(print_speed)
    case print_speed
    when :regular then 4
    when :fast    then 2
    when :turbo   then 0.05
    end
  end
end

TOGame.new.play
