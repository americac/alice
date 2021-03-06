class Alice::Item

  include Mongoid::Document
  include Mongoid::Timestamps
  include Alice::Behavior::Searchable
  include Alice::Behavior::Ownable
  include Alice::Behavior::Placeable

  field :name
  field :description
  field :is_cursed, type: Boolean
  field :is_hidden, type: Boolean
  field :is_weapon, type: Boolean
  field :is_game, type: Boolean
  field :is_key, type: Boolean
  field :is_readable, type: Boolean
  field :picked_up_at, type: DateTime
  field :creator_id

  index({ name: 1 },        { unique: true, })
  index({ is_cursed: 1 },   { unique: false })
  index({ is_hidden: 1 },   { unique: false })
  index({ is_weapon: 1 },   { unique: false })
  index({ is_game: 1 },     { unique: false })
  index({ is_key: 1 },      { unique: false })
  index({ is_readable: 1 }, { unique: false })
  index({ creator_id: 1 },  { unique: false })

  validates_uniqueness_of :name
  validates_presence_of :name
  
  attr_accessor :message

  belongs_to  :actor
  belongs_to  :user, inverse_of: :items
  belongs_to  :place
  has_many    :actions

  before_create :check_cursed
  before_create :ensure_description

  def self.already_exists?(name)
    like(name).present?
  end

  def self.cursed
    where(is_cursed: true).excludes(name: 'fruitcake')
  end


  def self.forge(args={})
    if new_item = create(
        name: args[:name].downcase,
        user: args[:user],
        actor: args[:actor],
        creator_id: args[:user].try(:id)
      )
      new_item.creator && new_item.creator.score_point
      new_item
    end
  end

  def self.fruitcake
    where(name: 'fruitcake').last || create(name: 'fruitcake', is_cursed: true)
  end

  def self.sweep
    all.map{|item| item.delete unless item.actor? || item.user?}
  end

  def self.games
    where(is_game: true)
  end

  def self.keys
    where(is_key: true)
  end
  
  def self.reading_material
    where(is_readable: true)
  end
  
  def self.weapons
    where(is_weapon: true)
  end

  def self.inventory_from(owner, list)
    stuff = Alice::Util::Randomizer.empty_pockets if list.empty?
    stuff ||= list.map(&:name_with_article).to_sentence
    "#{owner.proper_name}'s #{Alice::Util::Randomizer.item_container} #{stuff}."
  end

  def self.reset_cursed
    cursed.update_all(is_cursed: false)
  end

  def self.total_inventory
    return "We have nothing! Someone needs to forge some stuff, possibly some things as well!" if count == 0
    "Our equipment includes #{sorted.map(&:name_with_article).to_sentence}."
  end

  def self.sorted
    all.sort_by(&:name)
  end

  def check_cursed
    self.is_cursed ||= rand(10) == 1
    true
  end

  def creator
    return unless self.creator_id
    Alice::User.find(self.creator_id)
  end

  def describe
    text = self.description
    text << " #{creator.proper_name} was its creator, judging by the maker's mark." if creator
    text << " Might be fun to read." if self.is_readable?
    text << " Might make a decent weapon." if self.is_weapon?
    text << " Might be fun to play." if self.is_game?
    text << " Could come in handy with those pesky locked doors." if self.is_key?
    text
  end

  def ensure_description
    self.description ||= Alice::Util::Randomizer.item_description(self.name)
  end

  def name_with_appendix
    self.is_game? && "#{self.name} game" || self.name
  end

  def name_with_article
    Alice::Util::Sanitizer.process("#{Alice::Util::Randomizer.article} #{self.name_with_appendix}")
  end

  def play
    return "It's not safe to play with #{name_with_article}!" unless self.is_game?
    self.user.score_point if self.user.can_play_game?
    return "#{owner} #{Alice::Util::Randomizer.play} a game of #{name}."
  end
  
  def read
    return "#{name_with_article} is not a very interesting read." unless self.is_readable?
    return "It says that #{Alice::Factoid.random.formatted(false)}."
  end

  def transfer_to(recipient)
    self.user_id = recipient.id
    self.picked_up_at = DateTime.now
    self.save
  end

end

