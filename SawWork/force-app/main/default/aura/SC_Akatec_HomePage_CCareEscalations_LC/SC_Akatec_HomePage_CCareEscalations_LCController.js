({
    destroy:function(component, event, helper) {
        // console.log("destroy CCare");
        var pollIdCCare=component.get("v.PollIDCCare");
        window.clearInterval(pollIdCCare);
        component.destroy();
    },   
    
    handleQueueChange:function(component, event, helper) {
        var pollId=component.get("v.PollIDCCare");
        window.clearInterval(pollId);
        console.log("Clearing poller");
        var selectedEscOptionValue = component.find("EscQueue").get("v.value");
        helper.CcarePoller(component,event,helper,selectedEscOptionValue);
         var pollIdCCares =window.setInterval(
            $A.getCallback(function() { 
                var Queue=component.find("EscQueue").get("v.value");
                helper.CcarePoller(component,event,helper,Queue);
            }), 300000
            
        );  
        component.set('v.PollIDCCare', pollIdCCares);
        console.log(pollIdCCares);
    },
    
    doInit: function(component, event, helper) {
        component.set("v.spinner","true");
        helper.CcarePoller(component,event,helper,'My Queues');
        
        var pollIdCCares =window.setInterval(
            $A.getCallback(function() { 
                var Queue=component.find("EscQueue").get("v.value");
                helper.CcarePoller(component,event,helper,Queue);
            }), 300000
            
        );  
        component.set('v.PollIDCCare', pollIdCCares);
        
        
    },
    
    
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
                // console.log("The recordId for this tab is: " + tabInfo.recordId);
            });
        }).catch(function(error) {
            console.log(error);
        });
    },
    openModal:function(component, event, helper) {
        component.set('v.isOpen', true);
        var idx = event.target.id;
        component.set('v.AssignedTechID', idx);
        
    },
    closeModel:function(component, event, helper) {
        component.set('v.isOpen', false);
    },
    
    handleClick:function(component, event, helper) {
        var techID= component.get('v.AssignedTechID');
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        component.set("v.spinner","true");
        
        var action = component.get("c.assignEscalationToUser");
        action.setParams({
            "userID": userId ,
            "techID": techID
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var resp=response.getReturnValue();
                if(resp=='true'){
                    var appEvent = $A.get("e.c:SC_Akatec_MyEscalations_Refresher"); // firing event to refresh my escalations table
                    appEvent.fire();
                    var selectedEscOptionValue = component.find("EscQueue").get("v.value");
                    helper.CcarePoller(component,event,helper,selectedEscOptionValue);
                    helper.showToastMessage(component, event, helper,'Success','Escalation has been assigned to you!','success','dismissible');
                }
                
                else{
                    helper.showToastMessage(component, event, helper,'Error',resp,'error','dismissible');
                }
            }
        });
        $A.enqueueAction(action);
        
        component.set('v.isOpen', false);
        
        
    },
    
    sort:function(component, event, helper) {
        
        var n = event.target.id;            
        var table, rows, switching, i, x, y, shouldSwitch, dir, switchcount = 0;
        table = document.getElementById("subscribedescalations");
        switching = true;
        dir = "asc"; 
        while (switching) {
            switching = false;
            rows = table.rows;
            console.log('row'+rows);
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
        
    }
})