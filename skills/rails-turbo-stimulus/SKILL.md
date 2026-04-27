---
name: rails-turbo-stimulus
description: Hotwire patterns for Rails applications. Implement Turbo Frames, Turbo Streams, Stimulus controllers, and real-time features without writing JavaScript frameworks.
category: rails
version: 1.0.0
author: Claude
tags:
  - rails
  - hotwire
  - turbo
  - stimulus
  - javascript
  - real-time
dependencies:
  - rails >= 7.0
  - hotwire-rails
---

# Rails Turbo & Stimulus

A comprehensive guide for building modern, reactive Rails applications using Hotwire (Turbo and Stimulus). Create fast, interactive interfaces with minimal JavaScript by leveraging server-rendered HTML and progressive enhancement.

## Use this skill when

- Building interactive user interfaces in Rails
- Implementing real-time features without WebSocket frameworks
- Creating single-page-app experiences with server-rendered HTML
- Adding inline editing and live updates
- Implementing drag-and-drop functionality
- Building interactive forms with validation
- Creating modals and slide-overs without jQuery
- Implementing infinite scroll and pagination
- Adding auto-save functionality
- Creating dynamic search and filtering
- Building live notifications
- Implementing chat features
- Creating collaborative editing features

## Do not use this skill when

- Building a completely separate frontend (use React/Vue)
- The application requires complex client-side state management
- You need offline-first capabilities
- The team prefers traditional JavaScript frameworks
- The application is API-only without HTML views

## Prerequisites

- Rails 7.0+ with Hotwire installed
- Understanding of HTML, CSS, and basic JavaScript
- Familiarity with Rails views and partials
- Understanding of HTTP request/response cycle

## Core Concepts

### Hotwire Components

1. **Turbo Drive**: Faster navigation by replacing `<body>` content
2. **Turbo Frames**: Independent page regions that can be updated separately
3. **Turbo Streams**: Append, prepend, replace, remove, and update page elements
4. **Stimulus**: JavaScript framework for sprinkles of behavior

### Turbo Drive

Automatically converts link clicks and form submissions into AJAX requests, replacing the `<body>` content without full page reloads.

### Turbo Frames

Define independent regions of a page that can be navigated and updated separately. Perfect for modals, inline editing, and lazy-loaded content.

### Turbo Streams

Send targeted updates to specific parts of the page. Actions include:
- `append` - Add content to end of target
- `prepend` - Add content to beginning of target
- `replace` - Replace entire target
- `update` - Replace target's content
- `remove` - Remove target from page
- `before` - Insert content before target
- `after` - Insert content after target

### Stimulus

JavaScript framework that connects HTML to JavaScript controllers through data attributes. Philosophy: "sprinkle" behavior onto HTML.

## Step-by-Step Implementation

### Step 1: Install Hotwire

```ruby
# Gemfile
gem 'turbo-rails'
gem 'stimulus-rails'
```

```bash
bundle install
rails turbo:install stimulus:install
```

### Step 2: Basic Turbo Frames

#### Inline Editing with Turbo Frames

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  validates :title, presence: true
  validates :body, presence: true
end
```

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update]

  def show
  end

  def edit
    render :edit, layout: false if turbo_frame_request?
  end

  def update
    if @post.update(post_params)
      redirect_to @post
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :body)
  end

  def turbo_frame_request?
    request.headers['Turbo-Frame'].present?
  end
end
```

```erb
<!-- app/views/posts/show.html.erb -->
<div class="post">
  <%= turbo_frame_tag @post do %>
    <h1><%= @post.title %></h1>
    <div class="post-body">
      <%= simple_format @post.body %>
    </div>
    <%= link_to "Edit", edit_post_path(@post), class: "btn" %>
  <% end %>
</div>
```

