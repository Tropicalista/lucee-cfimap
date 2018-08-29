# **\<cfimap /\> for Lucee**
\<cfimap /\> tag for Lucee Server. Read email using IMAP protocol.

# WIP
## Supported actions
- Open
- Close
- GetHeaderOnly
- ListAllFolders
- CreateFolder
- DeleteFolder
- RenameFolder
- MarkRead
- MoveMail
- Delete
- GetAll


## Installation
- Save to Lucee context directory ("context/library/tag")
- you will need to restart Lucee when you have added these files (and after editing a tag)

## As custom tag

If you want use this as custom tag, import in your project 

`	this.customTagPaths = ["/custom_tag_import"];`

and then invoke like this:

`<cf_imap name="myimap">`