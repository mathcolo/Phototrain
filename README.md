#Phototrain
Phototrain is tiny macOS menu bar app for automatic Dropbox -> Photos app import.

####Motivation
I use a Nexus 5X, but I also use Apple's Photos application. Dropbox is a great way to get photos from Android to macOS, but I wanted a quick tool to automate the importing process. Phototrain emulates iCloud Photo Stream. 

####Requirements
- macOS 10.12 (may work on 10.10 and 10.11, untested)
- Dropbox
- Dropbox's Camera Upload feature enabled and using ~/Dropbox/Camera Uploads as its directory
- A configured Photos.app library

####Installation (binary download)
No binary currently available

####Installation (self compilation)
1. Clone the repo
2. `carthage update`
3. Open the project file in Xcode, compile and run :)
