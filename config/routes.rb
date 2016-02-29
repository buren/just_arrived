# frozen_string_literal: true
Rails.application.routes.draw do
  namespace :admin do
    resources :chats
    resources :comments
    resources :jobs
    resources :users
    resources :messages
    resources :languages
    resources :user_languages
    resources :skills
    resources :chat_users
    resources :job_skills
    resources :job_users
    resources :user_skills

    root to: 'jobs#index'
  end

  apipie
  get '/', to: redirect('/api_docs')

  namespace :api do
    namespace :v1 do
      resources :user_sessions, only: [:create, :destroy]

      resources :jobs, param: :job_id, except: [:new, :edit, :destroy] do
        member do
          get :matching_users
          resources :job_comments, module: :jobs, path: 'comments', except: [:new, :edit]
          resources :job_skills, module: :jobs, path: 'skills', except: [:new, :edit, :update]
          resources :job_users, module: :jobs, path: 'users', except: [:new, :edit]
          resources :ratings, module: :jobs, path: 'ratings', only: [:create]
        end
      end

      resources :users, param: :user_id, except: [:new, :edit] do
        member do
          resources :messages, module: :users, only: [:create, :index]

          get :matching_jobs
          get :jobs
          resources :comments, module: :users, except: [:new, :edit]
          resources :user_skills, module: :users, path: 'skills', except: [:new, :edit, :update]
          resources :user_languages, module: :users, path: 'languages', except: [:new, :edit, :update]
        end
      end

      resources :chats, except: [:new, :edit, :update, :destroy] do
        member do
          resources :messages, module: :chats, only: [:create, :index]
        end
      end

      resources :languages, except: [:new, :edit]
      resources :user_languages, except: [:new, :edit, :update]
      resources :user_skills, except: [:new, :edit]
      resources :job_skills, except: [:new, :edit]
      resources :job_users, except: [:new, :edit]
      resources :skills, except: [:new, :edit]
    end
  end
end
