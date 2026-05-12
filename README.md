# File Vault

File Vault is a Rails 8 multi-tenant document storage app. A user signs up and gets their own workspace; the workspace's admin can invite teammates by email, and every member shares the same folders and files. Files are stored on Cloudinary, search is folder-scoped, and bulk-delete is built in. I built it to practice multi-tenant data modeling, authorization at the query layer, file uploads through Active Storage, an invitation flow with ActionMailer, and deployment-ready Rails architecture.

**Live demo:** https://document-storage-mvp.onrender.com

---

## Screenshots

_[add 2-3 screenshots or a short GIF of the running app — ideally the folder list, a folder with files, and the workspace settings page with members]_

---

## Features

- Email/password authentication with Devise
- Each user belongs to a workspace; signup creates the user's first workspace and makes them its admin
- Admins can invite teammates by email; invitees set a password to join the workspace
- Two roles per workspace: admin (manages members) and member (manages files)
- Create, rename, and delete folders (visible to every member of the workspace)
- Upload files into folders, stored on Cloudinary via Active Storage
- Content-type allowlist (PDFs, images, common documents/spreadsheets) and 25 MB cap per file
- Download files
- Search within a folder by file name
- Bulk-delete multiple files in one action

---

## Tech stack

- Ruby 3.4 / Rails 8
- PostgreSQL (development, test, and production)
- Devise for authentication
- Active Storage with the Cloudinary service adapter
- ActionMailer for invitation emails (letter_opener in dev, SMTP in production)
- Hotwire (Turbo + Stimulus) for interactivity
- Bootstrap 5 for layout
- RSpec + Capybara for testing
- Deployed on Render

---

## Architecture overview

- **Authorization through workspace-scoped queries.** Every controller action loads records through `current_workspace.folders` or `current_workspace.stored_files` rather than `Folder.find` directly. A user in workspace A literally cannot query for a folder in workspace B, even if they guess the ID — the scoped query won't return it. This pushes authorization out of policy files and into the data layer where it's harder to forget.
- **One user, one workspace.** A user belongs to exactly one workspace, identified by `users.workspace_id` (NOT NULL). This trades flexibility (no multi-workspace membership) for simplicity (no workspace switcher, no per-resource permission checks).
- **Invitations as first-class records.** An `Invitation` carries the workspace, the inviter, the recipient email, a 32-byte URL-safe token, and an expiry timestamp. The accept endpoint is a public route keyed on the token — invitees don't need an account to land on it. Acceptance creates a new user already assigned to the workspace, bypassing the auto-workspace creation hook on signup.
- **No local file storage.** Active Storage is configured to use Cloudinary so the app stays stateless — uploads go straight to Cloudinary, downloads stream back through Active Storage, and the Render web instance has nothing on disk to back up.
- **Hotwire over a SPA.** Turbo handles navigation and destructive-action confirmations; a small Stimulus controller powers the "select all" checkbox on the file list. No JavaScript framework, no API layer.
- **Foreign keys are NOT NULL.** Every `Folder` and `StoredFile` has a `workspace_id` and a `user_id` (uploader/creator) enforced both in the model (`belongs_to`) and at the database level.

---

## Local setup

Prerequisites: Ruby 3.4, PostgreSQL, and a free-tier Cloudinary account.

```bash
git clone https://github.com/Mrowe178566/document-storage-mvp
cd document-storage-mvp
bundle install
cp .env.example .env
# Fill in the Cloudinary and database values in .env
rails db:create db:migrate
rails server
```

The app runs at `http://localhost:3000`. Invitation emails open in your browser via `letter_opener` instead of being sent.

### Required environment variables

```
CLOUDINARY_CLOUD_NAME=...
CLOUDINARY_API_KEY=...
CLOUDINARY_API_SECRET=...
DATABASE_URL=postgresql://localhost/document_storage_mvp_development
MAIL_FROM=no-reply@filevault.local
```

`.env` is gitignored.

---

## Running tests

```bash
bundle exec rspec
```

Tests cover model validations, associations, scopes, the invitation lifecycle, the auto-workspace-creation behavior on signup, end-to-end file upload and download, cross-workspace access being blocked, the full invitation send-and-accept flow (including email delivery), and folder destroy with stored-file cascade.

---

## Challenges, tradeoffs, and what I'd build next

**Authorization through scoped queries instead of Pundit.** I kept authorization out of a policy gem and pushed it into `current_workspace`-scoped lookups. The upside is one obvious pattern that's hard to misuse — there's no policy file you can forget to update, and a junior dev reading the controller can see exactly why one workspace can't read another's data. The downside is that as soon as the app needs per-folder ACLs or guest-read permissions, this approach falls apart and a real authorization layer becomes the right call.

**One workspace per user.** Modeling `users.workspace_id` as a single foreign key keeps the data model trivially simple but means there's no workspace switcher and no overlap between teams. The next-most-realistic model is a `Membership` join table between users and workspaces, but that's a meaningful refactor I deliberately deferred until there was a real reason for it.

**Cloudinary instead of S3.** Cloudinary's free tier is generous, the gem integrates cleanly with Active Storage, and it gave me a fully cloud-backed deployment without setting up an AWS account. The tradeoff is that I'm now dependent on Cloudinary's pricing model and have less control over storage region and transformation pipelines than I'd have with raw S3.

**Folder-scoped search instead of global search.** The current search filter only applies within the folder the user is looking at. This kept the UI simple and the query trivial (`where("file_name ILIKE ?", ...)`), but it's the most-requested missing feature. Building global search would mean either an index across folders or a Postgres full-text search column on `stored_files`.

**What I'd build next, in order:**
1. Workspace switcher + a `Membership` model so a user can belong to multiple workspaces.
2. Global search across folders within a workspace.
3. PDF and image previews inline in the folder view.
4. File versioning (replace a file without losing the previous version).

---

## Data model

![ERD](erd.png)

---

## License

MIT — Maia Rowe
