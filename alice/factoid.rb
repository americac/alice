class Alice::Factoid

  include Mongoid::Document

  field :text

  validates_presence_of :text
  
  belongs_to :user

  def self.for(nick)
    Alice::User.with_nick_like(nick).try(:get_factoid)
  end

  def self.random
    all.sample
  end

  def formatted(with_prefix=true)
    fact = self.text
    fact = Alice::Util::Sanitizer.strip_pronouns(fact)
    fact = Alice::Util::Sanitizer.make_third_person(fact)
    fact = Alice::Util::Sanitizer.initial_downcase(fact)

    message = ""
    message << "#{Alice::Util::Randomizer.fact_prefix}" if with_prefix
    message << " #{self.user.try(:proper_name)} #{fact}"
    message
  end

end