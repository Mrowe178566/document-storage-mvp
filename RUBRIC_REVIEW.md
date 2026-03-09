# SDF Final Project Rubric - Technical

- Date/Time: 2026-03-09
- Trainee Name: Maia Rowe
- Project Name: File Vault (document-storage-mvp)
- Reviewer Name: Claude, Ian Heraty, Adolfo Nava
- Repository URL: <https://github.com/Mrowe178566/document-storage-mvp>
- Feedback Pull Request URL: (not provided)

---

## Readme (max: 10 points)

- [x] **Markdown**: Is the README formatted using Markdown?
  > Evidence: `README.md` uses `#` headers, `*` bullet lists, and inline emphasis throughout.

- [x] **Naming**: Is the repository name relevant to the project?
  > Evidence: Repository named `document-storage-mvp`; app is a document storage system.

- [x] **1-liner**: Is there a 1-liner briefly describing the project?
  > Evidence: `README.md` line 3 — "This application provides a secure, minimal document‑storage system where users can sign in, create folders, and upload files."

- [ ] **Instructions**: Are there detailed setup and installation instructions, ensuring a new developer can get the project running locally without external help?
  > No setup instructions exist. No mention of `bundle install`, `rails db:create`, `rails db:migrate`, Ruby version, or how to start the server.

- [ ] **Configuration**: Are configuration instructions provided, such as environment variables or configuration files that need to be set up?
  > No `.env.sample` or instructions for required environment variables / keys (`CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`, `DATABASE_URL`). A developer cloning the repo cannot configure the app without inspecting `render.yaml` manually.

- [ ] **Contribution**: Are there clear contribution guidelines? Do they outline how developers can contribute to the project, including coding conventions, branch naming conventions, and the pull request process?
  > No `CONTRIBUTING.md` and no contribution section in `README.md`.

- [ ] **ERD**: Does the documentation include an entity relationship diagram?
  > `erd.png` exists at the repo root but is not linked or embedded in `README.md`. Screenshots in the README are app UI screenshots, not the ERD.

- [ ] **Troubleshooting**: Is there an FAQs or Troubleshooting section that addresses common issues, questions, or obstacles users or new contributors might face?
  > No troubleshooting or FAQ section present.

- [x] **Visual Aids**: Are there visual aids (diagrams, screenshots, etc.) that would help developers quickly ramp on to the project?
  > Evidence: `README.md` lines 59–61 embed three GitHub-hosted app screenshots.

- [ ] **API Documentation (for projects providing their own API endpoints)**: Is there clear and detailed documentation for the project's API?
  > N/A — this project has no custom API endpoints; all routes are HTML-serving controller actions.

### Score (4/10):

### Notes:
The README communicates the product vision and user context well, but fails completely as a developer onboarding document. A new developer cannot clone and run this app without external help. The ERD is in the repository but not linked. No setup, configuration, or contribution guidance exists.

---

## Version Control (max: 10 points)

- [x] **Version Control**: Is the project using a version control system such as Git?
  > Evidence: `.git` directory present; `git log` shows full commit history.

- [x] **Repository Management**: Is the repository hosted on a platform like GitHub, GitLab, or Bitbucket?
  > Evidence: PR history references `Mrowe178566` GitHub account (e.g., `Merge pull request #9 from Mrowe178566:feature/delete-stored-files`).

- [x] **Commit Quality**: Does the project have regular commits with clear, descriptive messages?
  > Evidence: Commits follow clear naming like `"Add StoredFile controller, routes, and upload form"`, `"Add Cloudinary Active Storage integration"`. Minor typos present (`"flased moved to partial"`, `"Add LICDDSE"`) but overall quality is acceptable.

- [x] **Pull Requests**: Does the project employ a clear branching and merging strategy?
  > Evidence: 9 merged PRs with consistent branch naming (`feature/`, `setup/`). Example: `feature/cloudinary-setup`, `feature/delete-stored-files`.

- [ ] **Issues**: Is the project utilizing issue tracking to manage tasks and bugs?
  > Needs GitHub repository settings verification. Cannot confirm from local git history.

- [ ] **Linked Issues**: Are these issues linked to pull requests (at least once)?
  > Needs GitHub repository settings verification.

- [ ] **Project Board**: Does the project utilize a project board linked to the repository?
  > Needs GitHub repository settings verification. Not linked in README.

- [x] **Code Review Process**: Is there evidence of a code review process, with pull requests reviewed by peers or mentors before merging?

