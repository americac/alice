module Alice

  module Behavior
  
    module Scorable

      def award_point_to(actor)
        if self.can_award_points?
          self.update_attribute(:last_award, DateTime.now)
          actor.score_point
        end
      end

      def can_award_points?
        self.last_award ||= DateTime.now - 1.day
        self.last_award <= DateTime.now - 13.minutes
      end

      def check_score
        score_text = "#{self.proper_name} has #{self.points == 1 ? "1 point" : self.points.to_s << ' points'}"
        score_text << " and is in #{Alice::Util::Sanitizer.ordinal(rank)} place" if rank && rank < 5
        score_text << "."
        score_text
      end

      def score_point
        self.update_attribute(:points, self.points + 1)
      end

      def penalize
        return if self.points == 0
        self.update_attribute(:points, self.points - 1)
      end

      def rank
        return unless self.points > 0
        places = (Alice::User.where(:points.gt => 0) + Alice::Actor.where(:points.gt => 0)).sort_by(&:points).reverse
        places.present? && places.index(self) + 1
      end

    end

  end

end