```erb
<!-- app/views/posts/edit.html.erb -->
<%= turbo_frame_tag @post do %>
  <%= form_with model: @post do |f| %>
    <div class="field">
      <%= f.label :title %>
      <%= f.text_field :title, class: "form-control" %>
      <% if @post.errors[:title].any? %>
        <div class="error"><%= @post.errors[:title].first %></div>
      <% end %>
    </div>

    <div class="field">
      <%= f.label :body %>
      <%= f.text_area :body, rows: 10, class: "form-control" %>
      <% if @post.errors[:body].any? %>
        <div class="error"><%= @post.errors[:body].first %></div>
      <% end %>
    </div>

    <div class="actions">
      <%= f.submit "Save", class: "btn btn-primary" %>
      <%= link_to "Cancel", post_path(@post), class: "btn btn-secondary" %>
    </div>
  <% end %>
<% end %>
```

**How it works:**
1. Click "Edit" link
2. Turbo Frame loads `edit_post_path` via AJAX
3. Only the content inside matching `turbo_frame_tag` is replaced
4. On save, form submits via AJAX and frame is updated
5. No full page reload required

#### Lazy Loading with Turbo Frames

```erb
<!-- app/views/posts/show.html.erb -->
<div class="post">
  <h1><%= @post.title %></h1>
  <%= simple_format @post.body %>

  <!-- Comments are lazy-loaded -->
  <%= turbo_frame_tag "comments", src: post_comments_path(@post), loading: :lazy do %>
    <p>Loading comments...</p>
  <% end %>
</div>
```

```ruby
# config/routes.rb
resources :posts do
  resources :comments, only: [:index, :create]
end
```

```ruby
# app/controllers/comments_controller.rb
class CommentsController < ApplicationController
  before_action :set_post

  def index
    @comments = @post.comments.includes(:user).order(created_at: :desc)
    render layout: false if turbo_frame_request?
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end
end
```

```erb
<!-- app/views/comments/index.html.erb -->
<%= turbo_frame_tag "comments" do %>
  <div class="comments">
    <h3><%= pluralize(@comments.count, 'Comment') %></h3>
    <%= render @comments %>
    <%= render 'comments/form', post: @post %>
  </div>
<% end %>
```

### Step 3: Turbo Streams for Real-Time Updates

#### Adding Comments with Turbo Streams

```ruby
# app/controllers/comments_controller.rb
class CommentsController < ApplicationController
  before_action :set_post

  def create
    @comment = @post.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @post }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @comment = @post.comments.find(params[:id])
    @comment.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @post }
    end
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
```

```erb
<!-- app/views/comments/_form.html.erb -->
<%= form_with model: [post, Comment.new], class: "comment-form" do |f| %>
  <div class="field">
    <%= f.text_area :body, placeholder: "Add a comment...", rows: 3 %>
  </div>
  <%= f.submit "Post Comment", class: "btn btn-primary" %>
<% end %>
```

```erb
<!-- app/views/comments/_comment.html.erb -->
<%= turbo_frame_tag dom_id(comment) do %>
  <div class="comment">
    <div class="comment-header">
      <strong><%= comment.user.name %></strong>
      <span class="timestamp"><%= time_ago_in_words(comment.created_at) %> ago</span>
    </div>
    <div class="comment-body">
      <%= simple_format comment.body %>
    </div>
    <% if current_user == comment.user %>
      <%= button_to "Delete",
                    post_comment_path(comment.post, comment),
                    method: :delete,
                    class: "btn btn-sm btn-danger",
                    form: { data: { turbo_confirm: "Are you sure?" } } %>
    <% end %>
  </div>
<% end %>
```

```erb
<!-- app/views/comments/create.turbo_stream.erb -->
<%= turbo_stream.prepend "comments", partial: "comments/comment", locals: { comment: @comment } %>
<%= turbo_stream.replace "comment-form", partial: "comments/form", locals: { post: @post } %>
```

```erb
<!-- app/views/comments/destroy.turbo_stream.erb -->
<%= turbo_stream.remove dom_id(@comment) %>
```

#### Broadcasting Updates to Multiple Users

```ruby
# app/models/comment.rb
class Comment < ApplicationRecord
  belongs_to :post
  belongs_to :user

  after_create_commit -> { broadcast_prepend_to post, target: "comments" }
  after_update_commit -> { broadcast_replace_to post }
  after_destroy_commit -> { broadcast_remove_to post }
end
```

