# == Schema Information
# Schema version: 20101215230231
#
# Table name: cards
#
#  id           :integer         not null, primary key
#  code         :string(255)
#  name         :string(255)
#  cardset_id   :integer
#  rarity       :string(255)
#  cost         :string(255)
#  supertype    :string(255)
#  cardtype     :string(255)
#  subtype      :string(255)
#  rulestext    :text
#  flavourtext  :text
#  power        :string(255)
#  toughness    :string(255)
#  image        :string(255)
#  active       :boolean
#  created_at   :datetime
#  updated_at   :datetime
#  frame        :string(255)
#  art_url      :string(255)
#  artist       :string(255)
#  image_url    :string(255)
#  last_edit_by :integer
#

class Card < ActiveRecord::Base
  belongs_to :cardset
  has_many :comments, :dependent => :destroy
  has_many :old_cards, :dependent => :destroy
  attr_accessor :foil, :blank  # not saved

  # has_many :highlighted_comments, :class_name => 'Comment', :conditions => ['status = ?', COMMENT_HIGHLIGHTED]
  # has_many :unaddressed_comments, :class_name => 'Comment', :conditions => ['status = ?', COMMENT_UNADDRESSED]

  before_create :regularise_fields
  # after_save do  - Can't do this, as we don't have access to session methods in model callbacks :/
  #   set_last_edit(self)
  # end

  DEFAULT_RARITY = "common"
  STRING_FIELDS = ["name","cost","supertype","cardtype","subtype","rarity","rulestext","flavourtext","code","frame","art_url","artist","image_url"]
  LONG_TEXT_FIELDS = ["rulestext", "flavourtext"]
  (STRING_FIELDS-LONG_TEXT_FIELDS).each do |field|
    validates field.to_sym, :length     => { :maximum => 255 }
  end
  # Ensure code is either blank or unique within cardset
  validates_uniqueness_of :code, :scope => [:cardset_id], :allow_blank => true
  
  def regularise_fields
    # Enforce rarity; Default rarity to common
    if (self.rarity.blank?) || !Card.rarities.include?(self.rarity)
      self.rarity = DEFAULT_RARITY
    end
    # Strip whitespace
    STRING_FIELDS.each do |field|
      if self.attributes[field]
        self.attributes[field].strip!
      end
    end
  end

  def formatted_rules_text
    format_card_text(rulestext)
  end
  def formatted_flavour_text
    format_card_text(flavourtext)
  end

  def printable_name
    case
      when !name.blank?
        name
      when !code.blank?
        code
      else
        "Card#{id}"
    end
  end
  
  def recency  # For a card, its order in recency is when it was updated
    updated_at
  end
  
  def get_history
    possible_logs = Log.find(:all, :conditions => {:object_id => id})
    my_logs = possible_logs.select{|l| l.return_object == self}
    logs_to_not_show = Log.kinds_to_not_show(:card_history)
    my_logs.reject!{|l| logs_to_not_show.include? l.kind}
    out = (comments + my_logs).sort_by &:recency
  end

  def self.colours
    ["White", "Blue", "Black", "Red", "Green"]
  end

  COLOUR_PAIRS = Card.colours.combination(2).to_a
  def self.colour_pairs
    COLOUR_PAIRS
  end
  
  DISPLAY_FRAMES = 
    Card.colours + ["Artifact", "Multicolour", "Colourless"] +
    Card.colour_pairs.map { |pair| "Hybrid #{pair.join('-').downcase}" } +
    ["Land (colourless)"] +
    Card.colours.map { |col| "Land (#{col.downcase})" } +
    Card.colour_pairs.map { |pair| "Land (#{pair.join('-').downcase})" } +
    ["Land (multicolour)"]
  def self.display_frames
    DISPLAY_FRAMES
  end
  FRAMES = DISPLAY_FRAMES.map { |f| f.gsub(/[()-]/,'') }
  def self.frames
    FRAMES
  end

  def self.rarities
    %w{common uncommon rare mythic basic token}
  end
  def self.supertypes
    %w{Legendary Basic World Snow}
  end
  def self.category_order
    %w{Colourless White Blue Black Red Green Multicolour Hybrid Artifact Land}
  end
  def self.frame_code_letters
    %w{C W U B R G M Z H A L}
  end
  
  colour_letters = %w{W U B R G}
  mana_symbols = []
  # First the misformed ones
  mana_symbols += colour_letters.map {|s| "{2/#{s}}" }
  mana_symbols += colour_letters.map {|s| "{3/#{s}}" }
  mana_symbols += (0..4).map do |i1|
    i1a = (i1+3).modulo(5)
    i1b = (i1+4).modulo(5)
    ["{#{colour_letters[i1]}/#{colour_letters[i1a]}}", "{#{colour_letters[i1]}/#{colour_letters[i1b]}}"]
  end.flatten
  mana_symbols  += (0..4).map do |i1|
    i1a = (i1+1).modulo(5)
    i1b = (i1+2).modulo(5)
    ["{#{colour_letters[i1]}/#{colour_letters[i1a]}}", "{#{colour_letters[i1]}/#{colour_letters[i1b]}}"]
  end.flatten
  mana_symbols += colour_letters.map {|s| "{#{s}/2}" }
  mana_symbols += colour_letters.map {|s| "{#{s}/3}" }
  mana_symbols += ( colour_letters + %w{1000000 100 10 11 12 13 14 15 16 17 18 19 20 -3 1 2 3 4 5 6 7 8 9 0 X Y T Q S C} ) .map {|s| "{#{s}}" }
  MANA_SYMBOLS = mana_symbols
    
  def self.mana_symbols_extensive
    MANA_SYMBOLS
  end
  
  # [CURMBT][CWUBRGMZHSAL]\d\d
  rarity_pattern = Card.rarities.reduce("["){ |m,r| m << r.upcase[0] }+"]"
  colour_codes_pattern = "[CWUBRGMZHSAL]"
  code_numbers_pattern = "[0-9][0-9]"
  regexp_string = rarity_pattern + colour_codes_pattern + code_numbers_pattern
  CODE_REGEXP = Regexp.new(regexp_string)
  BAR_CODE_REGEXP = Regexp.new("-" + regexp_string)
  def self.code_regexp
    CODE_REGEXP
  end
  def self.bar_code_regexp
    BAR_CODE_REGEXP
  end

  def self.interpret_code ( code )
    rarity_out = Card.rarities.select {|r| r[0] == code.downcase[0]}
    frame_out = case code[1]
      when ?C: "Colourless"
      when ?W: "White"
      when ?U: "Blue"
      when ?B: "Black"
      when ?R: "Red"
      when ?G: "Green"
      when ?M, ?Z: "Multicolour"
      when ?H: "Auto"
      when ?S: "Auto"
      when ?A: "Artifact"
      when ?L: "Land colourless"
      else nil
    end
    [rarity_out, frame_out]
  end
  @@colour_regexps = [/w/i, /u/i, /b/i, /r/i, /g/i]
  @@nonhybrid_colour_regexps = [
      /(^|[^\/{(])w|[({]w[})]/i,  # match w either at the start ^, or after anything other than / { (
      /(^|[^\/{(])u|[({]u[})]/i,
      /(^|[^\/{(])b|[({]b[})]/i,
      /(^|[^\/{(])r|[({]r[})]/i,
      /(^|[^\/{(])g|[({]g[})]/i]

  def colours_in_cost
    out = @@colour_regexps.map do |re|
      re.match(cost) ? true : false
    end
  end
  def num_colours
    colours_in_cost.count{|x|x}
  end
  def colour_strings_present
    out = (@@colour_regexps.zip(Card.colours)).map do |re, colour|
      re.match(cost) ? colour : nil
    end.compact
  end
  def display_class
    if self.frame == "Auto"
      cardclass = "" << self.calculated_frame
    else
      cardclass = "" << self.frame
    end
    if self.cardtype =~ /Planeswalker/
      cardclass << " Planeswalker"
    end
    if self.cardtype =~ /Artifact/ && self.frame != "Artifact"
      cardclass << " Coloured_Artifact"
    end
    if self.num_colours == 2
      cardclass << " " + self.colour_strings_present.join("").downcase
    end
    if self.rarity == "token"
      cardclass << " token"
    end
    cardclass
  end
  def converted_mana_cost
    if cost.nil?
      return 0
    end
    # We split three times!
    # First extract parenthesised or braced subexpressions
    cost_tokens = cost.split(/([{(][^})]*[})])/)
    total = 0
    cost_tokens.each do |token|
      if token.match(/[{(]/)
        # This is a bracketed symbol such as (1), {2/G), {15}, {X}, or {W/U}
        total += cmc_of_token(token)
      else
        # This is not bracketed, but potentially a string of tokens such as 11BRG
        # Need to keep numbers grouped
        components = token.split(/([0-9-]+)/)
        components.each do |component|
          # This is either a string of letters like XRR
          # or a string of numbers like 15
          if component.match(/[0-9-]+/)
            total += cmc_of_token(component)
          else
            # This is a string of letters: split into characters
            component.split("").each do |letter|
              total += cmc_of_token(letter)
            end
          end
        end
      end
    end
    total
  end
  def cmc_of_token(token)
    # Return CMC-contribution of one token, such as U, W, X, 11, {3}, (Y), {2/G}
    if token.blank?
      return 0
    end
    internal_number = token.match(/[0-9-]+/)
    if internal_number 
      return internal_number[0].to_i
    elsif token.match(/[XYZxyz]/)
      # (X) or (Y) have CMC 0
      return 0
    else
      # Any other bracketed symbol without a number has CMC 1
      return 1
    end
  end
  def border_colour
    if cardset && cardset.configuration && !cardset.configuration.border_colour.blank?
      cardset.configuration.border_colour
    else
      Configuration.DEFAULT_VALUES[:border_colour]
    end
  end

  def category
    f = frame || calculated_frame
    case f
      when /^Land/
        return "Land"
      when /^(White|Blue|Black|Red|Green|Multicolour|Artifact|Colourless)$/:
        return f
      when /^Hybrid/
        return "Hybrid"
    end
  end

  def frame
    if Card.frames.include?(attributes["frame"]) || attributes["frame"] == "Auto"
      attributes["frame"]
    else
      calculated_frame
    end
  end

  def calculated_frame

    case num_colours
      when 1:     # Monocolour is the simplest case
        case cost
          when /w/i: return "White"
          when /u/i: return "Blue"
          when /b/i: return "Black"
          when /r/i: return "Red"
          when /g/i: return "Green"
        end
      when 2:     # Two-colour: distinguish between gold and hybrid
                  # We say a card for 1W(W/U)U is gold, but 1W(W/G) is hybrid
        # Count the number of colours present outside hybrid symbols
        colours_present = @@nonhybrid_colour_regexps.reduce(0) do |total, re|
          re.match(cost) ? total+1 : total
        end
        if colours_present >= 2
          return "Multicolour"
        else
          return "Hybrid " + colour_strings_present.join("").downcase
        end
      when 3..5:  # Multicolour is easy
        return "Multicolour"
      when 0:     # Colourless is either artifact, land, or neither, based on type
        if /land/i.match(cardtype) # Land
          # Could try to detect the text box here, but that's really fiddly to get right
          # Consider Coastal Tower, Arcane Sanctum, Hallowed Fountain, Flooded Strand, and Vivid Creek
          # So we just let them override it
          return "Land (colourless)"
        elsif /artifact/i.match(cardtype)
          return "Artifact"
        else
          return "Colourless"
        end
    end
  end
  
  
  PLAINS = Card.new(
    :name => "Plains",
    :supertype => "Basic",
    :cardtype => "Land",
    :subtype => "Plains",
    :frame => "Land white",
    :rarity => "basic"
  ) 
  ISLAND = Card.new(
    :name => "Island",
    :supertype => "Basic",
    :cardtype => "Land",
    :subtype => "Island",
    :frame => "Land blue",
    :rarity => "basic"
  )
  SWAMP = Card.new(
    :name => "Swamp",
    :supertype => "Basic",
    :cardtype => "Land",
    :subtype => "Swamp",
    :frame => "Land black",
    :rarity => "basic"
  )
  MOUNTAIN = Card.new(
    :name => "Mountain",
    :supertype => "Basic",
    :cardtype => "Land",
    :subtype => "Mountain",
    :frame => "Land red",
    :rarity => "basic"
  )
  FOREST = Card.new(
    :name => "Forest",
    :supertype => "Basic",
    :cardtype => "Land",
    :subtype => "Forest",
    :frame => "Land green",
    :rarity => "basic"
  )
  def Card.basic_land 
    [PLAINS, ISLAND, SWAMP, MOUNTAIN, FOREST]
  end
  def Card.blank(text)
    out = Card.new(:rulestext => text)
    out.blank = true
    out
  end

  def <=>(c2)
    if category != c2.category
      # Sort by category
      return Card.category_order.find_index(category) <=> Card.category_order.find_index(c2.category)
    else
      if ["Multicolour", "Hybrid"].include?(category)
        # Within a category, sort by colour-pair (hybrid / gold), then name
        if num_colours == c2.num_colours
          case num_colours
            when 2
              pair_order = ["WhiteBlue", "BlueBlack", "BlackRed", "RedGreen", "WhiteGreen",
                "WhiteBlack", "BlackGreen", "BlueGreen", "BlueRed", "WhiteRed"
                ]
            when 3
              pair_order = [ # allied triples sorted by Shard order
                "WhiteBlueBlack", "BlueBlackRed", "BlackRedGreen", "WhiteRedGreen", "WhiteBlueGreen",
                # enemy triples sorted by the mutual enemy
                "WhiteBlackRed", "BlueRedGreen", "WhiteBlackGreen", "WhiteBlueRed", "BlueBlackGreen"
                ]
            when 4
              pair_order = [ "WhiteBlueBlackRed", "BlueBlackRedGreen", "WhiteBlackRedGreen", "WhiteBlueRedGreen", "WhiteBlueBlackGreen" ]
          end
          pair1 = colour_strings_present.join
          pair2 = c2.colour_strings_present.join
          if pair1 != pair2
            return pair_order.find_index(pair1) <=> pair_order.find_index(pair2)
          else
            # Just sort by name
            return printable_name <=> c2.printable_name
          end
        else
          # Higher number of colours goes later
          if num_colours != c2.num_colours
            return num_colours <=> c2.num_colours
          else
            # Just sort by name
            return printable_name <=> c2.printable_name
          end
        end
      else
        # Within a category other than multicolour, just sort by name
        return printable_name <=> c2.printable_name
      end
    end
  end

end
