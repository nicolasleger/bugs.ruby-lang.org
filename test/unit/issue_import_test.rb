# Redmine - project management software
# Copyright (C) 2006-2015  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require File.expand_path('../../test_helper', __FILE__)

class IssueImportTest < ActiveSupport::TestCase
  fixtures :projects, :enabled_modules,
           :users, :email_addresses,
           :roles, :members, :member_roles,
           :issues, :issue_statuses,
           :trackers, :projects_trackers,
           :versions,
           :issue_categories,
           :enumerations,
           :workflows,
           :custom_fields,
           :custom_values,
           :custom_fields_projects,
           :custom_fields_trackers

  def test_create_versions_should_create_missing_versions
    import = generate_import_with_mapping
    import.mapping.merge!('fixed_version' => '9', 'create_versions' => '1')
    import.save!

    version = new_record(Version) do
      assert_difference 'Issue.count', 3 do
        import.run
      end
    end
    assert_equal '2.1', version.name
  end

  def test_create_categories_should_create_missing_categories
    import = generate_import_with_mapping
    import.mapping.merge!('category' => '10', 'create_categories' => '1')
    import.save!

    category = new_record(IssueCategory) do
      assert_difference 'Issue.count', 3 do
        import.run
      end
    end
    assert_equal 'New category', category.name
  end

  def test_parent_should_be_set
    import = generate_import_with_mapping
    import.mapping.merge!('parent_issue_id' => '5')
    import.save!

    issues = new_records(Issue, 3) { import.run }
    assert_nil issues[0].parent
    assert_equal issues[0].id, issues[1].parent_id
    assert_equal 2, issues[2].parent_id
  end

  def test_is_private_should_be_set_based_on_user_locale
    import = generate_import_with_mapping
    import.mapping.merge!('is_private' => '6')
    import.save!

    issues = new_records(Issue, 3) { import.run }
    assert_equal [false, true, false], issues.map(&:is_private)
  end

  def test_run_should_remove_the_file
    import = generate_import_with_mapping
    file_path = import.filepath
    assert File.exists?(file_path)

    import.run
    assert !File.exists?(file_path)
  end
end