- [ ] **Branch Protection**: Are the main branches protected to prevent direct commits?

- [ ] **Continuous Integration/Continuous Deployment (CI/CD)**: Has the project implemented CI/CD pipelines?
  > Evidence: `.github/workflows/ci.yml` exists. **However**, all jobs are disabled — the only active job runs `echo "CI jobs disabled"`. The workflow file contains commented-out `scan_ruby`, `scan_js`, and `lint` jobs.

### Score (5/10):

### Notes:
Strong branching discipline and PR history. CI/CD file is present but entirely non-functional — all real jobs are commented out. Recommend uncommenting the CI jobs and enabling branch protection on `main`.

---

## Code Hygiene (max: 8 points)

- [x] **Indentation**: Is the code consistently indented throughout the project?
  > Evidence: 2-space indentation consistent in all Ruby files; 2-space in ERB templates; 2-space in JavaScript.

- [x] **Naming Conventions**: Are naming conventions clear, consistent, and descriptive?
  > Evidence: `stored_files`, `folders_controller`, `BreadcrumbsHelper`, `StoredFile` — all clear and descriptive.

- [x] **Casing Conventions**: Are casing conventions consistent?
  > Evidence: `snake_case` for Ruby methods/variables, `PascalCase` for classes (`StoredFile`, `FoldersController`), `camelCase` in JavaScript (`closeOnBackdrop`, `dialogTarget`).

- [x] **Layouts**: Is the code utilizing Rails' `application.html.erb` layout effectively?
  > Evidence: `app/views/layouts/application.html.erb` includes `shared/nav`, `shared/flash`, `shared/breadcrumbs`, and `yield`. All pages share this consistent layout.

- [ ] **Code Clarity**: Is the code easy to read and understand?
  > Critical issue: `FoldersController` has two `show` actions (`app/controllers/folders_controller.rb` lines 9–14 and 37–47). In Ruby, the second definition silently overrides the first — the simple version at line 9 is dead code. This is a significant clarity and correctness bug.
  >
  > Additional issues: `User` model (`app/models/user.rb` lines 27–28) has `has_many :stored_files` declared twice. `Folder` model (`app/models/folder.rb` lines 21 and 23) has `has_many :stored_files` declared twice. These are confusing and indicate code was not reviewed carefully.

- [ ] **Comment Quality**: Does the code include appropriate inline comments?
  > `app/javascript/controllers/modal_controller.js` is massively over-commented — nearly every line has a comment restating what the code already makes obvious (e.g., `// Use the native HTML dialog showModal() method` above `d.showModal()`). The Ruby files have almost no comments where non-obvious logic exists (e.g., the duplicate `show` action, the inline search in `show`).

- [ ] **Minimal Unused Code**: Unused code should be deleted.
  > - `app/javascript/controllers/hello_controller.js` — sets `textContent = "Hello World!"`. Not wired to any view with `data-controller="hello"`. Placeholder never cleaned up.
  > - `app/views/shared/_form.html.erb` — a duplicate upload form partial that is not rendered anywhere (the used one is `app/views/stored_files/_form.html.erb`).
  > - `app/views/stored_files/new.html.erb` — renders a standalone form but this view appears to never be linked to from the app (upload is embedded in `folders#show` via the `_form` partial).
  > - `app/assets/stylesheets/custom-image.css` contains classes like `.img-small`, `.img-medium`, `.img-large` with a comment "for Phase 2 Photogram targets" — clearly template leftovers with no relevance to this project.

- [x] **Linter**: Is a linter used and configured?
  > Evidence: `.rubocop.yml` exists, inherits from `rubocop-rails-omakase`, with project-specific overrides for hash syntax and spacing.

### Score (5/8):

### Notes:
The duplicate `show` action is the most serious hygiene issue — it creates a silent bug. The duplicate `has_many` declarations in two models suggest the codebase was not carefully reviewed. Unused files and a template placeholder (`custom-image.css`) should be removed. The modal controller is over-commented while business logic has no comments.

---

## Patterns of Enterprise Applications (max: 10 points)

- [x] **Domain Driven Design**: Does the application follow domain-driven design principles?
  > Evidence: Clear domain model with `User`, `Folder`, and `StoredFile`. Controllers are thin, models own associations and validations.

- [ ] **Advanced Data Modeling**: Has the application utilized ActiveRecord callbacks?
  > No `before_*`, `after_*`, or `around_*` callbacks defined in any model file.

