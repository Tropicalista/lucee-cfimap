component output="false" accessors="true" singleton {

	public function init(){
		return this;
	}

	public function connect( 
		required string connection, 
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
		objProperties.put("mail.store.protocol", "imap");
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

	public function getHeaderOnly( required string connection, required string name, string folder = "INBOX", startRow = "", maxRows = "" ){
		var objFolder = getFolder( arguments.connection, arguments.folder );
		objFolder.open( objFolder.READ_ONLY );
		var messages = objFolder.getMessages( arguments.startRow, arguments.maxRows );
		var flag = CreateObject("Java", "javax.mail.Flags$Flag");
		var recipient = CreateObject("Java", "javax.mail.Message$RecipientType");

		var columns = "answered, attachmentfiles, attachments, body, cc, deleted, draft, flagged, from, header, lines, messageid, 
		messagenumber, recent, replyto, rxddate, seen, size, subject, to, uid, user";
		var list = QueryNew( columns );
		loop from="1" to="#ArrayLen( messages )#" step="1" index="index"{
			queryAddRow(list);
			querySetCell( list, "answered", messages[index].isSet(flag.ANSWERED) );
			querySetCell( list, "attachmentfiles", messages[index].isSet(flag.ANSWERED) );
			querySetCell( list, "attachments", messages[index].isSet(flag.ANSWERED) );
			querySetCell( list, "body", messages[index].getContent() );
			querySetCell( list, "cc", messages[index].getRecipients( recipient.CC ) );
			querySetCell( list, "deleted", messages[index].isSet(flag.DELETED) );
			querySetCell( list, "draft", messages[index].isSet(flag.DRAFT) );
			querySetCell( list, "flagged", messages[index].isSet(flag.FLAGGED) );
			querySetCell( list, "from", messages[index].getSender().toString() );
			querySetCell( list, "header", ArrayToList( createObject( "java", "java.util.Collections" ).list( messages[index].getAllHeaderLines() ) ) );
			//querySetCell( list, "htmlbody", messages[index].getContent().getBodyPart().getContent() );
			querySetCell( list, "lines", messages[index].getLineCount() );
			querySetCell( list, "messageid", messages[index].getMessageID() );
			querySetCell( list, "messagenumber", messages[index].getMessageNumber() );
			querySetCell( list, "recent", messages[index].isSet(flag.RECENT) );
			querySetCell( list, "replyto", ArrayToList(messages[index].getReplyTo()) );
			querySetCell( list, "rxddate", messages[index].getReceivedDate() );
			querySetCell( list, "seen", messages[index].isSet(flag.SEEN) );
			querySetCell( list, "size", messages[index].getSize() );
			querySetCell( list, "subject", messages[index].getSubject() );
			//querySetCell( list, "textbody", messages[index].getContent().getBodyPart().getContent() );
			querySetCell( list, "to", ArrayToList(messages[index].getRecipients( recipient.TO )) );
			querySetCell( list, "uid", messages[index].getMessageID() );
			querySetCell( list, "user", messages[index].isSet(flag.USER) );
		}
		objFolder.close( true );
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
				querySetCell(list, "parent", folders[index].getParent().getName());
				querySetCell(list, "unread", folders[index].getUnreadMessageCount());
				querySetCell(list, "totalmessages", folders[index].getMessageCount());
			}

		}

		return list;

	}

	public function markRead( required string connection, string folder ){

		var flag = CreateObject("Java", "javax.mail.Flags$Flag");
		var objFolder = getFolder( arguments.connection, arguments.folder );
		objFolder.open( objFolder.READ_WRITE );
		var messages = objFolder.getMessages();

		loop from="1" to="#ArrayLen( messages )#" step="1" index="index"{
			messages[index].setFlag(flag.SEEN, true);
		}
		objFolder.close(true);

		return messages;

	}

	public function delete( required connection, string folder ){

		var flag = CreateObject("Java", "javax.mail.Flags$Flag");
		var objFolder = getFolder( arguments.connection, arguments.folder );
		objFolder.open( objFolder.READ_WRITE );
		var messages = objFolder.getMessages();

		loop from="1" to="#ArrayLen( messages )#" step="1" index="index"{
			messages[index].setFlag(flag.DELETED, true);
		}
		objFolder.close(true);

		return messages;

	}

	public function moveMail( required connection, required string newFolder, required string messageNumber, string folder ){

		var objFolder = getFolder( arguments.connection, arguments.folder );
		var objNewFolder = getFolder( arguments.connection, arguments.newFolder );

		objFolder.open( objFolder.READ_WRITE );
		var messages = objFolder.getMessages( JavaCast( "int[]", ListToArray(arguments.messageNumber)) );
		objFolder.copyMessages( messages, objNewFolder );
		objFolder.close(true);

		return messages;

	}

	public function createFolder( required string connection, required string folder ){

		var objFolder = getFolder( arguments.connection, arguments.folder );
		objFolder.create( 3 );

		return objFolder;

	}

	public function renameFolder( required string connection, required string folder, required string newFolder ){

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

		if( !len( arguments.folder ) GT 0 ){
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

	private function createQuery( required string columns, required boolean all=false ){

		var list = QueryNew( columns );
		loop from="1" to="#ArrayLen( messages )#" step="1" index="index"{
			queryAddRow(list);
			querySetCell( list, "answered", messages[index].isSet(flag.ANSWERED) );
			querySetCell( list, "attachmentfiles", messages[index].isSet(flag.ANSWERED) );
			querySetCell( list, "attachments", messages[index].isSet(flag.ANSWERED) );
			querySetCell( list, "body", messages[index].getContent() );
			querySetCell( list, "cc", messages[index].getRecipients( recipient.CC ) );
			querySetCell( list, "deleted", messages[index].isSet(flag.DELETED) );
			querySetCell( list, "draft", messages[index].isSet(flag.DRAFT) );
			querySetCell( list, "flagged", messages[index].isSet(flag.FLAGGED) );
			querySetCell( list, "from", messages[index].getSender().toString() );
			querySetCell( list, "header", ArrayToList( createObject( "java", "java.util.Collections" ).list( messages[index].getAllHeaderLines() ) ) );
			querySetCell( list, "htmlbody", messages[index].getContent().getBodyPart(1).getContent() );
			querySetCell( list, "lines", messages[index].getLineCount() );
			querySetCell( list, "messageid", messages[index].getMessageID() );
			querySetCell( list, "messagenumber", messages[index].getMessageNumber() );
			querySetCell( list, "recent", messages[index].isSet(flag.RECENT) );
			querySetCell( list, "replyto", ArrayToList(messages[index].getReplyTo()) );
			querySetCell( list, "rxddate", messages[index].getReceivedDate() );
			querySetCell( list, "seen", messages[index].isSet(flag.SEEN) );
			querySetCell( list, "size", messages[index].getSize() );
			querySetCell( list, "subject", messages[index].getSubject() );
			querySetCell( list, "textbody", messages[index].getContent().getBodyPart(0).getContent() );
			querySetCell( list, "to", ArrayToList(messages[index].getRecipients( recipient.TO )) );
			querySetCell( list, "uid", messages[index].getMessageID() );
			querySetCell( list, "user", messages[index].isSet(flag.USER) );
		}
		return objFolder;

	}

	private function getFileName( required message ){
		var part = createObject("Java", "javax.mail.Part");
		var multiPart = arguments.message.getContent().getCount();
		var res = {};
		dump(multiPart);

		for ( i=0; i LT multiPart; i++ ) {

			var bodyPart = arguments.message.getContent().getBodyPart( i );

			if( compareNoCase( bodyPart.getDisposition(), part.ATTACHMENT ) ){
				//res.attachments = bodyPart.getDataHandler().getFileName();
				dump(bodyPart.getDataHandler());
			}
			if( compareNoCase( bodyPart.getDisposition(), part.INLINE ) ){
				res.content = bodyPart.getContent().toString();
			}

		}
		dump(res);abort;
		return res;
	}

}