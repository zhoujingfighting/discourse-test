# name:  discourse-omniauth-gitlab
# about: Authenticate Discourse with GitLab
# version: 0.0.5
# author: Achilleas Pipinellis
# url: https://gitlab.com/gitlab-org/discourse-omniauth-gitlab

gem 'omniauth-gitlab', '1.0.2'

class GitLabAuthenticator < ::Auth::Authenticator

  GITLAB_APP_ID = "a1ff9f52e9a4516233159df812eaf7fdf261b6f90bf968d35d15ea73a3ae29ed"
  GITLAB_SECRET = "d76be55cecfcee7fbd5cf5311045b5638abc000fdc03f25fae870155b925bf69"

  def name
    'gitlab'
  end

  def after_authenticate(auth_token)
    result = Auth::Result.new

    # Grap the info we need from OmniAuth
    data = auth_token[:info]
    name = data["first_name"]
    gl_uid = auth_token["uid"]
    email = data['email']

    # Plugin specific data storage
    current_info = ::PluginStore.get("gl", "gl_uid_#{gl_uid}")

    # Check if the user is trying to connect an existing account
    unless current_info
      existing_user = User.joins(:user_emails).find_by(user_emails: { email: email })
      if existing_user
        ::PluginStore.set("gl", "gl_uid_#{data[:gl_uid]}", {user_id: existing_user.id })
        result.user = existing_user
      end
    else
      result.user = User.where(id: current_info[:user_id]).first
    end

    result.name  ||= name
    result.email ||= email
    result.extra_data = { gl_uid: gl_uid }

    result
  end

  def after_create_account(user, auth)
    data = auth[:extra_data]
    ::PluginStore.set("gl", "gl_uid_#{data[:gl_uid]}", {user_id: user.id })
  end

  def register_middleware(omniauth)
    omniauth.provider :gitlab,
     GITLAB_APP_ID,
     GITLAB_SECRET,
     {
       client_options:
       {
         site: "https://gitlab.com"
       }
     }
  end
end


auth_provider title: 'with GitLab11',
    message: 'Log in via GitLab (Make sure pop up blockers are not enabled).',
    frame_width: 920,
    frame_height: 800,
    authenticator: GitLabAuthenticator.new

# Use the fontawesome unicode for GitLab
# https://fontawesome.com/icons/gitlab?style=brands
register_css <<CSS

.btn-social.gitlab {
  background: #554488;
}

.btn-social.gitlab:before {
  content: "\f296";
}

CSS

