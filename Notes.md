# Adolfo Nava Document Storage MVP Notes

## README.md

The README.md file for a given repository is meant for developers not for people in sales, or pitching services to the general public. When I mean by developers I mean people who would are going to be working on the project and making their own additions to the project. This is basically meant to be part of the onboarding process which means everything a developer needs to understand before they try testing and running the project on their own devices. 

Below are example additions you can make clear for someone who is joining your team.
- What sort of console commands would you have for simple startup or reset of the environment. 
```sh
bundle install
bin/setup
rails s
```
- API keys are being used in this but aren't mentioned whatsoever so people are going to be left confused as to why doesn't the application work as they thought it would and that is because you are working with a cloud storage provider when it comes to uploading files like images or pdfs.
- Database structure (ERDs) and typical workflows (making folders and uploading/fetching files)

## Styling

There is a consistent issue with the CSS on the website part of is due to the additional styling choices you chose to include and part of it was not accounting how each service handled light and dark themes. 

[light & dark modes](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Values/color_value/light-dark)

## Documents

When it comes to uploading files, I had an issue where I was able to upload the file but when I attempted to download it back, it would not work. I believe this is because of the way that the file is being stored and retrieved from the database. I had made a note of that in the product score which feels like a critical flaw within the cloud storage provider that needs further investigation into what could be done to handle this properly.