```erb
<!-- app/views/posts/show.html.erb -->
<div class="post">
  <%= turbo_stream_from @post %>

  <h1><%= @post.title %></h1>
  <%= simple_format @post.body %>

  <div id="comments">
    <%= render @post.comments %>
  </div>

  <%= render 'comments/form', post: @post %>
</div>
```

**How it works:**
1. User A and User B are viewing the same post
2. User A creates a comment
3. `after_create_commit` broadcasts to the post channel
4. User B's page automatically receives the update via ActionCable
5. New comment appears in real-time without refresh

### Step 4: Stimulus Controllers

#### Toggle Controller

```javascript
// app/javascript/controllers/toggle_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]
  static classes = ["hidden"]

  toggle() {
    this.contentTarget.classList.toggle(this.hiddenClass)
  }

  show() {
    this.contentTarget.classList.remove(this.hiddenClass)
  }

  hide() {
    this.contentTarget.classList.add(this.hiddenClass)
  }
}
```

```erb
<!-- Usage -->
<div data-controller="toggle" data-toggle-hidden-class="hidden">
  <button data-action="click->toggle#toggle" class="btn">
    Toggle Details
  </button>

  <div data-toggle-target="content" class="hidden">
    <p>These are the details that can be toggled.</p>
  </div>
</div>
```

#### Dropdown Controller

```javascript
// app/javascript/controllers/dropdown_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]
  static classes = ["active"]

  toggle(event) {
    event.stopPropagation()
    this.menuTarget.classList.toggle(this.activeClass)
  }

  hide(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.remove(this.activeClass)
    }
  }

  connect() {
    this.boundHide = this.hide.bind(this)
    document.addEventListener("click", this.boundHide)
  }

  disconnect() {
    document.removeEventListener("click", this.boundHide)
  }
}
```

```erb
<!-- Usage -->
<div data-controller="dropdown" data-dropdown-active-class="active">
  <button data-action="click->dropdown#toggle" class="dropdown-trigger">
    Options ▼
  </button>

  <div data-dropdown-target="menu" class="dropdown-menu">
    <%= link_to "Edit", edit_path, class: "dropdown-item" %>
    <%= link_to "Delete", delete_path, method: :delete, class: "dropdown-item" %>
  </div>
</div>
```

#### Autosave Controller

```javascript
// app/javascript/controllers/autosave_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    interval: { type: Number, default: 2000 }
  }
  static targets = ["status"]

  connect() {
    this.timeout = null
  }

  save() {
    clearTimeout(this.timeout)
    
    this.timeout = setTimeout(() => {
      this.submitForm()
    }, this.intervalValue)
  }

  async submitForm() {
    this.showStatus("Saving...")

    const formData = new FormData(this.element)

    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        body: formData,
        headers: {
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
          "Accept": "application/json"
        }
      })

      if (response.ok) {
        this.showStatus("Saved ✓", "success")
      } else {
        this.showStatus("Error saving", "error")
      }
    } catch (error) {
      this.showStatus("Error saving", "error")
    }
  }

  showStatus(message, type = "info") {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message
      this.statusTarget.className = `status ${type}`
      
      if (type === "success") {
        setTimeout(() => {
          this.statusTarget.textContent = ""
        }, 2000)
      }
    }
  }
}
```

```erb
<!-- Usage -->
<%= form_with model: @post,
              data: {
                controller: "autosave",
                autosave_url_value: post_path(@post),
                action: "input->autosave#save"
              } do |f| %>
  
  <div data-autosave-target="status" class="status"></div>

  <%= f.text_field :title, class: "form-control" %>
  <%= f.text_area :body, rows: 10, class: "form-control" %>
<% end %>
```

#### Search Controller with Debounce

