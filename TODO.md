# Project To-Do List

## Core

* Make everything event-driven
* Protocol Interoperability
* Localization Support
* On-Protocol Help
* Encrypted Passwords
* Command and message hooks should use Events
* Dynamic code (re)loading
* Configuration rehashing
* Account creation and deletion events
* Make everything case-insensitive where it needs to be (almost every module)
* Make user storage more intelligent. Duplicate log-ins are currently impossible.
* Fix module info stoage. There are about six places module names and descriptions are kept. Bad!

### Protocol Support

For complete interoperability, a lot of things are going to have to be moved around.

Until then, things might look a little hackish.

* Bahamut
* Charybdis
* DreamForge
* Hybrid
* ircu
* InspIRCD
* IRCD
* Nefarius IRCu
* PleXusIRCd
* PTLink
* Ratbox
* ShadowIRCD
* SolidIRCd
* UnrealIRCD (In Progress) *3.2.8.10 or with ESVID patch*
* UltimateIRCd

## Modules

* Move commands to individual files?

### NickServ

* Info
* Ghost
* Noexpire
* Note
* Suspend
* Unsuspend
* Forbid
* Unforbid
* Vacation
* Unvacation

### ChanServ

* Register
* Drop
* List
* Grant
* Ungrant
* Topic
* Kick
* Ban
* Unban
* Forbid
* Unforbid
* Mode
* Invite
* Greet (Send saved notice to users when they join)
* Store grants in boolean columns rather than the dumb string

### OperServ

* Quit
* Restart
* Rehash
* ReloadMod
* LoadMod
* UnloadMod
* DropAccount
* AddAccount
* ListAccounts
* Global
* Oper News (Send news items to users when they oper)
* User News (Send news items to users when they connect)

### HostServ

* Set command for other users for services administrators
* Allow different characters depending on protocol or configuration. Not really sure how to do that yet.

### BotServ

* Create
* Delete
* Join
* Part
* Say
* Act
* Forbid
* Unforbid
* Grant
* Ungrant

### LogServ

* Join
* Part
* Age
* Get
* Delete

### BanServ

* Akill
* RegexKill
* ChanKill
* Akill user@host when joining specified channels

### MemoServ

* Send
* Draft
* Inbox
* Outbox
* Sent
* Drafts
* Read
* Delete

### SpamServ

* Join
* Part
* Badwords
* Colors
* Formatting
* Limit
* Punishment
* Whitelisting (Channels, Nicks, Regex?)

### NoteServ

* Add
* Read
* Delete

### PollServ

* Add
* Send
* List
* Delete
* Auto
* Vote

### BuddyServ

* Add
* Remove
* List
* Broadcast
