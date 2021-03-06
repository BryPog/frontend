require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  class ApplicationHelperContainer
    include ApplicationHelper
    include ActionView::Helpers::TagHelper

    def request
      @request ||= OpenStruct.new(:format => OpenStruct.new(:video? => false))
    end
  end

  def setup
    @helper = ApplicationHelperContainer.new
  end

  def dummy_artefact
    artefact_for_slug("dummy")
  end

  test "the page title doesn't contain consecutive pipes" do
    assert_no_match %r{\|\s*\|}, @helper.page_title(dummy_artefact)
  end

  test "the page title does not includes the publication alternative title if one's set" do
    publication = OpenStruct.new(alternative_title: 'I am an alternative', title: 'I am not')
    title = @helper.page_title(dummy_artefact, publication)
    assert_no_match %r{I am an alternative}, title
    assert_match %r{I am not}, title
  end

  test "the page title doesn't blow up if the publication titles are nil" do
    publication = OpenStruct.new(title: nil)
    assert @helper.page_title(dummy_artefact, publication)
  end

  context "wrapper_class" do
    should "correctly identifies a video guide in the wrapper classes" do
      @helper.request.format.stubs(:video?).returns(true)
      guide = OpenStruct.new(:type => 'guide')
      assert @helper.wrapper_class(guide).split.include?('video-guide')
    end

    should "mark local transactions as a service" do
      local_transaction = OpenStruct.new(:type => 'local_transaction')
      assert @helper.wrapper_class(local_transaction).split.include?('service')
    end

    should "mark travel advice as a guide" do
      travel_advice_edition = OpenStruct.new(:type => 'travel-advice')
      assert @helper.wrapper_class(travel_advice_edition).split.include?('guide')
    end
  end

  test "should build title from publication and artefact" do
    publication = OpenStruct.new(title: "Title")
    assert_equal "Title - GOV.UK", @helper.page_title(dummy_artefact, publication)
  end

  test "should prefix title of video with video" do
    @helper.request.format.stubs(:video?).returns(true)
    publication = OpenStruct.new(title: "Title")
    assert_match /^Video - Title/, @helper.page_title(dummy_artefact, publication)
  end

  test "should omit first part of title if publication is omitted" do
    @helper.request.format.stubs(:video?).returns(true)
    assert_equal "GOV.UK", @helper.page_title(dummy_artefact)
  end
end
