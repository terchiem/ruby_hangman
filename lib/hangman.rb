require 'json'

class WordBank
  def initialize
    fname = "5desk.txt"
    @words = File.open(fname, "r").readlines
              .map(&:chomp)
              .map(&:downcase)
              .select { |line| line.length.between?(5, 12) }
  end

  def get
    @words[rand(@words.length)]
  end
end

class Word
  attr_reader :word, :letters

  def initialize(word, letters = [])
    @word = word
    @letters = letters
    if letters.empty?
      word.each_char {|c| @letters << c unless @letters.include?(c) }
    end
  end

  def display
    @word.each_char do |ch|
      print " #{@letters.include?(ch) ? "_" : ch}"
    end
  end

  def guess?(ch)
    if @letters.include?(ch)
      @letters.delete(ch)
      true
    else
      false
    end
  end

  def win?
    @letters.length == 0 ? true : false
  end

  def to_hash
    { word: @word, letters: @letters }
  end
end

class Game
  def initialize
    @bank = WordBank.new
    @word = Word.new(@bank.get)
    @guesses = []
    @max_guesses = 6
    @num_guesses = 0

    file_name = prompt_load
    load_game(file_name) if file_name
  end

  def start_game
    until game_over?
      display_info

      letter = prompt_letter

      if letter == '5'
        save_game
        return
      else
        correct_guess = @word.guess?(letter)
        unless correct_guess
          @num_guesses += 1
          @guesses << letter
        end
      end
    end

    display_info
    puts @word.win? ? "You win!" : "You ran out of guesses!"

    new_game if new_game?
  end

  def display_info
    puts "\n"
    @word.display
    puts "\n\n"

    unless @guesses.empty?
      print "Incorrect Guesses (Max: #{@max_guesses}):"
      @guesses.each { |ch| print " #{ch}" }
      puts "\n"
    end
  end

  def game_over?
    @num_guesses >= @max_guesses || @word.win?
  end

  def prompt_letter
    while true
      print "Enter a letter (or '5' to save and exit game): "
      input = gets.chomp.downcase
      if input.match?(/^[a-z5]$/)
        return input
      else
        puts "'#{input}' is an invalid entry"
      end
    end
  end

  def prompt_load
    flist = Dir['saves/*.txt'].sort
    unless flist.empty?
      puts "Save files found:"
      flist.each_with_index { |f, i| puts "[#{i}] #{f}" }

      while true
        print "Select a file to load (or 'x' to skip): "
        input = gets.chomp.downcase
        if input.match?(/^x$/)
          return false
        elsif input.match?(/^\d+$/)
          index = input.to_i
          return flist[index] if index.between?(0, flist.length-1)
        end
        puts "'#{input}' is an invalid entry"
      end
    end
  end

  def save_game
    Dir.mkdir('saves') unless File.exists?('saves')
    date = Time.now.strftime("%Y-%m-%d-%H%M%S")
    save_file = "saves/#{date}.txt"
    state = {
      word: @word.word,
      letters: @word.letters,
      guesses: @guesses,
      num_guesses: @num_guesses
    }
    File.open(save_file, 'w'){ |f| f.write(state.to_json) }
    puts "File saved to '#{save_file}'"
  end

  def load_game(fname)
    puts "Loading '#{fname}'"
    fdata = File.open(fname, 'r'){ |f| f.readline }
    state = JSON.parse(fdata)
    if state.has_key?("word") && state.has_key?("letters")
      @word = Word.new(state["word"], state["letters"])
      @guesses = state["guesses"]
      @num_guesses = state["num_guesses"]
    else
      puts "Error opening save file\n"
    end
  end

  def new_game?
    print "Play again? (y/n): "
    while true
      input = gets.chomp.downcase
      if input.match?(/^[yn]$/)
        return input == "y" ? true : false
      end
      puts "'#{input}' is an invalid entry"
    end
  end

  def new_game
    @word = Word.new(@bank.get)
    @num_guesses = 0
    @guesses.clear
    start_game
  end
end

game = Game.new
game.start_game