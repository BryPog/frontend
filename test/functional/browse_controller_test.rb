require_relative "../test_helper"

class BrowseControllerTest < ActionController::TestCase
  def api_returns_404_for(path)
    body = {
      "_response_info" => {
        "status" => "not found"
      }
    }
    url = "#{Plek.current.find("contentapi")}#{path}"
    stub_request(:get, url).to_return(:status => 404, :body => body.to_json, :headers => {})
  end

  context "GET index" do
    should "list all categories" do
      content_api_has_root_sections(["crime-and-justice"])
      get :index
      url = "http://www.test.gov.uk/browse/crime-and-justice"
      assert_select "ul h2 a", "Crime and justice"
      assert_select "ul h2 a[href=#{url}]"
    end

    should "set slimmer format of browse" do
      content_api_has_root_sections(["crime-and-justice"])
      get :index

      assert_equal "browse",  response.headers["X-Slimmer-Format"]
    end

    should "set correct expiry headers" do
      content_api_has_root_sections(["crime-and-justice"])
      get :index

      assert_equal "max-age=1800, public",  response.headers["Cache-Control"]
    end
  end

  context "GET section" do
    should "list the sub sections" do
      content_api_has_section("crime-and-justice")
      content_api_has_subsections("crime-and-justice", ["alpha"])
      get :section, section: "crime-and-justice"

      assert_select "h1", "Crime and justice"
      assert_select "ul h2 a", "Alpha"
    end

    should "404 if the section does not exist" do
      api_returns_404_for("/tags/banana.json")
      api_returns_404_for("/tags.json?parent_id=banana&type=section")

      get :section, section: "banana"
      assert_response 404
    end

    should "set slimmer format of browse" do
      content_api_has_section("crime-and-justice")
      content_api_has_subsections("crime-and-justice", ["alpha"])
      get :section, section: "crime-and-justice"

      assert_equal "browse",  response.headers["X-Slimmer-Format"]
    end

    should "set correct expiry headers" do
      content_api_has_section("crime-and-justice")
      content_api_has_subsections("crime-and-justice", ["alpha"])
      get :section, section: "crime-and-justice"

      assert_equal "max-age=1800, public",  response.headers["Cache-Control"]
    end
  end

  context "GET sub_section" do
    setup do
      mock_api = stub('guidance_api')
      @results = stub("results", results: [])
      mock_api.stubs(:sub_sections).returns(@results)
      Frontend.stubs(:detailed_guidance_content_api).returns(mock_api)
    end

    context "nasty hardcoded links till we properly integrate inside gov" do
      should "include link to 'how government works' on government page" do
        content_api_has_section("citizenship/government", "citizenship")
        content_api_has_artefacts_in_a_section("citizenship/government", [])

        get :sub_section, section: 'citizenship', sub_section: 'government'

        assert_select "li h3 a", {:count => 1, :text => "How government works"}
      end

      should "not include 'how government works' on other sections" do
        content_api_has_section("crime-and-justice/judges", "crime-and-justice")
        content_api_has_artefacts_in_a_section("crime-and-justice/judges", ["judge-dredd"])

        get :sub_section, section: "crime-and-justice", sub_section: "judges"

        assert_select "li h3 a", {:count => 0, :text => "How government works"}
      end
    end

    should "list the content in the sub section" do
      content_api_has_section("crime-and-justice/judges", "crime-and-justice")
      content_api_has_artefacts_in_a_section("crime-and-justice/judges", ["judge-dredd"])

      get :sub_section, section: "crime-and-justice", sub_section: "judges"

      assert_select "h1", "Judges"
      assert_select "li h3 a", "Judge dredd"
    end

    should "list detailed guidance categories in the sub section" do
      content_api_has_section("crime-and-justice/judges", "crime-and-justice")
      content_api_has_artefacts_in_a_section("crime-and-justice/judges", ["judge-dredd"])

      detailed_guidance = OpenStruct.new({
          title: 'Detailed guidance',
          details: OpenStruct.new(description: "Lorem Ipsum Dolor Sit Amet"),
          content_with_tag: OpenStruct.new(web_url: 'http://example.com/browse/detailed-guidance')
        })

      @results.stubs(:results).returns([detailed_guidance])

      get :sub_section, section: "crime-and-justice", sub_section: "judges"

      assert_select '.detailed-guidance' do
        assert_select "li a[href='http://example.com/browse/detailed-guidance']", text: 'Detailed guidance'
        assert_select 'li p', text: "Lorem Ipsum Dolor Sit Amet"
      end
    end

    should "404 if the section does not exist" do
      api_returns_404_for("/tags/crime-and-justice%2Ffrume.json")
      api_returns_404_for("/tags/crime-and-justice.json")

      get :sub_section, section: "crime-and-justice", sub_section: "frume"
      assert_response 404
    end

    should "404 if the sub section does not exist" do
      content_api_has_section("crime-and-justice")
      api_returns_404_for("/tags/crime-and-justice%2Ffrume.json")
      get :sub_section, section: "crime-and-justice", sub_section: "frume"
      assert_response 404
    end

    should "set slimmer format of browse" do
      content_api_has_section("crime-and-justice/judges", "crime-and-justice")
      content_api_has_artefacts_in_a_section("crime-and-justice/judges", ["judge-dredd"])
      get :sub_section, section: "crime-and-justice", sub_section: "judges"

      assert_equal "browse",  response.headers["X-Slimmer-Format"]
    end

    should "set correct expiry headers" do
      content_api_has_section("crime-and-justice/judges", "crime-and-justice")
      content_api_has_artefacts_in_a_section("crime-and-justice/judges", ["judge-dredd"])
      get :sub_section, section: "crime-and-justice", sub_section: "judges"

      assert_equal "max-age=1800, public",  response.headers["Cache-Control"]
    end
  end
end
