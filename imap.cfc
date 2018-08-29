/**
*
* @author  Francesco Pepe
* @description
*
*/
component output="false" displayname="cfimap"  {

	this.metadata.hint="(partial) implementation of cfimap";
	this.metadata.attributetype="fixed";
	this.metadata.attributes={
		Action 			: { required:true, type:"string", hint="[DELETE|DELETEFOLDER|CREATEFOLDER|OPEN|CLOSE|RENAMEFOLDER|LISTALLFOLDERS|MARKREAD|MOVEMAIL|GETALL|GETHEADERONLY]"},
		Attachmentpath  : { required:false, type:"string", hint="pathname (Todo: byte array)"},
		Connection: { required:false, type:"string", hint="Specifies the variable name for the connection/session."},
		Folder: { required:false, type:"string", hint="Specifies the folder name where messages are retrieved, moved, or deleted"},
		GenerateUniqueFilenames: { required:false, type:"boolean", hint="Ensures that unique file names are generated for each attachment file. Default = NO"},
		MaxRows: { required:false, type:"boolean", hint="Specifies the number of rows to be marked as read, deleted, or moved across folders."},
		MessageNumber: { required:false, type:"string", default:"", hint="Specifies the message number or a comma delimited list of message numbers for retrieval, deletion, marking mail as read, or moving mails."},
		Name: { required:false, type:"string", hint="Specifies the name for the query object that contains the retrieved message information."},
		NewFolder: { required:false, type:"string", hint="Specifies the name of the new folder when you rename a folder or the name of the destination folder where all mails move."},
		Password: { required:false, type:"string", hint="Specifies the password for assessing the users’ e-mail account."},
		Port: { required:false, type:"string", hint="Specifies the IMAP port number. Use 143 for non-secure connections and 993 for secured connections."},
		Recurse: { required:false, type:"boolean", hint="Specifies whether ColdFusion runs the CFIMAP command in subfolders. Recurse works for action=”ListAllFolders”. When recurse is set to ”true”, ColdFusion parses through all folders and subfolders and returns folder/subfolder names and mail information."},
		Secure: { required:false, type:"boolean", hint="Specifies whether the IMAP server uses a Secure Sockets Layer."},
		Server: { required:false, type:"string", hint="Specifies the IMAP server identifier. You can assign a host name or an IP address as the IMAP server identifier."},
		StartRow: { required:false, type:"string", hint="Defines the first row number for reading or deleting. If you have specified the UID or MessageNumber attribute, then StartRow is ignored. You can also specify StartRow for moving mails."},
		StopOnError: { required:false, type:"string", hint="Specifies whether to ignore the exceptions for this operation. When the value is true, it stops processing, displays an appropriate error."},
		Timeout: { required:false, type:"string", hint="Specifies the number of seconds to wait before timing out connection to IMAP server. An error message is displayed when timeout occurs."},
		Uid: { required:false, type:"string", default: "", hint="Specifies the unique ID or a comma-delimited list of Uids to retrieve, delete, and move mails. If you set invalid Uids, then they are ignored."},
		Username: { required:false, type:"string", hint="Specifies the user name. Typically, the user name is same the e-mail login."}
	};
	this.metadata.requiredAttributesPerAction = {
		GetAll: ['name','connection'],
		GetHeaderOnly: ['name'],
		ListAllFolders: ['name'],
		CreateFolder: ['folder'],
		RenameFolder: ['folder','newFolder'],
		DeleteFolder: ['folder'],
		Close: ['connection'],
		Open: ['connection','server','username','password'],
		MoveMail: ['newFolder'],
		Delete: ['connection','UID']
	}

	/**
	*
	* @hint invoked after tag is constructed
	* @parent the parent cfc custom tag, if there is one
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
			throw( message="missing parameter", detail="'action' not passed in" );
		}

		if( structKeyExists( this.metadata.requiredAttributesPerAction, arguments.attributes.action ) ){
			var attrName = "";
			loop array="#this.metadata.requiredAttributesPerAction[arguments.attributes.action]#" index="attrName" {
				if( not structKeyExists( arguments.attributes, attrName ) ){
					throw (message="Attribute validation error for tag CFIMAP: when action is '#arguments.attributes.action#', the atribute [#attrName#] is required!");
				}
			}
		}else{
			throw( type="application", message="CFIMAP does not have an action '#htmleditformat(action)#'!", detail="Only actions '#structKeyList(this.metadata.requiredAttributesPerAction)#' are available." );
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
					arguments.attributes['folder'] = "";
				}
				arguments.caller[arguments.attributes.name] = variables.imap.ListAllFolders( 
					arguments.caller[arguments.attributes.connection],
					arguments.attributes.folder
				);
				break;

			case "delete":

				//check passing attributes passed in
				if ( !StructKeyExists(arguments.attributes, 'connection') ) {
					throw( type="application", message="Attribute validation error", detail="It has an invalid attribute combination." );
				}
				variables.imap.delete( arguments.caller[arguments.attributes.connection], arguments.attributes.folder, arguments.attributes.MessageNumber, arguments.attributes.uid );
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
				variables.imap.movemail( arguments.caller[arguments.attributes.connection], arguments.attributes.newFolder, arguments.attributes.messageNumber, arguments.attributes.uid, arguments.attributes.folder );
				break;

			case "getheaderonly":

				//check passing attributes passed in
				if ( !StructKeyExists(arguments.attributes, 'connection') ||
					!StructKeyExists(arguments.attributes, 'name')
				){
					throw( type="application", message="Attribute validation error for tag CFIMAP", detail="It has an invalid attribute combination." );
				}
				arguments.caller[arguments.attributes.name] = variables.imap.getHeaderOnly( 
					arguments.caller[arguments.attributes.connection], 
					arguments.attributes.folder ?: "",
					arguments.attributes.startRow ?: 1,
					arguments.attributes.maxRows ?: "",
					arguments.attributes.uid ?: "",
					arguments.attributes.messageNumber ?: ""
				);
				break;

			case "getall":

				//check passing attributes passed in
				if ( !StructKeyExists(arguments.attributes, 'connection') ||
					!StructKeyExists(arguments.attributes, 'name')
				){
					throw( type="application", message="Attribute validation error for tag CFIMAP", detail="It has an invalid attribute combination." );
				}
				arguments.caller[arguments.attributes.name] = variables.imap.getAll( 
					arguments.caller[arguments.attributes.connection], 
					arguments.attributes.folder ?: "",
					arguments.attributes.startRow ?: "",
					arguments.attributes.maxRow ?: "",
					arguments.attributes.uid ?: "",
					arguments.attributes.messageNumber ?: "",
					arguments.attributes.attachmentPath ?: ""
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
