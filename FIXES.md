# Prioritized Improvements

---

## P0 — Critical: Security / Architecture / Broken Patterns

These must be fixed before the project can be considered functional or safe.

---

### P0-1: Duplicate `show` action in FoldersController

**File:** `app/controllers/folders_controller.rb`

**Problem:** Two `show` actions are defined (lines 9–14 and 37–47). In Ruby, the second definition silently replaces the first. The simple version (lines 9–14) is dead code. This is a silent bug that masks intent and causes confusion during code review or debugging.

**Solution:** Remove the first (simple) `show` definition (lines 9–14). The second definition, which includes the search filter, is the intended behavior.

```ruby
# REMOVE this block (lines 9-14):
def show
  @folder = current_user.folders.find(params[:id])
  @files = @folder.stored_files
  add_breadcrumb "Folders", folders_path
  add_breadcrumb @folder.name
end

# KEEP only this version:
def show
  @folder = current_user.folders.find(params[:id])
  @files = @folder.stored_files

  if params[:query].present?
    @files = @files.where("file_name ILIKE ?", "%#{params[:query]}%")
  end

  add_breadcrumb "Folders", folders_path
  add_breadcrumb @folder.name
end
```

---

### P0-2: No full CRUD — missing `edit` and `update` actions

**File:** `app/controllers/folders_controller.rb`

**Problem:** `resources :folders` in routes generates `edit` and `update` routes, but neither action is implemented in the controller. Accessing `/folders/:id/edit` raises `AbstractController::ActionNotFound`. The rubric requires at least one resource with full CRUD.

**Solution:** Add `edit` and `update` actions to `FoldersController`.

```ruby
def edit
  @folder = current_user.folders.find(params[:id])
  add_breadcrumb "Folders", folders_path
  add_breadcrumb @folder.name, folder_path(@folder)
  add_breadcrumb "Edit"
end

def update
  @folder = current_user.folders.find(params[:id])
  if @folder.update(folder_params)
    redirect_to folders_path, notice: "Folder updated successfully."
  else
    render :edit
  end
end
```

Also create `app/views/folders/edit.html.erb` that renders the folder form partial.

---

### P0-3: Uncleaned PWA manifest placeholder

**File:** `app/views/pwa/manifest.json.erb`

**Problem:** The PWA manifest still contains the Rails 8 template defaults: `"name": "Rails8Template"`, `"theme_color": "red"`, `"description": "Rails8Template."`. This is a template placeholder that was never updated. If this app is ever installed as a PWA, it will identify itself as "Rails8Template" with a red theme.

**Solution:** Update the manifest with the actual app identity.

```json
{
  "name": "File Vault",
  "short_name": "File Vault",
  "icons": [
    { "src": "/icon.png", "type": "image/png", "sizes": "512x512" },
    { "src": "/icon.png", "type": "image/png", "sizes": "512x512", "purpose": "maskable" }
  ],
  "start_url": "/",
  "display": "standalone",
  "scope": "/",
  "description": "Secure, simple document storage.",
  "theme_color": "#000000",
  "background_color": "#ffffff"
}
```

---

## P1 — Important: Maintainability / Convention / Cleanliness

---

### P1-1: Duplicate `has_many` declarations in models

**Files:**
- `app/models/user.rb` (lines 27–28)
- `app/models/folder.rb` (lines 21 and 23)

**Problem:** Both models declare `has_many :stored_files, dependent: :destroy` twice. Rails accepts this silently but it's confusing, looks like a copy-paste error, and signals the code was not reviewed carefully.

**Solution:** Remove the duplicate line in each model.

```ruby
# user.rb — remove one of these:
has_many :stored_files, dependent: :destroy  # keep this one
has_many :stored_files, dependent: :destroy  # delete this line

# folder.rb — same fix:
has_many :stored_files, dependent: :destroy  # keep this one
has_many :stored_files, dependent: :destroy  # delete this line
```

---

### P1-2: Unused hello_controller.js

**File:** `app/javascript/controllers/hello_controller.js`

**Problem:** Sets `textContent = "Hello World!"` and is never connected to any view via `data-controller="hello"`. This is a Rails scaffold placeholder that should have been deleted.

**Solution:** Delete the file.

---

### P1-3: Orphaned `shared/_form.html.erb` partial

**File:** `app/views/shared/_form.html.erb`

**Problem:** An upload form partial that is never rendered anywhere. The active upload form is `app/views/stored_files/_form.html.erb`. Having two upload form partials with similar content causes confusion about which is canonical.

