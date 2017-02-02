component output="false" accessors="true" singleton {

	public function init(){
		return this;
	}

	public function connect( 
		required connection, 
		required string username, 
		required string password, 
		required string server, 
		required boolean secure = false, 
		required numeric timeout = 60, 
		required numeric port = 143
	){
		var clsSession = createObject("Java", "javax.mail.Session");
		var objProperties = createObject("Java", "java.util.Properties");
		var objStore = createObject("Java", "javax.mail.Store");
		var oTimeout = arguments.timeout * 1000;
		objProperties.init();
		objProperties.put("mail.store.protocol", arguments.secure ? 'imaps' : 'imap');
		objProperties.put("mail.imap.port", JavaCast( "int", arguments.port ) );
		objProperties.put("mail.imap.connectiontimeout", oTimeout);
		objProperties.put("mail.imap.timeout", oTimeout);
		objProperties.put("mail.imap.ssl.enable", JavaCast( "boolean", arguments.secure ) );
		objSession = clsSession.getInstance(objProperties);
		objStore = objSession.getStore();
		objStore.connect( arguments.server, arguments.username, arguments.password );

		return objStore;
	}

	public function close( required connection ){
		arguments.connection.close();
	}

	public function getHeaderOnly( required string connection, string folder = "INBOX", startRow = 1, maxRows, uid, messageNumber ){

		var list = getMessages(arguments);
		return list;

	}

	public function getAll( required connection, string folder = "INBOX", startRow = 1, maxRows, uid, messageNumber ){

		var list = getMessages( arguments, true );
		return list;

	}

	public function ListAllFolders( required connection, string folder, boolean recurse = false ){

		var folders = getFolders( arguments.connection, arguments.folder, JavaCast( "boolean", arguments.recurse ) );

		var columns = "fullname,name, new, unread, totalmessages, parent";
		var list = QueryNew(columns);
		loop from="1" to="#ArrayLen(folders)#" step="1" index="index"{
			if( folders[index].getType() != 2 ){
				queryAddRow(list);
				querySetCell(list, "fullname", folders[index].getFullName());
				querySetCell(list, "name", folders[index].getName());
				querySetCell(list, "new", folders[index].getNewMessageCount());
				querySetCell(list, "parent", folders[index].getParent().getFullName());
				querySetCell(list, "unread", folders[index].getUnreadMessageCount());
				querySetCell(list, "totalmessages", folders[index].getMessageCount());
			}

		}

		return list;

	}

	public function markRead( required connection, string folder, string messageNumber = "", string uid = "" ){

		var flag = CreateObject("Java", "javax.mail.Flags$Flag");
		var objFolder = getFolder( arguments.connection, arguments.folder );

		if (arguments.uid neq "" or arguments.messageNumber neq "") {
			objFolder.open( objFolder.READ_WRITE );
			var messages = objFolder.getMessages();
			var index = 0;

			loop from="1" to="#ArrayLen( messages )#" step="1" index="index"{
				if (arguments.uid neq "") {
					if (listfind(arguments.uid, objFolder.getUID(messages[index]))) {
						messages[index].setFlag(flag.SEEN, true);
					}
				}
				else if (arguments.messageNumber neq "") {
					if (listfind(arguments.messageNumber, objFolder.getMessageNumber(messages[index]))) {
						messages[index].setFlag(flag.SEEN, true);
					}
				}
			}
			objFolder.close(true);
		}
		else
			throw "uid and messageNumber are empty."

		return messages;

	}

	public numeric function delete( string folder, string messageNumber = "", string uid = "" ){

		var flag = CreateObject("Java", "javax.mail.Flags$Flag");
		var objFolder = getFolder( arguments.folder );
		var deleted = 0;

		if (arguments.uid neq "" or arguments.messageNumber neq "") {
			objFolder.open( objFolder.READ_WRITE );
			var messages = objFolder.getMessages();

			loop from="1" to="#ArrayLen( messages )#" step="1" index="index"{
				if (arguments.uid neq "") {
					if (listfind(arguments.uid, objFolder.getUID(messages[index]))) {
						messages[index].setFlag(flag.DELETED, true);
						deleted++;
					}
				}
				else if (arguments.messageNumber neq "") {
					if (listfind(arguments.messageNumber, objFolder.getMessageNumber(messages[index]))) {
						messages[index].setFlag(flag.DELETED, true);
						deleted++;
					}
				}
			}
			objFolder.close(true);
		}
		else
			throw "uid and messageNumber are empty."

		return deleted;

	}

	public function moveMail( required string newFolder, string messageNumber, string uid, string folder ){

		var objFolder = getFolder( arguments.folder );
		var objNewFolder = getFolder( arguments.newFolder );
		var messages = "";

		objFolder.open( objFolder.READ_WRITE );
		if (structKeyExists(arguments, "uid") and listlen(arguments.uid))
			messages = objFolder.getMessagesByUID( JavaCast( "int[]", ListToArray(arguments.uid)) );
		else if (listlen(arguments.messageNumber))
			messages = objFolder.getMessages( JavaCast( "int[]", ListToArray(arguments.messageNumber)) );
		else
			throw "uid and messageNumber are empty."

		objFolder.copyMessages( messages, objNewFolder );

		if (structKeyExists(arguments, "uid") and listlen(arguments.uid))
			delete( folder=arguments.folder, uid=arguments.uid );
		else
			delete( folder=arguments.folder, messageNumber=arguments.messageNumber );

		objFolder.close(true);

		return messages;

	}

	public function createFolder( required connection, required string folder ){

		var objFolder = getFolder( arguments.connection, arguments.folder );
		objFolder.create( 3 );

		return objFolder;

	}

	public function renameFolder( required connection, required string folder, required string newFolder ){

		var objFolder = getFolder( arguments.connection, arguments.folder );
		var objNewFolder = getFolder( arguments.connection, arguments.newFolder );
		objFolder.renameTo( objNewFolder );

		return objFolder;

	}

	public function deleteFolder( required connection, required string folder ){

		var objFolder = getFolder( arguments.connection, arguments.folder );
		objFolder.delete( true );

	}

	private function getFolder( required connection, required string folder ){

		if( !len( arguments.folder ) ){
			arguments.folder = "INBOX";
		}
		var folder = arguments.connection.getFolder( arguments.folder );

		return folder;

	}

	private function getFolders( required connection, string folder, boolean recurse = false ){

		if( !len( arguments.folder ) ){
			var folders = arguments.recurse ? arguments.connection.getDefaultFolder().list("*") : arguments.connection.getDefaultFolder().list();
		}else{
			var folders = arguments.recurse ? arguments.connection.getFolder( arguments.folder ).list("*") : arguments.connection.getFolder( arguments.folder ).list();
		}

		return folders;

	}

	private function openFolder( required connection, string folder ){

		if( !structKeyExists( arguments, "folder" ) ){
			var objFolder = arguments.connection.getDefaultFolder();
		}else{
			var objFolder = arguments.connection.getFolder( arguments.folder );
		}
		objFolder.open( objFolder.READ_ONLY );

		return objFolder;

	}

	private function createQuery( required messages, required string columns, required boolean all=false ){

		var flag = CreateObject("Java", "javax.mail.Flags$Flag");
		var recipient = CreateObject("Java", "javax.mail.Message$RecipientType");
		
		var list = QueryNew( arguments.columns );

		loop from="1" to="#ArrayLen( messages )#" step="1" index="index"{
			if( isNull(messages[index]) ){
				continue;
			}
			queryAddRow(list);
			querySetCell( list, "answered", messages[index].isSet(flag.ANSWERED) );
			if( arguments.all ) querySetCell( list, "attachmentfiles", getFileName( messages[index] ) );
			if( arguments.all ) querySetCell( list, "attachments", hasAttachments( messages[index] ) );
			if( arguments.all ) querySetCell( list, "body", getHtmlBody( messages[index] ) );
			querySetCell( list, "cc", IsArray( messages[index].getRecipients( recipient.CC ) ) ? ArrayToList(messages[index].getRecipients( recipient.TO )) : "" );
			querySetCell( list, "deleted", messages[index].isSet(flag.DELETED) );
			querySetCell( list, "draft", messages[index].isSet(flag.DRAFT) );
			querySetCell( list, "flagged", messages[index].isSet(flag.FLAGGED) );
			querySetCell( list, "from", messages[index].getSender().toString() );
			querySetCell( list, "header", ArrayToList( createObject( "java", "java.util.Collections" ).list( messages[index].getAllHeaderLines() ) ) );
			if( arguments.all ) querySetCell( list, "htmlbody", getHtmlBody( messages[index] ) );
			querySetCell( list, "lines", messages[index].getLineCount() );
			querySetCell( list, "messageid", messages[index].getMessageID() );
			querySetCell( list, "messagenumber", messages[index].getMessageNumber() );
			querySetCell( list, "recent", messages[index].isSet(flag.RECENT) );
			querySetCell( list, "replyto", ArrayToList(messages[index].getReplyTo()) );
			querySetCell( list, "rxddate", messages[index].getReceivedDate() );
			querySetCell( list, "seen", messages[index].isSet(flag.SEEN) );
			querySetCell( list, "sentDate", messages[index].getSentDate() );
			querySetCell( list, "size", messages[index].getSize() );
			querySetCell( list, "subject", messages[index].getSubject() );
			if( arguments.all ) querySetCell( list, "textbody", getText( messages[index] ) );
			querySetCell( list, "to", IsArray( messages[index].getRecipients( recipient.TO ) ) ? ArrayToList(messages[index].getRecipients( recipient.TO )) : messages[index].getRecipients( recipient.TO ) );
			querySetCell( list, "uid", messages[index].getFolder().getUID( messages[index] ) );
			if( arguments.all ) querySetCell( list, "user", messages[index].isSet(flag.USER) );
		}

		return list;

	}

	private function getFileName( required message ){

		if( !hasAttachments(message) ){
			return "";
		}

		var p = createObject("Java", "javax.mail.Part");
		var multiPart = arguments.message.getContent();
		var fileName = [];

		for ( i=0; i LT multiPart.getCount(); i++ ) {

			var part = multiPart.getBodyPart( i );

			if( !isNull( part.getDisposition() ) AND 
				( compareNoCase( part.getDisposition(), p.ATTACHMENT ) || compareNoCase( part.getDisposition(), p.INLINE ) )
			){
				fileName.append( part.getFileName() );
			}
		}

		return fileName.toList();

	}

	private function getText( required message ){

	        if ( message.isMimeType( "multipart/*" ) ) {

			var multiPart = arguments.message.getContent();
			for ( i=0; i LT multiPart.getCount(); i++ ) {

				var bodyPart = multiPart.getBodyPart( i );

				if( bodyPart.isMimeType("text/plain") ){
					return bodyPart.getContent();
				}

			}

	        }
		else if (arguments.message.isMimeType( "text/plain" ))
			return arguments.message.getContent();
		else return "";

	}

	private function getHtmlBody( required message ){

        if ( message.isMimeType( "multipart/*" ) ) {

			var multiPart = arguments.message.getContent();
			
			for ( i=0; i LT multiPart.getCount(); i++ ) {

				var bodyPart = multiPart.getBodyPart( i );

        		if ( bodyPart.isMimeType( "multipart/*" ) ) {
        			return bodyPart.getContent().getBodyPart(1).getContent();
        		}
        		if ( bodyPart.isMimeType( "text/html" ) ) {
        			return bodyPart.getContent();
        		}

			}

        }

	}

    boolean function hasAttachments( msg ){
		if ( msg.isMimeType("multipart/mixed") ){
		    var mp = msg.getContent();
		    if ( mp.getCount() > 1 ){
				return true;
			}
		}
		return false;
    }


    public any function getMessages( struct attr, boolean getAll = false ) {

    	var messages = [];
		var columns = "answered, cc, deleted, draft, flagged, from, header, lines, messageid, 
		messagenumber, recent, replyto, rxddate, seen, sentDate, size, subject, to, uid";
		var objFolder = getFolder( arguments.attr.connection, arguments.attr.folder );
		objFolder.open( objFolder.READ_ONLY );

		if( structKeyExists( arguments.attr, "uid") ){
			var messages = objFolder.getMessagesByUID( listToArray(arguments.attr.uid) );
		}elseif( structKeyExists( arguments.attr, "messageNumber") ){
			var messages = objFolder.getMessage( arguments.attr.messageNumber );
		}elseif( !structKeyExists( arguments.attr, "maxRows") ){
			var messages = objFolder.getMessages();
		}else{
			var messages = objFolder.getMessages( arguments.attr.startRow, arguments.attr.startRow + arguments.attr.maxRows - 1 );
		}

		if( arguments.getAll ){
			columns = ListAppend( columns, "attachmentfiles, attachments, body, htmlbody, textbody, user", "," );
		}

		var list = createQuery( messages, columns, arguments.getAll )

		objFolder.close( false );

    	return list;
    }
    
}