- [x] **Component-Based View Templates**: Does the application use partials?
  > Evidence: `shared/_flash.html.erb`, `shared/_nav.html.erb`, `shared/_breadcrumbs.html.erb`, `stored_files/_form.html.erb` — all rendered from layout or parent views.

- [ ] **Backend Modules**: Does the application effectively use modules (concerns, etc.)?
  > `BreadcrumbsHelper` is a helper module but is included into `ApplicationController` directly — not a model concern. No domain concerns (`app/models/concerns/` and `app/controllers/concerns/` directories appear empty or unused). This is not a meaningful use of backend modules.

- [ ] **Frontend Modules**: Does the application effectively use ES6 modules?
  > `modal_controller.js` is written as a proper ES6 Stimulus controller module but is **never wired to any view** — no `data-controller="modal"` exists in any ERB template. `hello_controller.js` is an unused placeholder. The select-all JavaScript is written as an inline `<script>` tag inside `folders/show.html.erb` rather than a Stimulus controller.

- [ ] **Service Objects**: Does the application abstract logic into service objects?
  > No `app/services/` directory. No service objects.

- [ ] **Polymorphism**: Does the application use polymorphism?
  > No evidence of polymorphic associations or method overriding patterns.

- [ ] **Event-Driven Architecture**: Does the application use event-driven architecture?
  > No ActionCable channels, no pub-sub patterns. `solid_cable` is in the Gemfile but only as an infrastructure dependency (not used in application code).

- [x] **Overall Separation of Concerns**: Are concerns separated effectively?
  > Evidence: Controllers handle request/response flow, models handle data, views handle presentation. No business logic found in views. Queries are scoped through `current_user` associations in controllers.

- [ ] **Overall DRY Principle**: Does the application follow DRY?
  > Violated in multiple places: duplicate `show` action in `FoldersController`, duplicate `has_many :stored_files` in `User` and `Folder` models, two upload form partials (`shared/_form.html.erb` and `stored_files/_form.html.erb`) with nearly identical content, inline `<script>` tag instead of a reusable Stimulus controller.

### Score (3/10):

### Notes:
The application demonstrates basic MVC separation and partial reuse, but does not reach the enterprise pattern level expected. No callbacks, no concerns, no service objects, no polymorphism, no event-driven patterns. The Stimulus controller (modal) is well-written but completely disconnected from the application — it adds no real value in its current state. The inline `<script>` tag for select-all is the exact pattern Stimulus was designed to replace.

---

## Design (max: 5 points)

- [x] **Readability**: Ensure the text is easily readable. Avoid color combinations that make text difficult to read (e.g., white text on a bright pink background).
- [x] **Line length**: The horizontal width of text blocks should be no more than 2–3 lowercase alphabets.
- [x] **Font Choices**: Use appropriate font sizes, weights, and styles to enhance readability and visual appeal.
- [x] **Consistency**: Maintain consistent font usage and colors throughout the project.
- [x] **Double Your Whitespace**: Ensure ample spacing around elements to enhance readability and visual clarity. Avoid cluttered layouts by doubling the whitespace where appropriate.

### Score (5/5)

### Notes:

- Both Bootstrap 5 and Pico CSS are loaded simultaneously — this creates conflicting CSS resets and utility class conflicts. Having two CSS frameworks is unusual and likely produces inconsistent styling.
- Inline `style=` attributes are used extensively in nearly every view and partial (nav, breadcrumbs, flash, folder forms), making the design difficult to maintain.
- The footer uses `style="text-align: center; color: #5f6368;"` instead of a CSS class.
- The `submit_tag` in `folders/show.html.erb` uses inline hex color + padding inline style.
- Code-level concern: heavy inline styling and conflicting CSS frameworks (Bootstrap 5 + Pico CSS) suggest inconsistency is likely. Recommend extracting styles to CSS classes.

---

## Frontend (max: 10 points)

- [x] **Mobile/Tablet Design**: It looks and works great on mobile/tablet.
  >  `<meta name="viewport" content="width=device-width,initial-scale=1">` is present and Bootstrap 5 responsive grid is used (`col-md-4`, `col-md-6`, etc.), which is promising. Landing page has horizontal overflow on mobile. Remove the `max-width` style tag to fix

- [x] **Desktop Design**: It looks and works great on desktop.

- [x] **Styling**: Does the frontend employ CSS or CSS frameworks?
  > Evidence: Bootstrap 5.3.3 via CDN, Bootstrap Icons 1.11.3, and Pico CSS loaded in layout. Custom CSS in `app/assets/stylesheets/`. Note: inline `style=` attributes are overused throughout views — this is not best practice.