**Solution:** Delete `app/views/shared/_form.html.erb`.

---

### P1-4: Inline `<script>` tag in view should be a Stimulus controller

**File:** `app/views/folders/show.html.erb` (lines 72–82)

**Problem:** JavaScript for the select-all checkbox is embedded as an inline `<script>` tag inside the view. This is exactly the anti-pattern that Stimulus.js is designed to solve. It also violates CSP best practices.

**Solution:** Extract to a Stimulus controller:

```javascript
// app/javascript/controllers/select_all_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selectAll", "checkbox"]

  toggle() {
    this.checkboxTargets.forEach(cb => cb.checked = this.selectAllTarget.checked)
  }
}
```

```erb
<%# In the view, replace the inline script with data attributes: %>
<div data-controller="select-all">
  <input type="checkbox" data-select-all-target="selectAll"
         data-action="change->select-all#toggle">
  ...
  <% @files.each do |file| %>
    <input type="checkbox" data-select-all-target="checkbox" ...>
  <% end %>
</div>
```

---

### P1-5: Enable CI jobs

**File:** `.github/workflows/ci.yml`

**Problem:** All real CI jobs (`scan_ruby`, `scan_js`, `lint`) are commented out. The only active job runs `echo "CI jobs disabled"`. This means no automated checks run on PRs or pushes to main.

**Solution:** Uncomment the `scan_ruby` and `lint` jobs at minimum:

```yaml
scan_ruby:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: ruby/setup-ruby@v1
      with:
        ruby-version: .ruby-version
        bundler-cache: true
    - run: bin/brakeman --no-pager

lint:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: ruby/setup-ruby@v1
      with:
        ruby-version: .ruby-version
        bundler-cache: true
    - run: bin/rubocop -f github
```

---

### P1-6: Add meaningful tests

**File:** `spec/features/sample_spec.rb` (replace entirely)

**Problem:** The only test is `expect(1).to eq(1)`. RSpec, Capybara, Selenium, and shoulda-matchers are all installed but unused.

**Solution:** Add at minimum model validation tests and authentication flow tests:

```ruby
# spec/models/folder_spec.rb
require "rails_helper"

RSpec.describe Folder, type: :model do
  it { should validate_presence_of(:name) }
  it { should belong_to(:user) }
  it { should have_many(:stored_files).dependent(:destroy) }
end

# spec/models/stored_file_spec.rb
require "rails_helper"

RSpec.describe StoredFile, type: :model do
  it { should validate_presence_of(:file_name) }
  it { should belong_to(:user) }
  it { should belong_to(:folder) }
end
```

---

### P1-7: Add model scopes

**Files:** `app/models/folder.rb`, `app/models/stored_file.rb`

**Problem:** No scopes defined. Controllers call raw association methods without any named, reusable query interface.

**Solution:** Add basic scopes:

```ruby
# folder.rb
scope :recent, -> { order(created_at: :desc) }

# stored_file.rb
scope :by_name, -> { order(file_name: :asc) }
scope :search, ->(query) { where("file_name ILIKE ?", "%#{query}%") }
```

The search scope in particular would remove the inline `where` call from `FoldersController#show`:

```ruby
# folders_controller.rb - becomes cleaner:
@files = @files.search(params[:query]) if params[:query].present?
```

---

### P1-8: Remove Phase 2 placeholder CSS

**File:** `app/assets/stylesheets/custom-image.css`

**Problem:** Contains classes with the comment `/* Custom image styles, mostly for Phase 2 Photogram targets */` and utility classes (`img-small`, `img-medium`, `img-large`) that are not used anywhere in this application. This is carryover from a different project template.

**Solution:** Remove `.img-small`, `.img-medium`, `.img-large`, and the comment referencing Phase 2 Photogram. Keep only the `.fade-in-up` animation which is used on the landing page.

---

### P1-9: Add developer setup instructions to README

**File:** `README.md`

**Problem:** No setup instructions. A new developer cannot clone and run this app.

**Solution:** Add a Setup section:

```markdown
## Setup

### Prerequisites
- Ruby 3.x (see `.ruby-version`)
- PostgreSQL
- Cloudinary account (for file storage)

### Installation
```bash
bundle install
cp .env.example .env  # then fill in values
rails db:create db:migrate
rails server
```

### Environment Variables
Create a `.env` file with:
```
DATABASE_URL=postgresql://localhost/document_storage_mvp_development
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```
```

Also add `.env.example` to the repo with placeholder values.

---

## P2 — Polish / UX / Enhancements

---

### P2-1: Move flash message inline styles to CSS classes

