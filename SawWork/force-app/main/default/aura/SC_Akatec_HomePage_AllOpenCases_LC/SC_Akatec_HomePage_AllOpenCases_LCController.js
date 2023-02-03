({
    
    handleQueueChange:function(component, event, helper) {
        var btn=document.getElementById("savebtn").innerHTML="Loading..";
        document.getElementById("savebtn").className = "slds-button slds-button_success";
        var selectedOptionValue = component.find("queue").get("v.value");
        helper.getAllCases(component,event,helper,selectedOptionValue);
        
    },
    
    destroy:function(component, event, helper) {
        //Changes by Sharath for ESESP-3407
        //Moving code to helper
        //console.log("destroy");
        //var pollId=component.get("v.PollID");
        //window.clearInterval(pollId);
        helper.destroyPollerHelper(component, event, helper);
        component.destroy();
        
        
    },    
    //Method -2 : For opening assign case modal and storing the CaseID
    openModal:function(component, event, helper) {
        var caseID = event.target.id;
        component.set('v.AssignedCaseID', caseID);
        var profileid=component.get('v.UserProfile');
        console.log("profileId: " + $A.get('$SObjectType.CurrentUser.ProfileId') );
        console.log("profileName: " + $A.get('$SObjectType.CurrentUser.Profile.Name') );        
        if(profileid=='00eG0000000f0ZQIAY'||profileid=='00eG0000000f0ZPIAY')
        {   
            component.set('v.spinner',true);
            var action = component.get("c.getDirectReporteeCount");
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                            component.set('v.spinner',false);
                    component.set('v.isOpenManager', true);
                    var conts =response.getReturnValue();
                    var custs = [];
                    for(var key in conts){
                        custs.push({value:conts[key], key:key});
                    }
                    component.set("v.ReporteeList", custs);
                    
                }
            });
            $A.enqueueAction(action);             
        }
        else
            component.set('v.isOpen', true);
        
    },
    //Method -3 : For closing the case modal
    
    closeModel:function(component, event, helper) {
        component.set('v.isOpen', false);
        component.set('v.isOpenManager', false);
        
    },
    
    //Method -4 : After scripts are loaded, for retrieving the saved geographies and then loading the case table
    scriptsLoaded : function(component, event, helper) {
        
       
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        var action = component.get("c.getSavedGeo");
        action.setParams({
            "userID": userId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var final=response.getReturnValue();
                //Adding choosen geographies to the UI
                component.set("v.valuegeo",final);
                //Calling the function to return the case data based on saved values
                setTimeout(function(){  
                    
                    helper.getAllCases(component,event,helper,'My Queues');
                }, 500);
                
            }          
        });
        $A.enqueueAction(action);
        
    },
    
    //Method -5 : For initializing the geographies choice picklist
    
    doInit: function(component, event, helper) {
     
        var action = component.get("c.getprofileId");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var profileID=response.getReturnValue();
                component.set("v.UserProfile", profileID);
            }
        });
        $A.enqueueAction(action); 
        //Changes by Sharath for ESESP-3407
        //Moving the code to helper method
        console.log('Inside INIT:');
        helper.createPollerHelper(component,event,helper);
        //var pollId = window.setInterval(
        //    $A.getCallback(function() { 
        //        var Queue=component.find("queue").get("v.value");
        //        helper.getAllCases(component,event,helper,Queue);
        //        
        //    }), 100000
        //);
        //component.set('v.PollID', pollId);
        
    },
    
    //Method -6 : For saving the user choosen geography filters
    
    saveFilters:function(component, event, helper) {
        
        var btn=document.getElementById("savebtn").innerHTML="Loading..";
        document.getElementById("savebtn").className = "slds-button slds-button_success";
        
        var res =component.find("CaseGeoCheckbox").get("v.value") ;
        
        //If the user has selected no geographies then throw error and handle 
        if(res=='')
        {
            helper.showToastMessage(component, event, helper,'An Empty Table?','You need to select atleast 1 geography','error','dismissible');   
            var btn=document.getElementById("savebtn").innerHTML="Save and Apply";
            document.getElementById("savebtn").className = "slds-button slds-button_brand";
            
        }
        else{
            //Changes by Sharath for ESESP-3407: Stop the poller before saving the filters
            helper.destroyPollerHelper(component, event, helper);
            var selectedGeo = res;
             
            var userId = $A.get("$SObjectType.CurrentUser.Id");
            var Queue=component.find("queue").get("v.value");
            
            var action = component.get("c.getCases");
            action.setParams({
                "IsUpsert":'true',
                "userID": userId,
                "SelectedGeoFromUser":selectedGeo,
                "QueryType":Queue
                
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    //Calling the getAllcases method to refresh the table
                    var caseLst=response.getReturnValue();
                    component.set('v.TechnicalCount', caseLst.length);
                    component.set('v.AllCaseList', caseLst);
                    console.log(caseLst);
                    var btn=document.getElementById("savebtn").innerHTML="Save and Apply";
                    document.getElementById("savebtn").className = "slds-button slds-button_brand";
                    
                }
                //Changes by Sharath for ESESP-3407: Start the poller After the action method executes
                helper.createPollerHelper(component,event,helper);
                
            });
            $A.enqueueAction(action); 
        }
        
    },
    //Method -7 : WorkSpace API for opening case in a new console tab
    
    openNewTab:function(component, event, helper) {
        var ID = event.target.id;
        var workspaceAPI = component.find("workspace");
        workspaceAPI.openTab({
            pageReference: {
                "type": "standard__recordPage",
                "attributes": {
                    "recordId":ID,
                    "actionName":"view"
                },
                "state": {}
            },
            focus: true
        }).then(function(response) {
            workspaceAPI.getTabInfo({
                tabId: response
            }).then(function(tabInfo) {
            });
        }).catch(function(error) {
            console.log(error);
        });
    },
    
    //Method -8 : JQuery search table function
    search: function(component, event, helper) {
        $(document).ready(function(){
            $("#myInput").on("keyup", function(event) {
                //Changes by Sharath for ESESP-3407
                //Search the table anly after enter key is pressed
                var value = $(this).val().toLowerCase();
                if(event.keyCode === 13)
                {                       
                    //var value = $(this).val().toLowerCase();
                    $("#AllOpenCases tr").filter(function() {
                        $(this).toggle($(this).text().toLowerCase().indexOf(value) > -1)
                    });
                }
            });
        });
    },
    
    //Method -9 : Assigning the case to the user after clicking on Yes in the modal, and then firing lightning event to refresh both "My open Cases" and "Technincal Cases" tables
    
    handleClick : function (component, event, helper) {
        component.set('v.spinner',true);
        var caseID= component.get('v.AssignedCaseID');
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        
        var action = component.get("c.assignCaseToUser");
        action.setParams({
            "userID": userId ,
            "CaseID": caseID
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var resp=response.getReturnValue();
                if(resp=='true'){
                    component.set('v.spinner',false);
                    helper.showToastMessage(component, event, helper,'Assigned','Yaay! More work!','success','dismissible');
                    var Queue=component.find("queue").get("v.value");                  
                    helper.getAllCases(component, event, helper,Queue);
                    var appEvent = $A.get("e.c:SC_Akatec_MyOpenCases_Refresher"); // firing event to refresh my open table
                    appEvent.fire();
                }
                else
                {
                    component.set('v.spinner',false);
                    helper.showToastMessage(component, event, helper,'Error',resp,'error','dismissible');
                    
                }
                
            }
        });
        $A.enqueueAction(action);
        component.set('v.isOpen', false);        
        
    },
    //Method -10: WorkSpace API for New Case button
    
    openNewCase : function(component, event, helper) {
        
        $A.get("e.force:navigateToURL").setParams({ 
            "url": '/one/one.app#/sObject/Case/new'            
        }).fire();
    },
    
    assignCasetoDirectReportee:function(component, event, helper) {
        component.set('v.spinner',true);
        var name = event.target.id;
        var CaseIDtoassign=component.get('v.AssignedCaseID');
        var action = component.get("c.getReporteeDetailsandAssign");
        action.setParams({
            "username": name ,
            "CaseID": CaseIDtoassign
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var resp=response.getReturnValue();
                    component.set('v.isOpenManager', false);
                    helper.showToastMessage(component, event, helper,'Assigned','Yaay! More work for the reportee!','success','dismissible');
                    component.set('v.spinner',false);
                    var Queue=component.find("queue").get("v.value");                  
                    helper.getAllCases(component, event, helper,Queue);
                    
                
            }
        });
        $A.enqueueAction(action);
        
    },
    sort:function(component, event, helper) {
        
        var n = event.target.id;            
        var table, rows, switching, i, x, y, shouldSwitch, dir, switchcount = 0;
        table = document.getElementById("AllOpenCases");
        switching = true;
        dir = "asc"; 
        while (switching) {
            switching = false;
            rows = table.rows;
            for (i = 1; i < (rows.length - 1); i++) {
                shouldSwitch = false;
                
                x = rows[i].getElementsByTagName("TD")[n];
                y = rows[i + 1].getElementsByTagName("TD")[n];
                if (dir == "asc") {
                    if (x.textContent.toLowerCase() > y.textContent.toLowerCase()) {
                        shouldSwitch= true;
                        break;
                    }
                } else if (dir == "desc") {
                    if (x.textContent.toLowerCase() < y.textContent.toLowerCase()) {
                        shouldSwitch = true;
                        break;
                    }
                }
            }
            if (shouldSwitch) {
                
                rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
                switching = true;
                switchcount ++;      
            } else {
                
                if (switchcount == 0 && dir == "asc") {
                    dir = "desc";
                    switching = true;
                }
            }
        }
        
    },
    
    sortnum:function(component, event, helper) {
        
        
        var table, rows, switching, i, x, y, shouldSwitch;
        table = document.getElementById("AllOpenCases");
        switching = true;
        
        while (switching) {
            //start by saying: no switching is done:
            switching = false;
            rows = table.rows;
            
            for (i = 1; i < (rows.length - 1); i++) {
                //start by saying there should be no switching:
                shouldSwitch = false;
                
                x = rows[i].getElementsByTagName("TD")[11];
                y = rows[i + 1].getElementsByTagName("TD")[11];
                //check if the two rows should switch place:
                if (Number(x.innerHTML) > Number(y.innerHTML)) {
                    //if so, mark as a switch and break the loop:
                    shouldSwitch = true;
                    break;
                }
            }
            if (shouldSwitch) {
                
                rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
                switching = true;
            }
        }
        
        
    }    
})