- [x] **Semantic HTML**: Is the project making effective use of semantic HTML elements?
  > Evidence: `<nav role="navigation">` in `_nav.html.erb`, `<footer>` in layout, `<nav aria-label="Breadcrumb">` in `_breadcrumbs.html.erb`.

- [x] **Feedback**: Are styled flashes or toasts implemented in a partial?
  > Evidence: `app/views/shared/_flash.html.erb` renders color-coded flash messages (green for notice, red for alert) and is rendered in the application layout.

- [x] **Client-Side Interactivity**: Is JavaScript or Stimulus utilized?
  > Evidence: Inline `<script>` in `folders/show.html.erb` handles select-all checkbox behavior. Note: `modal_controller.js` Stimulus controller is defined but **not wired to any view element**. Turbo is explicitly disabled: `Turbo.session.drive = false` in `application.js`.

- [ ] **AJAX**: Is Asynchronous JavaScript used to perform a CRUD action?
  > No evidence of AJAX calls. Turbo Drive is disabled (`Turbo.session.drive = false`). No `fetch()`, `$.ajax()`, or Turbo Stream responses found.

- [ ] **Form Validation**: Does the project include client-side form validation?
  > No client-side validation. No HTML5 `required`, `pattern`, or `minlength` attributes on form inputs. No JavaScript validation logic.

- [x] **Accessibility: alt tags**: Are alt tags implemented?
  > Evidence: `app/views/home/index.html.erb` — `image_tag "vault-logo.png", alt: "File Vault Logo"`.

- [ ] **Accessibility: ARIA roles**: Are ARIA roles implemented?
  > Only `aria-label="Breadcrumb"` found in `_breadcrumbs.html.erb`. No `role=` attributes on interactive components, modals, or buttons.

### Score (7/10):

### Notes:
Turbo is disabled globally which eliminates its performance benefits and prevents AJAX-style updates. The Stimulus modal controller is dead code — never connected to any view. No form validation or ARIA roles. Inline `<script>` tag in a view is exactly the anti-pattern Stimulus was designed to solve.

---

## Backend (max: 9 points)

- [ ] **CRUD**: Does the application implement at least one resource with full CRUD functionality?
  > `resources :folders` in `config/routes.rb` generates all 7 RESTful routes including `edit` and `update`. However, `FoldersController` has no `edit` or `update` actions — accessing `GET /folders/:id/edit` will raise `AbstractController::ActionNotFound`. Neither `StoredFile` nor `Folder` supports full CRUD (Create ✓, Read ✓, Update ✗, Delete ✓).

- [x] **MVC pattern**: Does the application follow the MVC pattern with skinny controllers?
  > Evidence: Controllers delegate to model associations (`current_user.folders.find`, `@folder.stored_files.build`). No raw SQL. Business logic is appropriately minimal.

- [x] **RESTful Routes**: Are the routes RESTful?
  > Evidence: `resources :folders`, `resources :stored_files, only: [:new, :create, :destroy]`. Custom `delete "stored_files/bulk_delete"` is named appropriately.

- [x] **DRY queries**: Are database queries implemented in the model/controller layer, not views?
  > Evidence: All queries in controllers (e.g., `current_user.folders`, `@folder.stored_files`). No ActiveRecord calls in views.

- [x] **Data Model Design**: Is the data model well-designed?
  > Evidence: `db/schema.rb` — Users → Folders → StoredFiles with proper foreign keys and indexes. `stored_files` has both `user_id` and `folder_id` with appropriate FK constraints and indexes. No redundancy.

- [x] **Associations**: Does the application use Rails association methods effectively?
  > Evidence: `User has_many :folders`, `User has_many :stored_files`, `Folder belongs_to :user`, `Folder has_many :stored_files`, `StoredFile belongs_to :user`, `StoredFile belongs_to :folder`. Note: `has_many :stored_files` is duplicated in both `User` and `Folder` models — these duplicate lines should be removed.

- [x] **Validations**: Are validations implemented?
  > Evidence: `Folder` — `validates :name, presence: true`. `StoredFile` — `validates :file_name, presence: true`. Devise handles User email/password validation.

- [ ] **Query Optimization**: Does the application use scopes?
  > No `scope` definitions found in any model. No named scopes for common queries (e.g., `scope :recent` or `scope :by_folder`).

