component output=false {

	property name="presideObjectService" inject="presideObjectService";
	property name="assetManagerService"  inject="AssetManagerService";

	public string function index( event, rc, prc, args={} ) output=false {
		var allowedTypes        = args.allowedTypes ?: "";
		var prefetchCacheBuster = assetManagerService.getPrefetchCachebusterForAjaxSelect( ListToArray( allowedTypes ) );

		if ( Len( Trim( args.savedData.id ?: "" ) ) ) {
			var sourceObject = args.sourceObject ?: "";

			if ( presideObjectService.isManyToManyProperty( sourceObject, args.name ) ) {
				args.savedValue = presideObjectService.selectManyToManyData(
					  objectName   = sourceObject
					, propertyName = args.name
					, id           = args.savedData.id
					, selectFields = [ "#args.name#.id" ]
				);

				args.defaultValue = args.savedValue = ValueList( args.savedValue.id );
			}
		}

		args.multiple    = args.multiple ?: ( ( args.relationship ?: "" ) == "many-to-many" );
		args.prefetchUrl = event.buildAdminLink( linkTo="assetmanager.ajaxSearchAssets", querystring="maxRows=100&allowedTypes=#allowedTypes#&prefetchCacheBuster=#prefetchCacheBuster#" );
		args.remoteUrl   = event.buildAdminLink( linkTo="assetmanager.ajaxSearchAssets", querystring="q=%QUERY&allowedTypes=#allowedTypes#" );
		args.browserUrl  = event.buildAdminLink( linkTo="assetmanager.assetPickerBrowser", querystring="allowedTypes=#allowedTypes#&multiple=#( args.multiple ? 'true' : 'false' )#" );
		args.uploaderUrl = event.buildAdminLink( linkTo="assetmanager.assetPickerUploader", querystring="allowedTypes=#allowedTypes#&multiple=#( args.multiple ? 'true' : 'false' )#" );

		if ( !Len( Trim( args.placeholder ?: "" ) ) ) {
			args.placeholder = translateResource(
				  uri  = "cms:datamanager.search.data.placeholder"
				, data = [ translateResource( uri=presideObjectService.getResourceBundleUriRoot( "asset" ) & "title", defaultValue=translateResource( "cms:datamanager.records" ) ) ]
			);
		}

		return renderView( view="formcontrols/assetPicker/index", args=args );
	}
}