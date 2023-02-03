({
	handleShowCreateForm: function( component, event, helper ) {
		var pageRef = component.get("v.pageReference");
        if ($A.util.isEmpty(pageRef) || $A.util.isEmpty(pageRef.state)) {
          return;
        }
        var urlParamMap = {
            'objectname' : '',      // object whose create form to display - Draft_Invoice__c
            'recordtypeid' : '',    // record type for new record (optional)
            'recordid' : ''         // id of Merge Contract Header where button was clicked
        }; 

        for ( let key in pageRef.state ) {
            let lowerKey = key.toLowerCase().replace(/^c__/, "");
            console.log('First: ', lowerKey, key);
            if ( urlParamMap.hasOwnProperty( lowerKey ) ) {
                urlParamMap[lowerKey] = pageRef.state[key];
            }
        }

        Promise.resolve()
            .then( function() {
                if ( !$A.util.isEmpty( urlParamMap.recordid ) ) {
                    // workaround for not being able to customize the cancel
                    // behavior of the force:createRecord event. instead of
                    // the user seeing a blank page, instead load in the background
                    // the very record the user is viewing so when they click cancel
                    // they are still on the same record.
                    helper.navigateToUrl( '/' + urlParamMap.recordid );
                    // give the page some time to load the new url
                    // otherwise we end up firing the show create form
                    // event too early and the page navigation happens
                    // afterward, causing the quick action modal to disappear.
                    return new Promise( function( resolve, reject ) {
                        setTimeout( resolve, 1000 );
                    });
                }
            })
            .then( function() {
                helper.showCreateForm( component, urlParamMap, pageRef );
            });
	},

    showCreateForm: function( component, urlParamMap, pageRef ) {
		var helper = this;
        helper.getDefaults(component, pageRef.state['c__recordId']).then(
        $A.getCallback( function( defaultFields ) {

                let eventParamMap = {
                    'defaultFieldValues' : {}
                };

                if ( !$A.util.isEmpty( urlParamMap.objectname ) ) {
                    eventParamMap['entityApiName'] = urlParamMap.objectname;
                }

                if ( !$A.util.isEmpty( urlParamMap.recordtypeid ) ) {
                    eventParamMap['recordTypeId'] = urlParamMap.recordtypeid;
                }
                for (var fieldName in  defaultFields){
                    if(fieldName != 'Id')
	                    eventParamMap.defaultFieldValues[fieldName] = defaultFields[fieldName] || null;
                }
                return eventParamMap;

            })).then( $A.getCallback( function( eventParamMap ) {
    			$A.get( 'e.force:createRecord' ).setParams( eventParamMap ).fire();
    		})).catch( $A.getCallback( function( err ) {
    			helper.logActionErrors( err );
    		}));
        },

    navigateToUrl: function( url ) {

        if ( !$A.util.isEmpty( url ) ) {
            $A.get( 'e.force:navigateToURL' ).setParams({ 'url': url }).fire();
        }
    },

    logActionErrors : function( errors ) {
        if ( errors ) {
            if ( errors.length > 0 ) {
                for ( let i = 0; i < errors.length; i++ ) {
                    console.error( 'Error: ' + errors[i].message );
                }
            } else {
                console.error( 'Error: ' + errors );
            }
        } else {
            console.error( 'Unknown error' );
        }
    },

    getDefaults : function(component, contractId){
        return new Promise( function( resolve, reject ) {
            component.set("v.showSpinner", true );
            let action = component.get("c.getDefaults");
            action.setParams({
                "relatedContractId": contractId
            });

            action.setCallback(this, function(response){
                component.set( 'v.showSpinner', false );
                var state = response.getState();
                //SUCCESS, ERROR or INCOMPLETE
                if(state=='SUCCESS'){
                    resolve(response.getReturnValue());
                } else{
                    console.error( 'Error calling action "' + getDefaults + '" with state: ' + response.getState() );

                    helper.logActionErrors( response.getError() );
                }
            })

        	$A.enqueueAction(action);
        });
    }
})