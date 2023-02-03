({
    init: function (component, event, helper) {
        //console.log('Inside Item');
        var recordsList = component.get("v.records");
        //console.log(recordsList);
        var objectList = [];
        var headerFieldsAPINames = [];
        var headerFieldsAPINamesFinal = [];
        var records = [];
        var record = [];
        
        var singleRecord = recordsList[0];
        console.log(singleRecord);
        for ( var key in singleRecord) {
            if (key != "attributes" && key != "Id") {
                headerFieldsAPINames.push(key);
            }
        }
        //console.log('headerFieldsAPINames');
        //console.log(headerFieldsAPINames);
        for ( var key in headerFieldsAPINames) {
            var item = headerFieldsAPINames[key]
            if (item.endsWith("__c")) {
                let relationshipName = item.replace("__c","__r");
                if (!headerFieldsAPINames.includes(relationshipName))
                	headerFieldsAPINamesFinal.push(item);
            } else {
                headerFieldsAPINamesFinal.push(item);
            }
        }
        //console.log('headerFieldsAPINamesFinal');
        //console.log(headerFieldsAPINamesFinal);
        
        helper.serverSideCall(component,event,helper,"c.getFieldsLabels",{fieldsAPINames : headerFieldsAPINamesFinal,objectName : component.get("v.sObjectName")}).then(
            function(response) {
                //console.log('SH : conditions - response :'+response);
                if (response != null) {
                    //console.log(response);
                    // Set the 'menuItems' variable back in the component.
                    
                    component.set("v.headerFieldsNames", response);
                    //console.log(headerFieldsAPINames);
                    recordsList.forEach((item) => {
                        //item.forEach((item) => {
                        //console.log(item);
                        record = [];
                        record.push({'value':"/partners/s/detail/"+item.Id, 'label':item.Name, 'isId': true});
                        //console.log(record);
                        for ( var key in item) {
                            //console.log(key);
                            if (key.endsWith("__r")) {
                                record.push({'value': "/partners/s/detail/"+item[key].Id, 'label': item[key].Name, 'isId': true});
                            } else if (key != "attributes" && key != "Id" && key !="Name") {
                                if (key.endsWith("__c")) {
                                    let relationshipname = key.replace("__c","__r");
                                    if (!headerFieldsAPINames.includes(relationshipname)) {
                                        record.push({'value': item[key], 'label': key, 'isId': false});
                                    }
                                } else {
                                	record.push({'value': item[key], 'label': key, 'isId': false});
                                }
                            }
                        }
                    	records.push({'value': record});
                });
                //console.log(headerFieldsAPINames);
                //console.log(records);
                component.set("v.headerFieldsAPINames",headerFieldsAPINames);
                component.set("v.processedRecords",records);
                var tableIdVal = '#'+ component.get("v.sObjectName") + '__table';
                component.set("v.tableId",component.get("v.sObjectName") + '__table');
                setTimeout(function(){ 
                      $(tableIdVal).DataTable();
                  }, 500);
            }
            }
        ).catch(
            function(error) {
                component.set("v.status" ,error ); 
                console.log(error);
            }
        );
    },
    
    scriptsLoaded : function(component, event, helper) {
        
        jQuery("document").ready(function(){
            console.log('scripts loaded');
            console.log('Setting datatable');
            /*$('#example').DataTable({
              responsive: true,
              paging: true,
    		  searching: true
          });*/
          /*setTimeout(function(){ 
              $('#tableId').DataTable();
          }, 500);*/
      });
        
    },
});