#Objectives

- Teach students how to do basic authentication with Rails
- Teach students how to authorize different users to take different actions in the system
- Reinforce previous lessons in rapidly building apps

--

## Understanding Rails Authentication and Authorization using BandBlitz
This lab will serve as an introduction to working with sessions, authentication, and authorization using the Ruby on Rails framework.

### Part 1: Sessions and Authentication

1. We are going to be working with a project known as BandBlitz.  This app allows for bands to post information about themselves as well as a small musical sample.  It also allows guests to post comments about the band for others to see.  Unregistered users can read everything, but can only post comments.  If a band manager is made a user, he/she can update the band's information and remove the band from BandBlitz if they so desire.  Regular band members can update the information, but cannot delete the band's entry.  Administrators can do it all – all CRUD operations on both bands and genres and is the only user that can delete a comment left for a band (in case there is libel, obscene remarks, etc.).  Begin by getting the base project code off of github with the following command:

  ```git
      git clone https://github.com/67-272-Q/lab10-bandblitz-starter.git
  ```

  Once you get the code, run `bundle install` to get the gems such as [CanCanCan](https://github.com/CanCanCommunity/cancancan) we will need for this lab.

2. We want to add authorization, but we must first begin by adding authentication.  To do this, create a user model with the following attributes: 

    **User**
    first_name (string)
    last_name (string)
    email (string)
    role (string)
    password_digest (string)
    band_id (integer)
    active (boolean) 
 
    (Use `rails generate model` for now; some user views you will need are already included in starter files.) In the migration set the default value of `role` to "member" and the default value of `active` to true.  Run `rails db:migrate` to capture these changes.

3. In the `User` model, create a relationship to `Band` (and likewise from `Band` to `User`). Note a band `has_many` users and a user `belongs_to` a band.

4. We also want to use Rails' built-in password management, so add the line `has_secure_password` to your User model as well.  This will create the password-digest, but you will need the bcrypt gem for this to work (make sure it's in your `Gemfile`).  Add appropriate validation to this model as well as a name method called `proper_name` which concatenates the user's first and last names. For validations consider that `first_name`, `last_name`, and `email` must be present, `email` is unique and `email` follows an email regex pattern (such as the one in PATS).  

    As an option, you can also add the following class method to handle logging in via email and use this method later in the sessions_controller (this was demoed in class last week and we'll point out where it would go later in the lab):

  ```ruby
    def self.authenticate(email,password)
      find_by_email(email).try(:authenticate, password)
    end
  ```

  Quick question: you are saving your work to git, right?

5. We are going to go to the ApplicationController (controllers/application_controller.rb) and add some methods we want all controllers to have for authentication purposes.  The first will be the `current_user`, which we will draw from the session hash (if it is saved... will do that in a moment).  We also want to make this a helper method so that our views can access it as well.  We will created a `logged_in?` method which simply tells us if you are logged in (true if you have a user_id in session hash, i.e., a current_user).  Finally, we will have a method called `check_login` that we can use as an additional before_action in other controllers.  The code would be as follows:

  ```ruby
    private
    def current_user
      @current_user ||= User.find(session[:user_id]) if session[:user_id]
    end
    helper_method :current_user
  
    def logged_in?
      current_user
    end
    helper_method :logged_in?
  
    def check_login
      redirect_to login_url, alert: "You need to log in to view this page." if current_user.nil?
    end
  ```

6. Now that we have a `check_login` method in ApplicationController, every other controller will also have it because they inherit from ApplicationController.  

    To use this method set up an additional `before_action` to require `check_login` be run before any action in the GenresController, and before all actions except index and show in the BandsController. See the [Rails Guide](http://guides.rubyonrails.org/action_controller_overview.html#filters) for more information on filters if you are unsure of how to do this.

7. We need to set up a UsersController and it will be much like our standard controllers with the following exceptions:

  a) We only need new, edit, create, and update actions this simple app (you can add more if you like, but will also need to add views)
  b) `edit` and `update` should get initial object from `current_user` method, not an id parameter passed in
  c) When a new user is saved during the create method, the user_id should be added to the session hash: `session[:user_id] = @user.id` and the user should be redirected to `home_path`
  d) In the private `user_params` method, allow all attributes except `:password_digest` and replace that with `:password` and `:password_confirmation`
  e) In the `new` method, be sure to set @user = User.new

  To do this, **DO NOT** run the rails generator as you will overwrite the view files I've given you.  Just create an empty file called `users_controller.rb` and build this controller manually. (Not hard; look at past projects/labs if you are unsure how to do this.)

