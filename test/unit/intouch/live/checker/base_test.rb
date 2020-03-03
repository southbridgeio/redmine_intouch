require File.expand_path('../../../../../test_helper', __FILE__)

class Intouch::Live::Checker::BaseTest < ActiveSupport::TestCase
  subject do
    Intouch::Live::Checker::Base.new(
      issue: issue,
      project: project
    ).required?
  end

  let(:project) { Object.new }
  let(:issue) { Object.new }

  describe 'yes' do
    before do
      project.stubs(:module_enabled?).with(:intouch).returns(true)
      project.stubs(:active?).returns(true)
      issue.stubs(:closed?).returns(false)
    end

    it { subject.must_equal true }
  end

  describe 'no' do
    describe 'project without enabled intouch module' do
      before do
        project.stubs(:module_enabled?).with(:intouch).returns(false)

        project.stubs(:active?).returns(true)
        issue.stubs(:closed?).returns(false)
      end

      it { subject.must_equal false }
    end

    describe 'inactive project' do
      before do
        project.stubs(:active?).returns(false)

        project.stubs(:module_enabled?).with(:intouch).returns(true)
        issue.stubs(:closed?).returns(false)
      end

      it { subject.must_equal false }
    end
  end
end
