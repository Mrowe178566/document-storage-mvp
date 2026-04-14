# 📁 FileVault — Ruby on Rails Application  
**Work in Progress (Refactoring in Progress)**

FileVault is a full‑stack Ruby on Rails application that provides a clean, Google‑Drive‑style interface for managing folders and uploaded files. The project is currently undergoing refactoring to improve architecture, UI consistency, and developer documentation.

This README is intentionally minimal while the codebase is being updated.

---

## 🚀 Overview

FileVault is built with:

- Ruby on Rails 8  
- PostgreSQL  
- Active Storage with Cloudinary  
- Bootstrap 5  
- Devise authentication  

Current functionality includes:

- Folder creation and management  
- File uploads  
- Bulk delete actions  
- Search across folders and files  

---

## 📦 Current Status

This project is actively being refactored to improve:

- Controller structure  
- UI/UX consistency  
- Error handling  
- Test coverage  
- Developer‑facing documentation  

A full README with setup instructions, architecture notes, and contribution guidelines will be added after refactoring is complete.

---

## 🛠️ Running the App (Development)

After cloning the repository:

```bash
bundle install
rails db:create db:migrate
bin/server

---

## 🔐 Environment Variables

The application uses environment variables for:

- Cloudinary API keys  
- Rails master key  

These values are **not** committed to the repository.

---

## 📄 License

MIT License.
