require File.expand_path('../../test_helper', __FILE__)

class JournalTest < ActiveSupport::TestCase
  fixtures :projects, :issues

  def setup
    @issue = Issue.find 1
    @project = @issue.project
  end

  context 'new alarm' do
  end
end
