=begin

TOGame
----------------
human
dealer
table_displayer

play

private
=-=-=-=

(play)
- game_loop
  > execute_round
    * deal_cards
    * human_turn
      • hit_stay_or_card_count
        ... ### Cut to `hit_stay_or_card_count` helper methods

(hit_stay_or_card_count)
- card_count_table_sequence
  > card_count_data
    * find_known_card_attributes
      • find_discarded_card_attributes
      • find_player_hand_attributes
    * instantiate_card_count_data
    * number_of_mystery_cards
- bust_display_sequence

        ... ### Back to `execute_round` helper methods
    * dealer_turn
      • dealer_reveal_sequence
      • close_out_dealer_turn
    * find_winner
    * update_wins
    * update_table
      • discard_cards
    * close_out_game
      • find_grand_winner
      • grand_winner_display_sequence
  > play_again?
  > reset_game

display_welcome_message
display_goodbye_message
display_play_again_message
display_stay_message
display_hit_message
display_bust_message
display_result
display_grand_winner_buffer
print_name_to_screen_width



Player
----------------
hand
hand=
wins
wins=
name

hand_value
bust?

private
=-=-=-=
set_name



Dealer
----------------
deck

prepare_deck
discard_pile

deal_card_to
discard_hand_of

hide_first_card
reveal_first_card

private
=-=-=-=
set_name
reshuffle_deck



Deck
----------------
stack_order
discard_pile

size
empty?
pop

been_cycled?
shuffle_discards_back_in

private
=-=-=-=
default_shuffled_deck



Card
----------------
value
suit

point_value

hide
reveal



TableDisplayer
----------------
showdown=

display_table
display_card_count_table

private
=-=-=-=

human
dealer

(display_table)
- display_title
- display_hand
  > display_card_row
    * display_card_headers
    * display_card_values
    * display_card_suits
    * display_card_footers
- display_middle_banner
  > display_deck_size_banner
  > display_cycled_deck_banner
  > display_showdown_banner

(display_card_count_table)
- display_card_count
- display_mystery_cards_cell



Rules
----------------
run_rules_loop

private
=-=-=-=
- open_rules?
  > display_rules_menu
  > retrieve_rules_menu_input
  > display_introduction_messages
  > display_gameplay_messages
  > display_card_values_messages
  > display_strategy_messages
    * print_message_sequence
      ~ find_intermessage_sleep_duration

=end