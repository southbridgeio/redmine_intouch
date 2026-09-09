require File.expand_path('../../../../test_helper', __FILE__)

class Intouch::Patches::IssuePatchTest < ActiveSupport::TestCase
  let(:issue) { Issue.new }

  describe 'client_notification_marker' do
    describe 'author is not a client' do
      before { issue.stubs(:author_is_client?).returns(false) }

      it { issue.client_notification_marker.must_equal '' }
    end

    describe 'client author with normal priority' do
      before do
        issue.stubs(:author_is_client?).returns(true)
        issue.stubs(:alarm?).returns(false)
        issue.stubs(:high_priority?).returns(false)
      end

      it { issue.client_notification_marker.must_equal ' ☎️' }
    end

    describe 'client author with high priority' do
      before do
        issue.stubs(:author_is_client?).returns(true)
        issue.stubs(:alarm?).returns(false)
        issue.stubs(:high_priority?).returns(true)
      end

      it { issue.client_notification_marker.must_equal ' ☎️ 🩸' }
    end

    describe 'client author with alarm priority' do
      before do
        issue.stubs(:author_is_client?).returns(true)
        issue.stubs(:alarm?).returns(true)
        issue.stubs(:high_priority?).returns(false)
      end

      it { issue.client_notification_marker.must_equal ' ☎️ 🩸' }
    end
  end
end