**File:** `app/views/shared/_flash.html.erb`

**Problem:** Flash messages use long inline `style=` attributes for background, color, border, padding. This makes the style hard to maintain and override.

**Solution:**

```css
/* In application.css or a flash.css file */
.flash-notice {
  margin: 1rem auto;
  padding: 0.75rem 1rem;
  border-radius: 6px;
  max-width: 900px;
  font-size: 0.95rem;
  background: #e8f5e9;
  color: #2e7d32;
  border: 1px solid #c8e6c9;
}

.flash-alert {
  background: #ffebee;
  color: #c62828;
  border: 1px solid #ffcdd2;
}
```

```erb
<%# _flash.html.erb %>
<% flash.each do |type, message| %>
  <div class="<%= type == 'notice' ? 'flash-notice' : 'flash-alert' %>">
    <%= message %>
  </div>
<% end %>
```

---

### P2-2: Wire up the Stimulus modal controller or delete it

**File:** `app/javascript/controllers/modal_controller.js`

**Problem:** The modal controller is well-written but never connected to any view. It adds no value in its current state and confuses reviewers.

**Solution (Option A):** Use it for the folder delete confirmation:

```erb
<%# In folders/index.html.erb %>
<div data-controller="modal">
  <button data-action="click->modal#open">Delete</button>
  <dialog data-modal-target="dialog">
    <article>
      <header><h3>Confirm Delete</h3></header>
      <p>Are you sure you want to delete this folder?</p>
      <footer>
        <%= button_to "Delete", folder_path(folder), method: :delete,
            data: { action: "click->modal#confirm" } %>
        <button data-action="click->modal#close">Cancel</button>
      </footer>
    </article>
  </dialog>
</div>
```

**Solution (Option B):** If not needed, delete the file.

---

### P2-3: Resolve conflicting CSS frameworks

**File:** `app/views/layouts/application.html.erb`

**Problem:** Both Bootstrap 5 and Pico CSS are loaded. These frameworks both define base styles and resets, which conflict. Mixed class usage (Bootstrap `.btn`, `.container`, `.d-flex` alongside Pico's `contrast outline`) creates inconsistency.

**Solution:** Choose one framework and remove the other. Given that Bootstrap utilities (`d-flex`, `justify-content-between`, `col-md-*`) are used throughout all views, Bootstrap is the primary framework. Remove the Pico CSS CDN link and the FirstDraft Pico overrides link from the layout.

---

### P2-4: Embed ERD in README

**File:** `README.md`

**Problem:** `erd.png` is in the repository root but not linked in the README. Reviewers and new developers miss it.

**Solution:** Add to README:

```markdown
## Entity Relationship Diagram

![ERD](erd.png)
```

---

### P2-5: Add ARIA roles and form `required` attributes

**Files:** Multiple views

**Problem:** Interactive components lack ARIA roles. Form inputs lack HTML5 `required` attributes for client-side validation.

**Solution:**
- Add `required: true` to the folder name field in `folders/new.html.erb`
- Add `required: true` to the file upload field in `stored_files/_form.html.erb`
- Add `role="button"` or `aria-label` attributes to icon-only action buttons

```erb
<%# Example: %>
<%= f.text_field :name, class: "form-control", required: true,
    placeholder: "Enter folder name", aria: { label: "Folder name" } %>
```

---

### P2-6: Fill in the `sample_data.rake` task

**File:** `lib/tasks/sample_data.rake`

**Problem:** The task body is empty. Running `rails sample_data` does nothing.

**Solution:**

```ruby
desc "Fill the database tables with some sample data"
task sample_data: :environment do
  puts "Clearing existing data..."
  StoredFile.destroy_all
  Folder.destroy_all
  User.destroy_all

  puts "Creating sample user..."
  user = User.create!(
    email: "demo@example.com",
    password: "password",
    username: "demo_user"
  )

  puts "Creating sample folders..."
  3.times do |i|
    folder = user.folders.create!(name: "Sample Folder #{i + 1}")
    puts "  Created folder: #{folder.name}"
  end

  puts "Done! Log in with demo@example.com / password"
end
```

---

### P2-7: Add `edit` link on folders index

**File:** `app/views/folders/index.html.erb`

**Problem:** Once `edit`/`update` are implemented (P0-2), there's no UI to access the edit page. The folder list only shows Open and Delete buttons.

**Solution:** Add an edit link alongside the existing actions:

```erb
<%= link_to "Edit", edit_folder_path(folder), class: "btn btn-sm btn-outline-secondary" %>
```