```javascript
// app/javascript/controllers/search_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results"]
  static values = {
    url: String,
    delay: { type: Number, default: 300 }
  }

  connect() {
    this.timeout = null
  }

  search() {
    clearTimeout(this.timeout)
    
    this.timeout = setTimeout(() => {
      this.performSearch()
    }, this.delayValue)
  }

  async performSearch() {
    const query = this.inputTarget.value

    if (query.length < 2) {
      this.resultsTarget.innerHTML = ""
      return
    }

    const url = new URL(this.urlValue)
    url.searchParams.set("q", query)

    try {
      const response = await fetch(url, {
        headers: {
          "Accept": "text/html"
        }
      })

      if (response.ok) {
        const html = await response.text()
        this.resultsTarget.innerHTML = html
      }
    } catch (error) {
      console.error("Search failed:", error)
    }
  }

  clear() {
    this.inputTarget.value = ""
    this.resultsTarget.innerHTML = ""
  }
}
```

```erb
<!-- Usage -->
<div data-controller="search" data-search-url-value="<%= search_posts_path %>">
  <input type="text"
         data-search-target="input"
         data-action="input->search#search"
         placeholder="Search posts..."
         class="form-control">

  <div data-search-target="results" class="search-results"></div>
</div>
```

### Step 5: Advanced Patterns

#### Modal with Turbo Frames

```javascript
// app/javascript/controllers/modal_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  open() {
    this.containerTarget.classList.remove("hidden")
    document.body.classList.add("modal-open")
  }

  close(event) {
    if (event.target === this.containerTarget || event.target.closest("[data-action='click->modal#close']")) {
      this.containerTarget.classList.add("hidden")
      document.body.classList.remove("modal-open")
    }
  }

  closeWithKeyboard(event) {
    if (event.key === "Escape") {
      this.close(event)
    }
  }

  connect() {
    this.boundCloseWithKeyboard = this.closeWithKeyboard.bind(this)
    document.addEventListener("keydown", this.boundCloseWithKeyboard)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundCloseWithKeyboard)
  }
}
```

```erb
<!-- app/views/shared/_modal.html.erb -->
<div data-controller="modal"
     data-action="turbo:frame-load->modal#open"
     class="modal-backdrop hidden"
     data-modal-target="container">
  
  <div class="modal-content">
    <button data-action="click->modal#close" class="modal-close">×</button>
    <%= turbo_frame_tag "modal" %>
  </div>
</div>
```

```erb
<!-- app/views/posts/index.html.erb -->
<%= render 'shared/modal' %>

<div class="posts">
  <% @posts.each do |post| %>
    <div class="post-card">
      <h3><%= post.title %></h3>
      <%= link_to "View", post_path(post), data: { turbo_frame: "modal" } %>
    </div>
  <% end %>
</div>
```

```erb
<!-- app/views/posts/show.html.erb -->
<%= turbo_frame_tag "modal" do %>
  <h1><%= @post.title %></h1>
  <%= simple_format @post.body %>
  
  <div class="modal-actions">
    <%= link_to "Edit", edit_post_path(@post) %>
    <%= button_to "Delete", post_path(@post), method: :delete, data: { turbo_confirm: "Sure?" } %>
  </div>
<% end %>
```

#### Infinite Scroll

```javascript
// app/javascript/controllers/infinite_scroll_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["entries", "pagination"]

  scroll() {
    const nextPage = this.paginationTarget.querySelector("a[rel='next']")
    
    if (nextPage == null) return

    const url = nextPage.href
    
    const windowBottom = window.pageYOffset + window.innerHeight
    const paginationTop = this.paginationTarget.offsetTop

    if (windowBottom > paginationTop) {
      this.loadMore(url)
    }
  }

  async loadMore(url) {
    const response = await fetch(url, {
      headers: {
        "Accept": "text/html"
      }
    })

    if (response.ok) {
      const html = await response.text()
      const template = document.createElement("template")
      template.innerHTML = html

      const entries = template.content.querySelector("[data-infinite-scroll-target='entries']")
      const pagination = template.content.querySelector("[data-infinite-scroll-target='pagination']")

      if (entries) {
        this.entriesTarget.insertAdjacentHTML("beforeend", entries.innerHTML)
      }

      if (pagination) {
        this.paginationTarget.innerHTML = pagination.innerHTML
      }
    }
  }
}
```

