require 'Test.More'
local Spore = require 'Spore'
local response, payload, update_payload
local print = print

local ENV = -- some constants for tests
{
  -- This path should be relative to the directory, where you run tests
  -- Redmine description file an be get there: https://github.com/SPORE/api-description/tree/master/services
  ['api_description_path'] = '../../api-description/services/redmine.json';
  ['test_project_id'] = 1; -- Test requires a project already created on the test Redmine server
  ['test_issue_id'] = 5; -- Test requires two issues already created on the test Redmine server
  ['related_test_issue_id'] = 24;
  ['test_attachment_id'] = 1; -- Test requires an attachnet already created on the test Redmine server  
}

local helper = {}

helper.enable_auth = function (redmine)
  local api_key = os.getenv('REDMINE_API_KEY')
    if not api_key or api_key:match'^%s*$' then
    skip_rest('REDMINE_API_KEY variable in your environment is not set')
    os.exit()
  end
redmine:enable('Spore.Middleware.Auth.Redmine', { api_key = api_key })
end

helper.enable_format = function (redmine, is_xml)
  if is_xml then
    redmine:enable('Spore.Middleware.Format.XML')
  else
    redmine:enable('Spore.Middleware.Format.JSON')
  end
end

helper.check_libs = function()
  if not pcall(require, 'lxp.lom') then
    skip_all 'no xml'
  end

  if not pcall(require, 'ssl.https') then
    skip_all 'no https'
  end

  if not require_ok 'Spore.Middleware.Format.XML' then
    skip_rest "no Spore.Middleware.Format.XML"
  os.exit()
  end

  if not require_ok 'Spore.Middleware.Format.JSON' then
    skip_rest "no Spore.Middleware.Format.JSON"
    os.exit()
  end
end

