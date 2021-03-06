# encoding: UTF-8
require 'spec_helper'

describe ReviewEvaluation, type: :model do
  context "validations" do
    it { should validate_presence_of :review }
    should_validate_existence_of :review

    it "should validate conference of feedback matches the one in review" do
      session = FactoryGirl.build(:session)

      review = FactoryGirl.build(:final_review, session: session)
      review_feedback = FactoryGirl.build(:review_feedback,
          author: session.author,
          conference: FactoryGirl.build(:conference))

      evaluation = ReviewEvaluation.new(review: review, review_feedback: review_feedback)

      expect(evaluation).to_not be_valid
      expect(evaluation.errors[:review]).to include(I18n.t("activerecord.errors.models.review_evaluation.review_and_feedback_missmatch"))
    end

    it "should validate author of review's session matches the one on feedback" do
      session = FactoryGirl.build(:session)

      review = FactoryGirl.build(:final_review, session: session)
      review_feedback = FactoryGirl.build(:review_feedback,
          author: FactoryGirl.build(:author),
          conference: session.conference)

      evaluation = ReviewEvaluation.new(review: review, review_feedback: review_feedback)

      expect(evaluation).to_not be_valid
      expect(evaluation.errors[:review]).to include(I18n.t("activerecord.errors.models.review_evaluation.review_and_feedback_missmatch"))
    end
  end

  context "associations" do
    it { should belong_to :review }
    it { should belong_to :review_feedback }
  end
end
