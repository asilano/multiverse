# == Schema Information
# Schema version: 20101215230231
#
# Table name: configurations
#
#  id                     :integer         not null, primary key
#  frame                  :string(255)
#  use_highlighting       :boolean
#  use_addressing         :boolean
#  default_comment_state  :string(255)
#  cardlist_show_comments :boolean
#  cardlist_show_code     :boolean
#  cardlist_show_active   :boolean
#  card_show_code         :boolean
#  card_show_active       :boolean
#  visibility             :string(255)
#  commentability         :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  cardset_id             :integer
#  editability            :string(255)
#  adminability           :string(255)
#  last_edit_by           :integer
#

class Configuration < ActiveRecord::Base
  attr_protected :id

  belongs_to :cardset

  people_options = {
    :anyone => "Anyone",
    :signedin => "Signed-in users",
    :admins => "Admins only",
    # :selected => "Selected users:"
  }
  admin_options = {
    :signedin => "Signed-in users",
    :justme => "Just owner",
    # :selected => "Selected users:"
  }
  @@legal_values_internal = {
    :frame => {
      "image" => "Supplied image",
      "prettycard" => "Coloured card mockup",
      "plain" => "Plain text",
    },
    :default_comment_state => {
      "unaddressed" => "Unaddressed",
      "normal" => "Normal",
    },
    :visibility => people_options,
    :commentability => people_options,
    :editability => people_options,
    :adminability => admin_options,
  }
  validators = Hash[ @@legal_values_internal.map do |prop, values_hash|
    [prop, Regexp.new( values_hash.keys.join('|') )]
  end ]

  validators.keys.each do |thisprop|
    validates thisprop, :presence => true,
                        :format   => { :with => validators[thisprop] }
  end

  def legal_values
    @@legal_values_internal
  end

  DEFAULT_VALUES = {
    :frame                  => 'prettycard',
    :use_highlighting       => true,
    :use_addressing         => true,
    :default_comment_state  => 'unaddressed',
    :cardlist_show_comments => true,
    :cardlist_show_code     => false,
    :cardlist_show_active   => false,
    :card_show_code         => false,
    :card_show_active       => false,
    :visibility             => 'anyone',
    :commentability         => 'anyone',
    :editability            => 'admins',
    :adminability           => 'justme',
  }

  def set_default_values!
    self.attributes = DEFAULT_VALUES
  end

  def set_blank_values!
    if self.editability.blank?
      self.editability = DEFAULT_VALUES[:editability]
    end
    if self.adminability.blank?
      self.adminability = DEFAULT_VALUES[:adminability]
    end
    self.save!
  end

end