- [x] **Database Management**: Are custom rake tasks for database management included?
  > Evidence: `lib/tasks/sample_data.rake` exists with a `sample_data` task. Note: the task body is empty — it defines the task but performs no seeding. Credit given for structure, deducted in Notes.

### Score (7/9):

### Notes:
The major gap is full CRUD — neither resource supports Update (edit/update actions are missing despite routes being generated). The `sample_data.rake` exists but does nothing. No model scopes. The duplicate `has_many :stored_files` declarations in both `User` and `Folder` are harmless but sloppy and should be removed.

---

## Quality Assurance and Testing (max: 2 points)

- [ ] **End to End Test Plan**: Does the project include an end to end test plan?
  > No test plan document found. No `TEST_PLAN.md` or equivalent.

- [ ] **Automated Testing**: Does the project include a meaningful test suite?
  > `spec/features/sample_spec.rb` exists but contains only:
  > ```ruby
  > it "is not graded" do
  >   expect(1).to eq(1)
  > end
  > ```
  > This is a placeholder, not a real test. RSpec, Capybara, and related gems are installed but no meaningful tests were written.

### Score (0/2):

### Notes:
Testing infrastructure is fully configured (RSpec, Capybara, Selenium, shoulda-matchers, webmock) but no actual tests exist. This is a significant gap for production readiness. At minimum, model validations, authentication flow, and authorization scoping should be tested.

---

## Security and Authorization (max: 5 points)

- [x] **Credentials**: Are API keys and sensitive information securely stored?
  > Evidence: `.gitignore` excludes `**/.env*`. `render.yaml` uses `sync: false` for `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`, and `DATABASE_URL` (set externally). `config/credentials.yml.enc` present for Rails encrypted credentials. No hardcoded secrets found in source code.

- [x] **HTTPS**: Is HTTPS enforced?
  > Evidence: `config/environments/production.rb` — `config.force_ssl = true` and `config.assume_ssl = true` both present.

- [x] **Sensitive attributes**: Are sensitive attributes assigned safely?
  > Evidence: `@stored_file.user = current_user` is set server-side in `stored_files_controller.rb:21`. `@folder = current_user.folders.build(folder_params)` — user ownership enforced server-side.
  >
  > Concern: `folder_id` is passed as a hidden field in `stored_files/_form.html.erb` and `shared/_form.html.erb`. A user could tamper with this value. However, the controller mitigates this with `current_user.folders.find(params[:folder_id])` which will raise `ActiveRecord::RecordNotFound` if the folder doesn't belong to the current user. Mitigation is in place, but the hidden field approach is not ideal.

- [x] **Strong Params**: Are strong parameters used?
  > Evidence: `folder_params` permits only `:name`. `stored_file_params` permits only `:uploaded_file`. Both controllers use `params.require` or `params.fetch`.

- [ ] **Authorization**: Is an authorization framework employed?
  > No Pundit, CanCanCan, or equivalent authorization framework. Access control is done entirely through manual `current_user` scoping. While this works for the current simple use case, it does not scale and provides no policy layer.

### Score (4/5):

### Notes:
Good security fundamentals. HTTPS enforced, secrets managed properly, strong params in place, user-scoped queries prevent cross-user data access. The missing piece is a formal authorization framework. With only one user role currently, this is acceptable for MVP scope, but should be addressed before adding any admin or multi-role functionality.

---

## Features (each: 1 point - max: 15 points)

- [ ] **Sending Email**: Does the application send transactional emails?
  > Mailer view templates exist (`app/views/layouts/mailer.html.erb`, `mailer.text.erb`) but are empty Rails defaults. No mailer classes defined, no mail delivery configured.

- [ ] **Sending SMS**: No evidence.

- [ ] **Building for Mobile (PWA)**: Is there a PWA manifest?
  > `app/views/pwa/manifest.json.erb` exists but contains unmodified Rails 8 template values: `"name": "Rails8Template"`, `"theme_color": "red"`, `"description": "Rails8Template."`. This is an **uncleaned placeholder** — not a functional PWA.

- [ ] **Advanced Search and Filtering**: Is Ransack or similar used?
  > A basic `ILIKE` search is implemented in `folders_controller.rb#show` (line 42: `@files.where("file_name ILIKE ?", "%#{params[:query]}%")`). This is a raw SQL pattern match, not an advanced search library (Ransack or similar). Does not meet the rubric criterion.

- [ ] **Data Visualization**: No charts or graphs.

- [ ] **Dynamic Meta Tags**: No dynamic meta tag generation.

- [ ] **Pagination**: No pagination library.

