component {

// CONSTRUCTOR
	public any function init( string logDirectory=ExpandPath( "/logs/rte-logs" ) ) {
		_setLogDirectory( arguments.logDirectory );
		return this;
	}

// PUBLIC API METHODS
	public void function raiseError( required struct error ) {
		var rendered = "";
		var catch    = arguments.error;
		var fileName = "rte-" & GetTickCount() & ".html";
		var filePath = _getLogDirectory() & "/" & filename;

		savecontent variable="rendered" {
			include template="errorTemplate.cfm";
		}
		FileWrite( filePath, Trim( rendered ) );
		_cleanupLogFiles();
		_callErrorListeners( arguments.error );
	}

	public array function listErrors() {
		var files = DirectoryList( _getLogDirectory(), false, "query", "rte-*.html" );
		var errors = [];

		for( var file in files ) {
			errors.append( { date=file.dateLastModified, filename=file.name } );
		}

		errors.sort( function( a, b ){
			return a.date < b.date ? 1 : -1;
		} );

		return errors;
	}

	public string function readError( required string logFile ) {
		try {
			return FileRead( _getLogDirectory() & "/" & arguments.logFile );
		} catch( any e ) {
			return "";
		}
	}

	public void function deleteError( required string logFile ) {
		try {
			return FileDelete( _getLogDirectory() & "/" & arguments.logFile );
		} catch( any e ) {
		}
	}

	public void function deleteAllErrors() {
		listErrors().each( function( err ){
			deleteError( err.filename );
		} );
	}

// PRIVATE HELPERS
	private void function _callErrorListeners( required struct error ) {
		_callListener( "app.services.errors.ErrorHandler", arguments.error );

		var extensions = new preside.system.services.devtools.ExtensionManagerService( "/app/extensions" ).listExtensions( activeOnly=true );
		for( var extension in extensions ) {
			_callListener( "app.extensions.#extension.name#.services.errors.ErrorHandler", arguments.error );
		}
	}

	private void function _callListener( required string listenerPath, required struct error ) {
		var filePath = ExpandPath( "/" & Replace( arguments.listenerPath, ".", "/", "all" ) & ".cfc" );
		if ( FileExists( filePath ) ) {
			try {
				CreateObject( arguments.listenerPath ).raiseError( arguments.error );
			} catch ( any e ){}
		}
	}

	private void function _cleanupLogFiles() {
		var files             = DirectoryList( _getLogDirectory(), false, "query", "*.html", "datelastmodified asc" );
		var maxFilesToKeep    = 50;
		var fileCountToDelete = files.recordCount - maxFilesToKeep;
		var filesDeleted      = 0;
		var currentRow        = 0;
		var fileToDelete      = "";

		while ( filesDeleted < fileCountToDelete ) {
			currentRow++;
			fileToDelete = files.directory[ currentRow ] & "/" & files.name[ currentRow ];
			try {
				FileDelete( fileToDelete );
				filesDeleted++;
			} catch( any e ) {
				break;
			}
		}
	}

// GETTERS AND SETTERS
	private any function _getLogDirectory() {
		return _logDirectory;
	}
	private void function _setLogDirectory( required any logDirectory ) {
		_logDirectory = Replace( arguments.logDirectory, "\", "/", "all" );
		_logDirectory = ReReplace( _logDirectory, "/$", "" );

		if ( !DirectoryExists( _logDirectory ) ) {
			DirectoryCreate( _logDirectory, true );
		}
	}

}