8. We also need a SessionsController to handle logging in for users who already exist in the system. Create this file from scratch as well.  

    We need a new method which is essentially blank, but let's the user get a login form (provided).  We need a create method which tries to authenticate and if successful sets the user_id in session.  Finally, we need a destroy method for logout which destroys the user_id in session (clearing the session).  In the interest of time, the code for all this can be seen below:

  ```ruby
    class SessionsController < ApplicationController
      def new
      end
  
      def create
        user = User.find_by_email(params[:email])
        if user && user.authenticate(params[:password])
          session[:user_id] = user.id
          redirect_to home_path, notice: "Logged in!"
        else
          flash.now.alert = "Email or password is invalid"
          render "new"
        end
      end
  
      def destroy
        session[:user_id] = nil
        redirect_to home_path, notice: "Logged out!"
      end
    end
  ```

  Note: if you created the class method earlier in the User model, you could use that instead to rewrite/replace the first two lines of the create action.  This is optional, but it would be a good learning exercise at some point to do this and make sure you have a good grasp of what is happening when creating a user's session.

9. Now we have controllers and the views were already given to us, but without routes these controllers will never be called.  So go to `config/routes.rb` and add the following routes:

  ```ruby
    resources :users
    resources :sessions
    get 'user/edit' => 'users#edit', :as => :edit_current_user
    get 'signup' => 'users#new', :as => :signup
    get 'login' => 'sessions#new', :as => :login
    get 'logout' => 'sessions#destroy', :as => :logout

    # Default route
    root :to => 'bands#index', :as => :home
  ```

  Now run `rails routes` from the terminal to update the routes.

10. Now we will add a default user (admin) to the system using migrations (since all new sign-ups are going to be members only unless an admin is signing them up and chooses a different level).  An example of the up and down methods for this migration are below; create a new migration with `rails generate migration [NAME]` (remove the change method in this new migration) and add these methods:

  ```ruby
    def up
      adminBand = Band.new
      adminBand.name = "Admin Band"
      adminBand.description = "An initial band to create users"
      adminBand.save
      admin = User.new
      admin.first_name = "Admin"
      admin.last_name = "Admin"
      admin.email = "admin@example.com"
      admin.band_id = adminBand.id
      admin.password = "secret"
      admin.password_confirmation = "secret"
      admin.role = "admin"
      admin.save
    end
    def down
      admin = User.find_by_email "admin@example.com"
      User.delete admin
      band = Band.find_by_name "Admin Band"
      Band.delete band
    end
  ```

  Now run `rails db:migrate` to get this user into the system.

11. Now we will test this out by attempting to log in as the default user. Start the server and try to log-in with the email and password we have in the migration (navigate to /login). This seems to work (you get a flash message saying 'Logged in!') but it would be nice to add some personal information to the page.  In the application layout file, add to the div id="login" the following and reload the page to verify:

  ```erb
    <% if logged_in? %>
      <%= link_to 'Logout', logout_path %>
      <br>[<%= current_user.proper_name %>:<%= current_user.role %>]
    <% else %>
      <%= link_to 'Login', login_path %>
    <% end %>
  ```

- - -
# <span class="mega-icon mega-icon-issue-opened"></span> Stop
Show a TA that you have the authentication functionality set up and working as instructed and that the code is properly saved to git. Make sure the TA initials your sheet.
- - -

### Part 2: Authorization

1. With authentication under our belts, let's tackle the issue of authorization.  We will be using the CanCan gem to help with this; feel free to open the [documentation for this gem](https://github.com/CanCanCommunity/cancancan) and reference it if you have questions.  Using CanCan we will first tell Rails what each user role can do in the system (stored in a file called 'ability') and then test in our controllers and/or views whether that user can? access selected functions on the app.  