local function test_redmine_1_1(data_format) -- Tests methods that are included in Redmine API ver. 1.1
                                             -- NB! Some of tests may require administrative privilegies on Redmine server.

  local is_xml = string.lower(data_format) == 'xml'
  local base_url = os.getenv('REDMINE_BASE_URL')
  if not base_url or base_url:match'^%s*$' then
    skip_rest('REDMINE_BASE_URL variable in your environment is not set')
    os.exit()
  end
  local redmine = Spore.new_from_spec(ENV.api_description_path, { ['base_url'] = base_url })
  helper.enable_auth(redmine)
  helper.enable_format(redmine, is_xml)

  -------------------------------------------------------------------------------------------------------------
  -- Issues tests
  -------------------------------------------------------------------------------------------------------------
  print ('Issues tests (' .. data_format .. ')')

  -- Check for getting all issues
  response = redmine:list_issues{['format'] = data_format}
  is(response.status, 200)

  payload =
  {
    issue =
    {
      subject = 'api_test';
      project_id = ENV.test_project_id;
      priority_id = 4;
    }
  }

  -- Check for creating an issue
  response = redmine:create_issue{ ['format'] = data_format, ['payload'] = payload }
  is(response.status, 201)

  local created_issue_id
  if is_xml then
    created_issue_id = response.body.issue.id[1]
  else
    created_issue_id = response.body.issue.id
  end

    -- Check for getting single issue
  response = redmine:get_issue{ ['format'] = data_format, ['id'] = created_issue_id }
  is(response.status, 200)

  update_payload =
  {
    issue =
    {
      subject = 'api_test_new_subject XML';
    }
  }

  -- Check for updating an issue
  response = redmine:update_issue{ ['format'] = data_format, ['id'] = created_issue_id, ['payload'] = update_payload }
  is(response.status, 200)

  -- Check for deleting an issue
  response = redmine:delete_issue{ ['format'] = data_format, ['id'] = created_issue_id }
  is(response.status, 200)

  -------------------------------------------------------------------------------------------------------------
  -- Projects tests
  -------------------------------------------------------------------------------------------------------------
  print ('Projects tests (' .. data_format .. ')')

  -- Check for getting all projects
  response = redmine:list_projects{ ['format'] = data_format }
  is(response.status, 200)

  local time = os.time()
  payload =
  {
    project =
    {
      name = 'Test project ' .. time;
      identifier = 'test-project-' .. time; -- Identifier must be unique
      description = 'This project is created by test script for Redmine API';
    }
  }

  -- Check for creating a project
  response = redmine:create_project{ ['format'] = data_format, ['payload'] = payload }
  is(response.status, 201)

  local created_project_id
  if is_xml then
    created_project_id = response.body.project.id[1]
  else
    created_project_id = response.body.project.id
  end

  -- Check for getting single project
  response = redmine:get_project{ ['format'] = data_format, ['id'] = created_project_id }
  is(response.status, 200)

  update_payload =
  {
    project =
    {
      description = 'Description was changed by test script for Redmine API';
    }
  }

  -- Check for updating a project
  response = redmine:update_project{ ['format'] = data_format, ['id'] = created_project_id, ['payload'] = update_payload }
  is(response.status, 200)

  -- Check for deleting a project
  response = redmine:delete_project{ ['format'] = data_format, ['id'] = created_project_id }
  is(response.status, 200)

  -------------------------------------------------------------------------------------------------------------
  -- Users tests
  -------------------------------------------------------------------------------------------------------------
  print ('Users tests (' .. data_format .. ')')

  -- Check for getting all users
  response = redmine:list_users{ ['format'] = data_format }
  is(response.status, 200)

  local can_work_with_users = response.status ~= 403 -- whether current user has privileges to create/read/update/delete users or not

   -- Check for getting current User
  response = redmine:get_current_user{ ['format'] = data_format }
  is(response.status, 200)

  if not can_work_with_users then -- Skip tests in order to avoid an exception
    skip('Check for creating a user: no such privileges')
    skip('Check for getting single user: no such privileges')
    skip('Check for updating a user: no such privileges')
    skip('Check for deleting a user: no such privileges')
  else
    payload =
    {
      user =
      {
        login = 'js';
        firstname = 'John';
        lastname = 'Smith';
        password = 'secret';
        mail = 'js@google.com';
      }
    }

    -- Check for creating a user
    response = redmine:create_user{ ['format'] = data_format, ['payload'] = payload }
    is(response.status, 201)

    local created_user_id
    if is_xml then
      created_user_id = response.body.user.id[1]
    else
      created_user_id = response.body.user.id
    end

    -- Check for getting single user
    response = redmine:get_user{ ['format'] = data_format, ['id'] = created_user_id }
    is(response.status, 200)

    update_payload =
    {
      user =
      {
        mail = 'js_new@google.com';
      }
    }

    -- Check for updating a user
    response = redmine:update_user{ ['format'] = data_format, ['id'] = created_user_id, ['payload'] = update_payload }
    is(response.status, 200)
    -- TODO! Get this user and check its attributs

    -- Check for deleting a user
    response = redmine:delete_user{ ['format'] = data_format, ['id'] = created_user_id }
    is(response.status, 200)
  end

  -------------------------------------------------------------------------------------------------------------
  -- Time entries tests
  -------------------------------------------------------------------------------------------------------------
  print ('Time entries tests (' .. data_format .. ')')

  -- Check for getting all time entries
  response = redmine:list_time_entries{ ['format'] = data_format }
  is(response.status, 200)

  payload =
  {
    time_entry =
    {
      issue_id = ENV.test_issue_id ;
      hours = 10;
      activity_id = 1;
      comments = 'Some comments';
    }
  }

  -- Check for creating a time entry
  response = redmine:create_time_entries{ ['format'] = data_format, ['payload'] = payload }
  is(response.status, 201)

  local created_time_entry_id
  if is_xml then
    created_time_entry_id = response.body.time_entry.id[1]
  else
    created_time_entry_id = response.body.time_entry.id
  end

  -- Check for getting single time entry
  response = redmine:get_time_entry{ ['format'] = data_format, ['id'] = created_time_entry_id }
  is(response.status, 200)

  update_payload =
  {
    time_entry =
    {
      hours = 20;
      comments = '10 hours more';
    }
  }

  -- Check for updating a time entry
  response = redmine:update_time_entries{ ['format'] = data_format, ['id'] = created_time_entry_id, ['payload'] = update_payload }
  is(response.status, 200)

  -- Check for deleting a time entry
  response = redmine:delete_time_entry { ['format'] = data_format, ['id'] = created_time_entry_id }
  is(response.status, 200)

end

