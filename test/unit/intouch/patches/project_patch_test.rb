require File.expand_path('../../../../test_helper', __FILE__)

class Intouch::Patches::ProjectPatchTest < ActiveSupport::TestCase
  fixtures :projects

  describe '#title' do
    it 'returns project name' do
      project = Project.find(1)

      assert_equal project.name, project.title
    end

    it 'returns project name for child project' do
      parent = Project.find(1)
      child = Project.new(name: 'Child Project', identifier: 'child-project')
      child.parent = parent
      child.save!

      assert_equal 'Child Project', child.title
    end

    it 'returns project name for nested project' do
      grandparent = Project.find(1)

      parent = Project.new(name: 'Parent Project', identifier: 'parent-project')
      parent.parent = grandparent
      parent.save!

      child = Project.new(name: 'Child Project', identifier: 'child-project')
      child.parent = parent
      child.save!

      assert_equal 'Child Project', child.title
    end
  end
end