- [ ] **Internationalization (i18n)**: `locales/simple_form.en.yml` exists (auto-generated by simple_form), but no application-level i18n implementation.

- [ ] **Admin Dashboard**: No.

- [ ] **Business Insights Dashboard**: No.

- [x] **Enhanced Navigation**: Are breadcrumbs used?
  > Evidence: `BreadcrumbsHelper` in `app/helpers/breadcrumbs_helper.rb`, `add_breadcrumb` called in `FoldersController` and `StoredFilesController`, rendered via `shared/_breadcrumbs.html.erb` in the layout.

- [ ] **Performance Optimization**: No Bullet gem in Gemfile.

- [ ] **Stimulus**: Is Stimulus implemented?
  > `modal_controller.js` and `hello_controller.js` exist. However: `hello_controller.js` is a placeholder that is never connected to any view. `modal_controller.js` is well-written but also **never connected to any view** (`data-controller="modal"` appears nowhere in the ERB templates). Stimulus is installed but not meaningfully used in the application.

- [ ] **Turbo Frames**: Is Turbo Frames used?
  > No `turbo_frame_tag` in any view. Turbo Drive is globally disabled (`Turbo.session.drive = false`).

- [ ] **Other**: N/A.

### Score (1/15):

### Notes:
Only breadcrumbs earned credit. The PWA manifest is an uncleaned template placeholder (`Rails8Template`). Basic file search exists but doesn't use a library as specified. Stimulus controllers are defined but never connected to any view element — this is a missed opportunity. Turbo is installed but disabled. Email infrastructure exists but is empty.

---

## Ambitious Features (each: 2 points - max: 16 points)

- [ ] **Receiving Email**: No ActionMailbox.

- [ ] **Inbound SMS**: No.

- [ ] **Web Scraping Capabilities**: No.

- [ ] **Background Processing**: `solid_queue` is in `Gemfile` and schema tables are present. `ApplicationJob` exists. `render.yaml` sets `SOLID_QUEUE_IN_PUMA=true`. However, no custom job classes are defined — only the default `application_job.rb` stub. No background processing is actually implemented.

- [ ] **Mapping and Geolocation**: No.

- [x] **Cloud Storage Integration**: Cloudinary integrated for file storage.
  > Evidence: `gem "cloudinary"` and `gem "activestorage-cloudinary-service"` in `Gemfile`. `render.yaml` configures `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET`. `StoredFile` uses `has_one_attached :uploaded_file`. Files are uploaded and downloadable via `rails_blob_path`.

- [ ] **Chat GPT or AI Integration**: No.

- [ ] **Payment Processing**: No.

- [ ] **OAuth**: No.

- [ ] **Other**: N/A.

### Score (2/16):

### Notes:
Cloudinary integration is the standout ambitious feature and is properly implemented. Background job infrastructure (solid_queue) is installed but no actual jobs are defined. All other ambitious features are absent.

---

## Technical Score (/100):
- Readme (4/10)
- Version Control (5/10)
- Code Hygiene (5/8)
- Patterns of Enterprise Applications (3/10)
- Design (5/5)
- Frontend (7/10)
- Backend (7/9)
- Quality Assurance and Testing (0/2)
- Security and Authorization (4/5)
- Features (1/15)
- Ambitious Features (2/16)
---
- **Total: 43/100**

---

## Additional overall comments for the entire review may be added below:

### Summary Assessment

The core application works: users can authenticate, create folders, upload files to Cloudinary, and delete them. The data model is sensible, authorization scoping is correctly implemented via `current_user`, and Cloudinary integration is a genuine accomplishment.

However, the project has several issues:

1. **No full CRUD** — Neither resource supports Update. The `edit` and `update` routes are generated but will 404.
2. **Silent duplicate `show` action** — `FoldersController` defines `show` twice. This is a bug that obscures the intended behavior.
3. **Zero meaningful tests** — The test suite contains only `expect(1).to eq(1)`.
4. **Dead code everywhere** — Stimulus modal controller, hello controller, shared/_form partial, and Phase 2 CSS classes are all unused.
5. **CI is disabled** — The GitHub Actions workflow runs only `echo "CI jobs disabled"`.
6. **Uncleaned template placeholder** — `manifest.json.erb` still reads `"Rails8Template"` with `"theme_color": "red"`.
7. **README lacks all developer onboarding content** — no setup, no config, no contribution guide.

The strongest areas are backend security (scoped queries, strong params, HTTPS, credential management) and cloud storage.
