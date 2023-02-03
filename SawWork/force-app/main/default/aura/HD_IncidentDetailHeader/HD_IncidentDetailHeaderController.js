({
    fireMe: function(component, event, helper) {
        var action = component.get("c.getIncidentDetailsFormatedData");
        action.setParams({
            recordId: component.get("v.recordId")
        });
        action.setCallback(this, function(response){

            var metaBeans = [];

            var result = response.getReturnValue();

            component.set("v.type", result['incType']);
            component.set("v.status", result['status']);

            if (result['incType'] == 'Incident') {
                result['incidentNumber'] = 'IN' + result['incidentNumber'];
            } else {
                result['incidentNumber'] = 'SR' + result['incidentNumber'];

            }
            component.set("v.incidentNumber",result['incidentNumber']);

            var metaBeansOrder = ['priority', 'category',
                                  'owner','totalEffort','isVipUser','hasProb','hasCR',
                                  'isChild','isParent','ccInfo','isAPITicket','hasTask','hasAttachments','status']; //helper.returnKeyOrder;

            //lableToShow is map of redable message/ lables against the keyValue in json returned from server
            var lableToShow = {
                "isAPITicket" : "API Created Ticket",
                "priority": "Priority",
                "incidentNumber" : "Number",
                "category" : "Category",
                "categoryTree" : "Category Tree",
                "owner" : "Owner",
                "status" : "Status",
                "isVipUser" : "It's VIP ticket",
                "totalEffort" : "Total time spent on this ticket",
                "hasProb": "Incident has Problem Associated",
                "hasCR" : "Incident has Change Associated",
                "isChild": "Incident is a Child of another Incident",
                "isParent": "Incident is a parent of another incident",
                "ccInfo" : "CC Users",
                "hasAttachments" : "Number of Attachments"
            };
            var keyLookup = {
                "isVipUser" : "VIP",
               //  "isChild" : "Child Ticket",
                "isAPITicket": "API Ticket"

            };
            var keyLookup2 = {
                "hasTask" : "Tasks",
                "isParent" : "Parent Ticket",
                "hasCR" : "Change Request Associated",
                "hasProb" :   "Problem Associated",
                "hasAttachments" : "File Attached"

            };
            var association = {
                "hasTask" : "TaskCount",
                "isParent" : "parentCount",
                "hasCR" : "crCount",
                "hasProb" : "probCount",
                "hasAttachments" : "attachCount"
            }
            metaBeansOrder.forEach(function(key) {
              
                if (result[key] != null) {
                    var temp = {};
                    temp.key = keyLookup[key];
                    temp.label = lableToShow[key];
                    
                   
                    //if (key == "isVipUser" || key == "hasProb" || key == "hasCR") {
                    if (key in keyLookup) {
                    	if (result[key] == true) {
                            temp.value = "slds-badge " + "Style-Default float-left " + key + " " + result[key];
                          	metaBeans.push(temp);
                        }
                    }else if(key in keyLookup2){
                        if(result[key] == true){
                            temp.key = keyLookup2[key];
                            temp.count = result[association[key]];
                            //alert(temp.count);
                            temp.value = "slds-badge " + "Style-Default float-left " + key + " " + result[key];
                            metaBeans.push(temp);
                        }
                    }else if (key == 'category'){
                        temp.tree = result['categoryTree'];
                        temp.value = "slds-badge " + "Style-Default float-left " + key + " " + result[key];
                        temp.key = result[key];
                        temp.label = lableToShow[key];
                        metaBeans.push(temp);
                    }else if(key=='ccInfo'){
                        temp.key = 'CC Users';
                        temp.label = 'CC Users List';
                        temp.cclist = result['ccInfo'];

                        if(temp.cclist != ''){
                           	temp.value = "slds-badge " + "Style-Default float-left " + key + " " + result[key];
                        	metaBeans.push(temp);
                        }

                    }else if(key == 'isChild'){
                        if(result[key] == true ){
                        temp.value = "slds-badge " + "Style-Default float-left " + key + " " + result[key];
                        temp.key =  "Child Ticket";
                        temp.label = "Child Ticket";
                        component.set("v.parentId",result['parentId']);
                        component.set("v.parentName",result['parentName']);
                         
                        metaBeans.push(temp);
                        }
                    }else{
                        temp.value = "slds-badge " + "Style-Default float-left " + key + " " + result[key];
                        temp.key = result[key];
                        temp.label = lableToShow[key];
                        metaBeans.push(temp);
                    }

                    
                     
                }

            });
            component.set("v.values", metaBeans);

        });


        $A.enqueueAction(action);
    },

     handleHover: function(component, event, helper) {

    	$A.util.removeClass(component.find("copyIcon"), 'slds-hide');


    },

     copyToClipboard: function(component, event, helper) {

    	  var copyText = document.getElementById("incNo");

          copyText.select();

        document.execCommand("Copy");

         var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({

        			"message": "Copied to clipboard!"
    			});
    			toastEvent.fire();

    },
    handleMouseOut: function(component, event, helper) {

    	$A.util.addClass(component.find("copyIcon"), 'slds-hide');


    },

    gotoURL : function (component, event, helper) {
        console.log('Enter Here');
        var evt = $A.get("e.force:navigateToComponent");
        console.log('evt'+evt);
        
        evt.setParams({
            componentDef: "c:HD_ShowAttachments",

           componentAttributes :{
             recordId: component.get("v.recordId")
           }
        });

        evt.fire();
    	/*var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": "/lightning/r/a5U0f000000xjtdEAA/related/CombinedAttachments/view"
        });
        urlEvent.fire();*/
	},

    gotoParent: function(component,event,helper){

        var evt = $A.get("e.force:navigateToSObject");
        evt.setParams({
            "recordId": component.get("v.parentId"),
            "isredirect": true
        });
        evt.fire();

    }

})