```erb
<!-- app/views/posts/index.html.erb -->
<div data-controller="infinite-scroll" data-action="scroll@window->infinite-scroll#scroll">
  <div data-infinite-scroll-target="entries">
    <%= render @posts %>
  </div>

  <div data-infinite-scroll-target="pagination">
    <%= paginate @posts %>
  </div>
</div>
```

## Best Practices

### 1. Use Turbo Frames for Independent Page Sections

```erb
<!-- Good: Each section is independent -->
<%= turbo_frame_tag "user_profile" do %>
  <%= render 'users/profile', user: @user %>
<% end %>

<%= turbo_frame_tag "user_posts" do %>
  <%= render 'posts/list', posts: @user.posts %>
<% end %>
```

### 2. Keep Stimulus Controllers Small and Focused

```javascript
// Good: Single responsibility
class ToggleController extends Controller {
  toggle() {
    this.element.classList.toggle(this.hiddenClass)
  }
}

// Bad: Too many responsibilities
class MegaController extends Controller {
  toggle() { }
  validate() { }
  submit() { }
  format() { }
  // ... too much
}
```

### 3. Use Turbo Streams for Targeted Updates

```ruby
# Good: Precise updates
def create
  @comment = @post.comments.create!(comment_params)
  
  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: [
        turbo_stream.prepend("comments", partial: "comments/comment", locals: { comment: @comment }),
        turbo_stream.replace("comment_count", partial: "posts/comment_count", locals: { post: @post })
      ]
    end
  end
end
```

### 4. Provide Fallbacks for Non-Turbo Requests

```ruby
# Good: Works with and without JavaScript
def create
  @comment = @post.comments.create!(comment_params)
  
  respond_to do |format|
    format.turbo_stream
    format.html { redirect_to @post } # Fallback
  end
end
```

### 5. Use data-turbo-permanent for Persistent Elements

```erb
<!-- Element survives Turbo Drive navigation -->
<div id="flash-messages" data-turbo-permanent>
  <%= render 'shared/flash' %>
</div>
```

## Common Mistakes

### 1. Not Matching Turbo Frame IDs

```erb
<!-- Bad: IDs don't match -->
<%= turbo_frame_tag "post_#{@post.id}" do %>
  <%= link_to "Edit", edit_post_path(@post) %>
<% end %>

<!-- In edit view -->
<%= turbo_frame_tag "post" do %> <!-- Wrong ID! -->
  ...
<% end %>

<!-- Good: IDs match -->
<%= turbo_frame_tag dom_id(@post) do %>
  <%= link_to "Edit", edit_post_path(@post) %>
<% end %>

<%= turbo_frame_tag dom_id(@post) do %>
  ...
<% end %>
```

### 2. Forgetting CSRF Tokens in Stimulus

```javascript
// Bad: No CSRF token
fetch(url, {
  method: "POST",
  body: data
})

// Good: Include CSRF token
fetch(url, {
  method: "POST",
  body: data,
  headers: {
    "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
  }
})
```

### 3. Not Cleaning Up Stimulus Event Listeners

```javascript
// Bad: Memory leak
connect() {
  document.addEventListener("click", this.handleClick)
}

// Good: Cleanup
connect() {
  this.boundHandleClick = this.handleClick.bind(this)
  document.addEventListener("click", this.boundHandleClick)
}

disconnect() {
  document.removeEventListener("click", this.boundHandleClick)
}
```

## Conclusion

Hotwire (Turbo + Stimulus) enables building modern, reactive Rails applications with minimal JavaScript. Key benefits:

- Fast, SPA-like experiences with server-rendered HTML
- Real-time updates with Turbo Streams and ActionCable
- Progressive enhancement
- Less JavaScript to write and maintain
- Better SEO than client-side rendering
- Simpler architecture

Remember: Start with Turbo Drive, add Turbo Frames for independent sections, use Turbo Streams for real-time updates, and sprinkle Stimulus for interactive behavior.
