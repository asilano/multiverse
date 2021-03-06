# The has_many association gives this a bunch of methods:
# cards(force_reload = false)
# cards<<(object, �)   / cards.push(card)
# cards.delete(object, �)
# cards=objects
# card_ids
# card_ids=ids
# cards.clear   - blanks the decklist, doesn't delete cards
# cards.empty?
# cards.size
# cards.find(�)
# cards.where(�)
# cards.exists?(�)
# cards.build(attributes = {}, �)
# cards.create(attributes = {})

class Decklist < ActiveRecord::Base
  belongs_to :user
  belongs_to :cardset
  # http://stackoverflow.com/questions/16569994/
  has_many :cards, -> { uniq }, :through => :deck_cards
  has_many :deck_cards  # to get at the counts and sections
  has_many :deck_wizards_cards  # to get at the counts and sections
  attr_protected :cardset_id, :user_id
  
  PUBLISHED = 4
  VIEWABLE = 8
  EDITABLE = 16
  HIGHEST_STATUS = 31
  
  validates_inclusion_of :status, :in => (0..HIGHEST_STATUS)
  
  def active?
    self.active
  end
  def published?
    (status & PUBLISHED) > 0
  end
  def editable?
    (status & EDITABLE) > 0
  end
  def viewable?
    (status & VIEWABLE) > 0
  end
  def sections
    all_secs = deck_cards.map{ |dc| dc.section } + deck_wizards_cards.map{ |dc| dc.section }
    all_secs.uniq
  end
  
  #? attr_accessor :stats
  def stats
    if attributes[:stats].nil?
      # calc them
      attributes[:stats] = calculated_stats
    else
      attributes[:stats]
    end
  end
  
  def Decklist.enabled?
    false
  end
end
