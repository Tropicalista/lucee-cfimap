/**
*
* @author  Francesco Pepe
* @description
*
*/

component output="false" displayname="cfimap"  {

	this.metadata.hint="(partial) implementation of cfimap"; // http://pdfbox.apache.org
	this.metadata.attributetype="fixed";
	this.metadata.attributes={
		Action 			: { required:true, type:"string", hint="[DELETE|DELETEFOLDER|CREATEFOLDER|OPEN|CLOSE|RENAMEFOLDER|LISTALLFOLDERS|MARKREAD|MOVEMAIL|GETALL|GETHEADERONLY]"},
		Attachmentpath  : { required:false, type:"string", hint="pathname (Todo: byte array)"},
		Connection: { required:false, type:"string",    hint="read - structure containing form field values"},
		Folder: { required:false, type:"string", hint="pathname"},
		GenerateUniqueFilenames: { required:false, type:"boolean", hint="overwrite the destination file. default no"},
		MaxRows: { required:false, type:"boolean", hint="remove form fields. default no"},
		MessageNumber: { required:false, type:"string", hint="that returns XML data"},
		Name: { required:false, type:"string", hint="filename to be exported to"},
		NewFolder: { required:false, type:"string", hint="filename to be exported to"},
		Password: { required:false, type:"string", hint="filename to be exported to"},
		Port: { required:false, type:"string", hint="filename to be exported to"},
		Recurse: { required:false, type:"boolean", hint="filename to be exported to"},
		Secure: { required:false, type:"boolean", hint="filename to be exported to"},
		Server: { required:false, type:"string", hint="filename to be exported to"},
		StartRow: { required:false, type:"string", hint="filename to be exported to"},
		StopOnError: { required:false, type:"string", hint="filename to be exported to"},
		Timeout: { required:false, type:"string", hint="filename to be exported to"},
		Uid: { required:false, type:"string", hint="filename to be exported to"},
		Username: { required:false, type:"string", hint="filename to be exported to"}
	};
	this.metadata.requiredAttributesPerAction = {
		GetAll: ['name'],
		GetHeaderOnly: ['name'],
		ListAllFolders: ['name'],
		CreateFolder: ['folder'],
		RenameFolder: ['folder','newFolder'],
		DeleteFolder: ['folder'],
		Close: ['connection'],
		Open: ['connection','server','username','password'],
		MoveMail: ['newFolder']
	}

	/**
	*
	* @hint invoked after tag is constructed
	* @component the parent cfc custom tag, if there is one
	*
	*/
	public function init( required boolean hasEndTag = false, component parent ){

		variables.hasEndTag = arguments.hasEndTag;
		variables.parent = arguments.parent;
		variables.imap = new imap.imap();

		return this;
	}

	public boolean function onStartTag(	required struct attributes, required struct caller ){

		// check for action
		if ( !StructKeyExists( arguments.attributes, 'action' ) ) {
			throw( type="application", message="missing parameter", detail="'action' not passed in" );
		}

		// check for source
		switch(arguments.attributes.action) {

			case "open":

				//check passing attributes passed in
				if ( 
					!StructKeyExists( arguments.attributes, 'server' ) || 
					!StructKeyExists( arguments.attributes, 'connection' ) || 
					!StructKeyExists( arguments.attributes, 'username' ) || 
					!StructKeyExists( arguments.attributes, 'password' ) 
				)
				{
					throw( type="application", message="Attribute validation error", detail="It has an invalid attribute combination." );
				}
				// check optional arguments
				if (! StructKeyExists(arguments.attributes, 'timeout')) {
					arguments.attributes.timeout = 60;
				}
				if (! StructKeyExists(arguments.attributes, 'port')) {
					arguments.attributes.port = 143;
				}
				if (! StructKeyExists(arguments.attributes, 'secure')) {
					arguments.attributes.secure = false;
				}
	
				arguments.caller[arguments.attributes.connection] = variables.imap.connect( 
					arguments.attributes.connection,
					arguments.attributes.username, 
					arguments.attributes.password, 
					arguments.attributes.server,
					arguments.attributes.secure,
					arguments.attributes.timeout,
					arguments.attributes.port
				);
				break;

			case "createFolder":

				//check passing attributes passed in
				if ( !StructKeyExists(arguments.attributes, 'connection') ){
					throw( type="application", message="Attribute validation error", detail="Attribute connection is required." );
				}
				if ( !StructKeyExists(arguments.attributes, 'folder') ){
					throw( type="application", message="Attribute validation error", detail="It has an invalid attribute combination." );
				}
				variables.imap.createFolder( 
					arguments.caller[arguments.attributes.connection], 
					arguments.attributes.folder
				);
				break;

			case "deleteFolder":

				//check passing attributes passed in
				if ( !StructKeyExists(arguments.attributes, 'folder') ){
					throw( type="application", message="Attribute validation error", detail="It has an invalid attribute combination." );
				}
				variables.imap.deleteFolder( 
					arguments.caller[arguments.attributes.connection], 
					arguments.attributes.folder
				);
				break;

			case "renameFolder":

				//check passing attributes passed in
				if ( !StructKeyExists(arguments.attributes, 'folder') ){
					throw( type="application", message="Attribute validation error", detail="Attribute folder is required." );
				}
				if ( !StructKeyExists(arguments.attributes, 'newFolder') ){
					throw( type="application", message="Attribute validation error", detail="Attribute newFolder is required." );
				}
				variables.imap.renameFolder( 
					arguments.caller[arguments.attributes.connection], 
					arguments.attributes.folder,
					arguments.attributes.newFolder
				);
				break;

			case "ListAllFolders":

				//check passing attributes passed in
				if ( !StructKeyExists(arguments.attributes, 'name') || !StructKeyExists(arguments.attributes, 'connection') ) {
					throw( type="application", message="Attribute validation error", detail="It has an invalid attribute combination." );
				}
				if( !StructKeyExists(arguments.attributes, 'folder') ){
					arguments.attributes.folder = "INBOX";
				}
				arguments.caller[arguments.attributes.name] = variables.imap.ListAllFolders( 
					arguments.caller[arguments.attributes.connection],
					arguments.attributes.folder,
					arguments.attributes.recurse
				);
				break;

			case "delete":

				//check passing attributes passed in
				if ( !StructKeyExists(arguments.attributes, 'connection') ) {
					throw( type="application", message="Attribute validation error", detail="It has an invalid attribute combination." );
				}
				variables.imap.close( arguments.caller[arguments.attributes.connection], arguments.attributes.folder );
				break;

			case "markread":

				//check passing attributes passed in
				if ( !StructKeyExists(arguments.attributes, 'connection') ) {
					throw( type="application", message="Attribute validation error", detail="It has an invalid attribute combination." );
				}
				variables.imap.markread( arguments.caller[arguments.attributes.connection], arguments.attributes.folder );
				break;

			case "movemail":

				//check passing attributes passed in
				if ( !StructKeyExists(arguments.attributes, 'connection') ||
					!StructKeyExists(arguments.attributes, 'newFolder') ||
					!StructKeyExists(arguments.attributes, 'messageNumber') 
				){
					throw( type="application", message="Attribute validation error", detail="It has an invalid attribute combination." );
				}
				variables.imap.movemail( arguments.caller[arguments.attributes.connection], arguments.attributes.newFolder, arguments.attributes.messageNumber, arguments.attributes.folder );
				break;

			case "getheaderonly":

				//check passing attributes passed in
				if ( !StructKeyExists(arguments.attributes, 'connection') ||
					!StructKeyExists(arguments.attributes, 'name')
				){
					throw( type="application", message="Attribute validation error", detail="It has an invalid attribute combination." );
				}
				arguments.caller[arguments.attributes.name] = variables.imap.getHeaderOnly( 
					arguments.caller[arguments.attributes.connection], 
					arguments.attributes.folder ?: "",
					arguments.attributes.startRow ?: "",
					arguments.attributes.maxRow ?: "",
					arguments.attributes.uid ?: "",
					arguments.attributes.messageNumber ?: ""
				);
				break;

			case "close":

				//check passing attributes passed in
				if ( !StructKeyExists(arguments.attributes, 'connection') ) {
					throw( type="application", message="Attribute validation error", detail="It has an invalid attribute combination." );
				}
				variables.imap.close( arguments.caller[arguments.attributes.connection] );
				break;

			default: 
				throw(type="application", message="unsupported action", detail="valid action=[DELETE|DELETEFOLDER|CREATEFOLDER|OPEN|CLOSE|RENAMEFOLDER|LISTALLFOLDERS|MARKREAD|MOVEMAIL|GETALL|GETHEADERONLY]");
		
		}
		return true;
	}

}