2. We will start by defining some abilities.  The cancan gem is looking for a model file called 'ability.rb' located in `app/models`.  Let's create this file by running on the command line `rails generate cancan:ability`.  

    Looking at this file in the models directory, you can see it is an example of a non-ActiveRecord model.  (Most, but not all models inherit from ActiveRecord.  Since abilities are defined in that file, there is no need for database access so we don't need the power of ActiveRecord.)  The initialize method is there (with lots of helpful comments), but we need to add some basic abilities.  We also see that the method takes a user as an argument, but what if someone is not logged in yet?  Will it blow up in our face?  

    To prevent this, we add the line `user ||= User.new` to the initialize method.

3. Now it is time to add the all-powerful admin user; admins can do everything and guests can only read for now.  To make this happen, add the following code to the initialize method:
  ```ruby
    if user.role? :admin
      can :manage, :all
    else
      can :read, :all
    end
  ```

  The user model needs a method called `role?` that compares a user's role in the system with the role we are testing for.  So this can all work properly, add the following code to the User model: 

  ```ruby
    ROLES = [['Administrator', :admin],['Band Manager', :manager],['Band Member', :member]]
  
    def role?(authorized_role)
      return false if role.nil?
      role.to_sym == authorized_role
    end
  ```

  Now an admin can 'manage' (run all CRUD operations) for all models while guests can only read content (but again for all models). 

4. Now that we have this simple authorization in place, time to go put constraints on the controllers so they don't give the user access to app functionality they aren't entitled to.

    Open the band controller and add to the top of the `new` action the following line: `authorize! :new, @band`.  What this is doing is raising an exception if the user does not have the ability to create a new band.  

    We will add the same line to the create method just in case someone is trying to add a new band without going through the interface (we will learn about this soon enough).  

    In the edit and update methods add the line `authorize! :update, @band` to the update method and `authorize! :destroy, @band` to the destroy method. You will need to comment out check_login `before_action` callback to make sure that CanCan can do its job (otherwise, you will hit the `before_action` and get redirected before the `authorize!` command is called). 

5. Test out your work by logging in as an admin (small login link in upper right corner) and see that you can access everything.  Logout and try to access restricted functionality (go to bands/new); you should get a `CanCan::AccessDenied` exception.  If do not get this exception, please see a TA for assistance before going on further.  Now we need to add similar restraints to the genre controller (try it and see that access is unrestricted), but you realize this could be tedious for a larger project to do this for every action in every controller.  Not to worry, CanCan has a shortcut for us; add to the top of the genres_controller  `authorize_resource` and it will be as if you added the `authorize!` method to each action in the controller. Note here, you will simply now just be redirected to the login action because `authorize_resource` handles these exceptions nicely.

6. Let's fix up that exception page – informative to developers, but not appropriate for general users.  Go to the Application controller and add the following code into `private` (but not in a specific method) to fix up certain cases where the user is logged in but does not have appropriate authorization:

  ```ruby
    rescue_from CanCan::AccessDenied do |exception|
      flash[:error] = "Go away or I shall taunt you a second time."
      redirect_to home_path
    end
  ```
  If you don't like [Monty Python](https://www.youtube.com/watch?v=A8yjNbcKkNY) or you just want to follow some of the design principles discussed in class, you can change the text to a more appropriate message.  [Quick: what is wrong with this message?  If you don't immediately know the answer, go back and review your design notes and book.]

7. Time to clean up the views a bit.  We know that from our design principles, if the user doesn't have access to certain functionality, it is better not to display these options.  [Again: why?  What design principles specifically are being violated?  You should know this and if not, go back and study.]  Go to the index page of the bands view and you will notice that there are three sets of comments telling us to essentially replace with some type of access control.  For the first one – edit icon and link – wrap the line in the following:

  ```erb
    <% if can? :update, band %>
      <%= link_to ... %>
    <% end %>
  ```

  What we are doing here is testing whether the user has the access rights of the user to see if he/she has the ability to update this particular band.  Add a similar control to the delete icon and link.  After that, fix the new band link with the following at the end:

  ```erb
    <% if can? :create, Band %>
      <p><%= link_to "Create New Band", new_band_path %></p>
    <% end %>
  ```

5. This is nice, but what about managers and members?  They have partial access to update|destroy, but only for their own band.  To do this, we have to modify 'ability.rb' to include these users.  In the file after the admin is defined, but before the `else` that sets the guest users, add the following:

  ```ruby
    elsif user.role? :manager
      can :update, Band do |band|  
        band.id == user.band_id
      end
      can :destroy, Band do |band|  
        band.id == user.band_id
      end
    elsif user.role? :member
      can :update, Band do |band|  
        band.id == user.band_id
      end
  ```

  What this says in each case is that the user (manager or member) has the ability to perform the operation specified on Band objects if the id of the band equals the user's band_id.  Now if you log in as a manager **[you'll need to first create genres, then a band, and then manager and members]**, you should see links for editing/deleting the band, but not for others.  Likewise, logging in as a member should show the update functionality for the band is there and working, but others are not.  Get the TA to verify this and mark off the checkpoint.

- - -
# <span class="mega-icon mega-icon-issue-opened"></span> Stop
Show a TA that you have the authorization functionality set up for all three user types and working as instructed and that the code is properly saved to git. Make sure the TA initials your sheet.
- - -

### Part 3: General Users

If time allows during lab, challenge yourself by extending this project – add the ability of anyone (even guests) to write comments about a particular band.  [This will require a Comment model and appropriate support from views and controllers.] Comments should be displayed only on the band's show details page and place a form for new comments should be there as well.  Comments may be deleted only by an admin.  (You shouldn't even see the option if you are not an admin.)  Again this is optional but an excellent exercise when you have the time, but not essential for today.