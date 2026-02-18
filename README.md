# Multi‑Tenant Document Storage 
## Overview 
This application provides a secure, minimal document‑storage system where users can sign in, create folders, and upload files. Each user has access only to their own content.

## Pain Point
Users waste time digging through emails, desktop folders, and shared drives to find the files they need, leading to frustration, lost documents, and delays in getting work done.

## Target User
* Name: Alexis Carter
* Age: 29
* Occupation: Freelance digital creator (photography, small business content)
* Tech Comfort: Moderate — uses cloud tools but not deeply technical
* Location: Urban or suburban area

Alexis manages a mix of client projects, invoices, creative assets, and personal documents. Their files live everywhere — email attachments, desktop folders, random cloud drives, and screenshots saved to their phone. Alexis isn’t disorganized on purpose; they’re just juggling a lot and don’t have a simple, central place to put everything.

## Hypothesis
If users are given a simple, private place to upload and organize their files, then they will save time and reduce frustration because they no longer have to search through emails, downloads, and scattered folders to find what they need.

## Goals & Objectives 
1. Allow users to securely sign up and log in
2. Provide a simple interface for uploading and organizing files
3. Ensure users only access their own folders and files
4. Keep the system lightweight and intuitive
5. Deliver a stable, functional MVP quickly

## User Roles 
1. Can view only their own folders and files 
2. Can upload files into their folders 
3. Cannot access other users’ folders or files 

## User Stories 
1. As an user, I want to create folders so that I can organize my own files. 
2. As an user, I want to upload files into my folders so that I can store documents I need. 
3. As an user, I want to view only my own folders and files so that I don’t see information that doesnt belong to me.  

## Core Features

### User Authentication
1. Users can sign up or log in
2. Authentication handled via Devise
3. All routes require authentication
4. Users can only access their own data

### Folder Management
1. Users can create folders
2. Folders belong to the user who created them
3. Users can view only their own folders

### File Uploads
1. Users can upload files into their folders
2. Users cannot access files belonging to other users

### Access Control
1. All access is enforced using current_user
2. Users only see their own folders and files


![Image](https://github.com/user-attachments/assets/74095758-310f-4b52-b8b1-51271801dd9b)
![Image](https://github.com/user-attachments/assets/f4206cdd-1c4e-4f66-aad8-a21ec52f95a5)
![Image](https://github.com/user-attachments/assets/fa549556-1dce-43a6-9964-5cef9285058b)


## Stretch Goal:  
Add an Organizations table to support multiple companies or teams using the system independently, with complete data isolation between them.
