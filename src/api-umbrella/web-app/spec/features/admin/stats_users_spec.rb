require "spec_helper"

describe "analytics by users", :js => true do
  login_admin

  before(:each) do
    # TODO: remove delete by query (not supported in ES 2.0)
    # https://www.elastic.co/guide/en/elasticsearch/reference/1.6/docs-delete-by-query.html
    # https://www.elastic.co/guide/en/elasticsearch/reference/1.6/search-request-scroll.html
    LogItem.gateway.client.delete_by_query :index => LogItem.index_name, :body => {
      :query => {
        :match_all => {},
      },
    }
  end

  describe "xss" do
    it "escapes html entities in the table" do
      user = FactoryGirl.create(:xss_api_user)
      FactoryGirl.create(:xss_log_item, :request_at => Time.parse("2015-01-16T06:06:28.816Z"), :api_key => user.api_key, :user_id => user.id, :user_email => user.email, :user_registration_source => user.registration_source)
      LogItem.gateway.refresh_index!

      visit "/admin/#/stats/users/tz=America%2FDenver&search=&start_at=2015-01-12&end_at=2015-01-18&interval=day"

      page.should have_content(user.email)
      page.should have_content(user.first_name)
      page.should have_content(user.last_name)
      page.should have_content(user.use_description)
      page.should_not have_selector(".xss-test", :visible => :all)
    end
  end
end