local function test_redmine_1_3(data_format) -- Tests methods that are included in Redmine API ver. 1.3
                                            -- NB! Some of tests may require administrative privilegies on Redmine server.

  local is_xml = string.lower(data_format) == 'xml'
  local base_url = os.getenv('REDMINE_BASE_URL') or "https://redmine-test.iphonestudio.ru/"
  local redmine = Spore.new_from_spec(ENV.api_description_path, { ['base_url'] = base_url })
  helper.enable_auth(redmine)
  helper.enable_format(redmine, is_xml)

  -------------------------------------------------------------------------------------------------------------
  -- Issue relations tests
  -------------------------------------------------------------------------------------------------------------
  print ('Issue relations (' .. data_format .. ')')

  -- Check for getting all issue relations
  response = redmine:list_issue_relations{ ['issue_id'] = ENV.test_issue_id, ['format'] = data_format }
  is(response.status, 200)

  payload =
  {
    relation =
    {
      issue_to_id = ENV.related_test_issue_id;
      relation_type = "relates";
    }
  }

  -- Check for creating an issue relation
  response = redmine:create_issue_relation{ ['issue_id'] = ENV.test_issue_id, ['format'] = data_format, ['payload'] = payload }
  is(response.status, 201)

  local created_issue_relation_id
  if is_xml then
    created_issue_relation_id = response.body.relation.id[1]
  else
    created_issue_relation_id = response.body.relation.id
  end

  -- Check for deleting an issue relation
  response = redmine:delete_issue_relation{ ['format'] = data_format, ['id'] = created_issue_relation_id }
  is(response.status, 200)

  -------------------------------------------------------------------------------------------------------------
  -- Versions tests
  -------------------------------------------------------------------------------------------------------------
  print ('Versions tests (' .. data_format .. ')')

  -- Check for getting all versions
  response = redmine:list_versions{ ['format'] = data_format, ['project_id'] = ENV.test_project_id }
  is(response.status, 200)

  payload =
  {
    version =
    {
      name = 'Test project version';
      description = 'This version is created by test script for Redmine API';
    }
  }

  -- Check for creating a version
  response = redmine:create_version{ ['format'] = data_format, ['project_id'] = ENV.test_project_id, ['payload'] = payload }
  is(response.status, 201)

  local created_version_id
  if is_xml then
    created_version_id = response.body.version.id[1]
  else
    created_version_id = response.body.version.id
  end

  -- Check for getting single version
  response = redmine:get_version{ ['format'] = data_format, ['id'] = created_version_id }
  is(response.status, 200) -- 401 for some mysterious reason

  update_payload =
  {
    version =
    {
      description = 'Description was changed by test script for Redmine API';
    }
  }

  -- Check for updating a version
  response = redmine:update_version{ ['format'] = data_format, ['id'] = created_version_id, ['payload'] = update_payload }
  is(response.status, 200)

  -- Check for deleting a version
  response = redmine:delete_version{ ['format'] = data_format, ['id'] = created_version_id }
  is(response.status, 200)

  -------------------------------------------------------------------------------------------------------------
  -- Queries tests
  -------------------------------------------------------------------------------------------------------------
  print ('Queries tests (' .. data_format .. ')')

  -- Check for getting all queries
  response = redmine:list_queries{ ['format'] = data_format }
  is(response.status, 200)

  -------------------------------------------------------------------------------------------------------------
  -- Attachments tests
  -------------------------------------------------------------------------------------------------------------
  print ('Attachments tests (' .. data_format .. ')')

  -- Check for getting single attachment
  response = redmine:get_attachment{ ['format'] = data_format, ['id'] = ENV.test_attachment_id }
  is(response.status, 200)

end

-------------------------------------------- Run all tests ----------------------------------------------------
plan(64)
helper.check_libs();
test_redmine_1_1('xml')
test_redmine_1_1('json')
print 'Attention! The folowing tests require Redmine v.1.3.'
local version = os.getenv('REDMINE_VERSION')
if not version or version:match'^%s*$' then
  print 'REDMINE_VERSION variable in your environment should be set to "1.3"'
  skip_rest('Redmine v.1.3 is required')
  os.exit()
end
test_redmine_1_3('xml')
test_redmine_1_3('json')


--[[ TODO list for futher improvements

1) Test all variants for getting issues with a filter.
GET /issues.xml?project_id=2
GET /issues.xml?project_id=2&tracker_id=1
GET /issues.xml?assigned_to_id=6
GET /issues.xml?status_id=closed
GET /issues.xml?status_id=*

2) Test getting issues with a paging.
GET /issues.xml?project_id=testproject&query_id=2&offset=50&limit=100

3) Test getting users with 'include' param
GET /users/3.xml?include=memberships

4) Improve the test, so that it won't require pre-created objects on Redmine server. Now it requires a project, two issues and an attachment.

5) Fix the issue with getting single version (line 362)

6) Improve the test, so that it won't break down due to possible external errors (like insufficient access rights, absence of environment variables and the like).
]]
