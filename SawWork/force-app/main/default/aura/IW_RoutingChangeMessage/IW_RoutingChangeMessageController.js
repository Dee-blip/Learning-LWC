({
    handleRecordUpdated : function(component) {

        //console.log(' check testt1t1 : ' , component.get("v.simpleRecord.Status__c") );

        var statusVal = component.get("v.simpleRecord.Status__c");
        var createddate = component.get("v.simpleRecord.CreatedDate");
        var messageSetting ;
        var showMessage;
        var goliveDate;
        var action;

        try {

            action = component.get('c.getRoutingMessageToggle');
            console.log(' after action :: ' );
            //action.setStorable();
            console.log( '  anything ::1111');
            action.setCallback(this,function(a){
                            
                
                //console.log( JSON.parse(a.getReturnValue()) );
                console.log('vallss : ' , JSON.parse(a.getReturnValue()) );

                messageSetting = JSON.parse(a.getReturnValue()) ;
                showMessage = (messageSetting.split(":>")[1]).trim() === "True" ? true : false ;
                goliveDate = (messageSetting.split(":>")[2]).trim() ;

                console.log(' shomsgg : ', showMessage );
                console.log(' datess : ' ,createddate , ' setting date : ' , goliveDate , ' cndttn : ' , createddate <  goliveDate  );
                console.log(' cndtn  ' , ( statusVal === 'Saved' && statusVal === 'Awaiting Approval' && statusVal === 'Escalated' ) );

                if( showMessage && createddate <  goliveDate )
                {
                    console.log(' setting false ? : ' , component.get("v.show" ) );
                    component.set("v.show", true);
                    component.set("v.message", (messageSetting.split(":>")[0]).trim() );

                    console.log(' setting false ? : ' , component.get("v.show" ) );
                }

                
            });
            $A.enqueueAction(action);
            
        } catch (e) {
            console.log( ' error while processing ::: ' , e.message );

        }


        



        // if( statusVal !== 'Approved' && statusVal !== 'Cancelled' && statusVal !== 'Rejected' )
        // {
        //     component.set("v.show", true);
        //     console.log(' setting false ? : ' , component.get("v.show" ) );
        // }

    }


})