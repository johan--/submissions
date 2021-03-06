# encoding: UTF-8
require 'spec_helper'

describe ReviewersHelper, type: :helper do
  it "should reply doesnot_review for track without preferences" do
    level = helper.review_level([], FactoryGirl.build(:track))
    expect(level).to eq('reviewer.doesnot_review')
  end
  
  it "should reply doesnot_review for track with preferences that don't match" do
    track = FactoryGirl.build(:track, id: 10)
    level = helper.review_level(
      [FactoryGirl.build(:preference, track: track)],
      FactoryGirl.build(:track))
    expect(level).to eq('reviewer.doesnot_review')
  end
  
  it "should reply preference level for track with preferences that match" do
    track = FactoryGirl.build(:track)
    preference = FactoryGirl.build(:preference, track: track)
    level = helper.review_level([preference], track)
    expect(level).to eq(preference.audience_level.title)
  end

  it "should build hash with reviewers when reviewer is anonymous" do
    early_review = FactoryGirl.create(:early_review)
    reviewer = FactoryGirl.create(:reviewer, user: early_review.reviewer)
    reviwers, comments = helper.build_hash_with_reviewers_and_comments([early_review], Conference.current)
    expect(reviwers[early_review]).to eq("#{t('formtastic.labels.reviewer.user_id')} 1")
  end

  it "should build hash with reviewers when reviewer is not anonymous" do
    early_review = FactoryGirl.create(:early_review)
    reviewer = FactoryGirl.create(:reviewer, sign_reviews: true, user: early_review.reviewer)
    reviwers, comments = helper.build_hash_with_reviewers_and_comments([early_review], Conference.current)
    expect(reviwers[early_review]).to eq(reviewer.user.full_name)
  end

  it "should build hash with reviewers when there are anonymous and not anonymous reviewers" do
    early_review1 = FactoryGirl.create(:early_review)
    reviewer1 = FactoryGirl.create(:reviewer, sign_reviews: false, user: early_review1.reviewer)
    
    early_review2 = FactoryGirl.create(:early_review)
    reviewer2 = FactoryGirl.create(:reviewer, sign_reviews: true, user: early_review2.reviewer)
    
    early_review3 = FactoryGirl.create(:early_review)
    reviewer3 = FactoryGirl.create(:reviewer, sign_reviews: false, user: early_review3.reviewer)

    reviewers, comments = helper.build_hash_with_reviewers_and_comments([early_review1, early_review2, early_review3], Conference.current)
    expect(reviewers[early_review1]).to eq("#{t('formtastic.labels.reviewer.user_id')} 1")
    expect(reviewers[early_review2]).to eq(reviewer2.user.full_name)
    expect(reviewers[early_review3]).to eq("#{t('formtastic.labels.reviewer.user_id')} 3")
  end

  context 'reviewer summary review row' do
    before(:each) do
      @conference = FactoryGirl.build(:conference)
      @recommendations = Recommendation.all_names.map do |name|
        FactoryGirl.create(:recommendation, name: name)
      end
    end
    it 'should have 4 0s and a blank spot before reviews are happening' do
      row = helper.reviewer_summary_review_row([], @conference)

      expect(row).to have(5).items
      expect(row[0]).to eq(0)
      expect(row[1]).to eq(0)
      expect(row[2]).to eq(0)
      expect(row[3]).to eq(0)
      expect(row[4]).to eq('')
    end
    it 'should partition reviews by recommendations' do
      reviews = @recommendations.map do |r|
        session = FactoryGirl.build(:session, conference: @conference, state: 'in_review')
        FactoryGirl.build(:final_review, recommendation_id: r.id, session: session)
      end
      row = helper.reviewer_summary_review_row(reviews, @conference)

      expect(row).to have(5).items
      expect(row[0]).to eq(1)
      expect(row[1]).to eq(1)
      expect(row[2]).to eq(1)
      expect(row[3]).to eq(1)
      expect(row[4]).to eq('')
    end
    it 'should include feedback if past author notification' do
      @conference.author_notification = DateTime.now - 1.minute
      @conference.save
      reviews = @recommendations.map do |r|
        session = FactoryGirl.create(:session, conference: @conference, state: 'in_review')
        FactoryGirl.create(:final_review, recommendation_id: r.id, session: session)
      end
      feedback = ReviewFeedback.create(conference: @conference, author: FactoryGirl.create(:author))
      ReviewEvaluation.new(review_feedback: feedback, review: reviews.first, helpful_review: true).save(validate: false)
      ReviewEvaluation.new(review_feedback: feedback, review: reviews.first, helpful_review: false).save(validate: false)
      ReviewEvaluation.new(review_feedback: feedback, review: reviews.last, helpful_review: false).save(validate: false)
      row = helper.reviewer_summary_review_row(reviews, @conference)

      expect(row).to have(5).items
      expect(row[0]).to eq(1)
      expect(row[1]).to eq(1)
      expect(row[2]).to eq(1)
      expect(row[3]).to eq(1)
      expect(row[4]).to eq('1<img alt="👍" src="/assets/helpful.png" /> 2<img alt="👎" src="/assets/not-helpful.png" />')
    end
  end

  context 'review feedback score' do
    before(:each) do
      @review = FactoryGirl.build(:final_review)
    end
    it 'should count a negative feedback as 10' do
      @review.stubs(:review_evaluations).returns(
        [ReviewEvaluation.new(review: @review, helpful_review: false)]
      )
      expect(helper.review_feedback_score(@review)).to eq(10)
    end
    it 'should count a positive feedback as 1' do
      @review.stubs(:review_evaluations).returns(
        [ReviewEvaluation.new(review: @review, helpful_review: true)]
      )
      expect(helper.review_feedback_score(@review)).to eq(1)
    end
    it 'should have 0 value without evaluation' do
      @review.stubs(:review_evaluations).returns([])
      expect(helper.review_feedback_score(@review)).to eq(0)
    end
  end
end
