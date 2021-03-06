class User < ActiveRecord::Base

  hobo_user_model # Don't put anything above this

  fields do
    username :string, :login => true, :name => true
    email_address :email_address
    administrator :boolean, :default => false
    timestamps
  end

  # This gives admin rights to the first sign-up.
  # Just remove it if you don't want that
  before_create { |user| user.administrator = true if count == 0 }
  
  has_many :task_assignments, :dependent => :destroy
  has_many :tasks, :through => :task_assignments
  
  has_many :projects, :foreign_key => "owner_id"

	has_many :project_memberships, :dependent => :destroy
  has_many :joined_projects, :through => :project_memberships, :source => :project

  
  # --- Signup lifecycle --- #

  lifecycle do

    initial_state :active
    
    create :anybody, :signup, 
           :params => [:username, :email_address, :password, :password_confirmation],
           :become => :active,
           :if => proc {|_, u| u.guest?}

    transition :nobody, :request_password_reset, { :active => :active }, :new_key => true do
      UserMailer.deliver_forgot_password(self, lifecycle.key)
    end

    transition :with_key, :reset_password, { :active => :active }, 
               :update => [ :password, :password_confirmation ]

  end
  

  # --- Hobo Permissions --- #

  def creatable_by?(creator)
    creator.administrator? || !administrator
  end

  def updatable_by?(updater, new)
    updater.administrator? || (updater == self && only_changed_fields?(new, :password, :password_confirmation))
  end

  def deletable_by?(deleter)
    deleter.administrator?
  end

  def viewable_by?(viewer, field)
    true
  end

end
