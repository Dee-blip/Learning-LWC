({
    doInit: function(component, event, helper) {
        var statusopts=['All','Accepted','Pending','Reopened'];
        var opts = [];
        for (var i = 0; i < statusopts.length; i++) {
            opts.push({
                class: "optionClass",
                label: statusopts[i],
                value: statusopts[i]
            });
        }
        component.find('statusidesc').set("v.options", opts); 
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        var action = component.get("c.getMyOpenEscalations");
        action.setParams({
            "userID": userId
        });
        console.log("userID", userId);
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var myopenlst=response.getReturnValue();
                console.log("esc1",myopenlst);
                component.set("v.OpenEscalation", myopenlst);
                component.set("v.OpenCount", myopenlst.length);
                
                
            }
            
        });
        $A.enqueueAction(action);
        
    },
    
    ApplyEscFilters:function(component, event, helper) {
        var Chkvalue = component.find("EscCheckbox").get("v.value");
        var Statusvalue = component.find("statusidesc").get("v.value");
        
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        var action = component.get("c.getMyFilteredEscalations");
        action.setParams({
            "userID": userId,
            "SelSeverity" : Chkvalue,
            "SelStatus": Statusvalue
        });
        console.log("calling filter query");
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var myopenlst=response.getReturnValue();
                console.log("filter", myopenlst);
                  component.set("v.OpenEscalation", response.getReturnValue());
                component.set("v.OpenCount", response.getReturnValue().length);
              }
        });
        $A.enqueueAction(action);
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
    sort:function(component, event, helper) {
        
        var n = event.target.id;            
        var table, rows, switching, i, x, y, shouldSwitch, dir, switchcount = 0;
        table = document.getElementById("myopenescalations");
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