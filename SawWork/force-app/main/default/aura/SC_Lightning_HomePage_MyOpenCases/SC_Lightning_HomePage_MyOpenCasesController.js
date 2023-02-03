({
    //Method -1 : To open SLA Alerts Side bar
    openNav : function(component,event,helper){
        
        document.getElementById("mySidenav").style.width = "270px";
    },
    
    //Method -2 : To Close SLA Alerts Side bar    
    closeNav : function(component,event,helper){
        
        document.getElementById("mySidenav").style.width = "0";
    },
    
    
    //Method -4 : Oppening the Akachat transcript related to a case
    openAkaChatModal : function(component, event, helper) {
        component.set("v.spinner",true);
        var AkachatID=event.target.id;
        var action = component.get("c.getAkaChatTranscript");
        action.setParams({
            "AkachatID": AkachatID
        });
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var akachatlist=response.getReturnValue();
                component.set("v.AkachatBody",akachatlist);
                component.set("v.isAkaModalOpen",true);
                component.set("v.spinner",false);
                
            }
        });
        $A.enqueueAction(action);
        
    },
    
    //Method -5 : Close Akachat modal
    closeModal:function(component, event, helper) {
        component.set("v.isAkaModalOpen",false);
        
    },
    
    //Method -6 : Init Function
    doInit: function(component, event, helper) {
        
        component.set("v.spinner",true);
        
        //Setting Options for Status filter
        var statusopts=['All','Assigned','Work in Progress','Mitigated / Solution Provided'];
        var opts = [];
        for (var i = 0; i < statusopts.length; i++) {
            opts.push({
                class: "optionClass",
                label: statusopts[i],
                value: statusopts[i]
            });
        }
        component.find('statusid').set("v.options", opts);        
        helper.getMyOpenCases(component, event, helper);
    },
    
    //Method -7 : Applying Filter values - When apply button is pressed, assigning case, clearing customer update, on force:refresh
    ApplyFilters:function(component, event, helper) {
        
        component.set("v.spinner",true);
        var selectedwork = component.find("WorkTypeCheckbox").get("v.value") ;
        
        if(selectedwork=='')
        {
            helper.showToastMessage(component, event, helper,'An Empty Table?','You need to select atleast 1 Work Type','error','dismissible');   
                    component.set("v.spinner",false);

        }
        
        else
        {
            var selectCmp = component.find("statusid").get("v.value");
            
            var userId = $A.get("$SObjectType.CurrentUser.Id");
            var slalist=[];
            var action = component.get("c.getMyopenCases");
            action.setParams({
                "userID": userId,
                "QueryType":'MyOpenCases'
            });
            action.setCallback(this, function(response) {
                if (response.getState() == "SUCCESS") {
                    var orginallist=response.getReturnValue();
                    for(var i=0;i<orginallist.length;i++)
                    {
                        if(orginallist[i].SLA_Color=="Red")
                        {slalist.push(orginallist[i]);}
                    }
                    component.set("v.spinner",false);
                    component.set("v.SLAMissList", slalist);
                    component.set("v.SLAMissListcount", slalist.length);
                    if(slalist.length>0)
                        component.set("v.HasMissedSLA",true);
                    else
                        component.set("v.HasMissedSLA",false);
                    
                    var filteredlist=[];
                    //If no filter is applied
                    if(selectedwork.length==2 && selectCmp=='All' )
                    {
                        component.set("v.OpenCase", orginallist);
                        component.set("v.OpenCount", orginallist.length);
                    }
                    else
                    {	//If all work types are selected
                        if(selectedwork.length==2)
                        {	
                            //Filtering only by status
                            for(var i=0;i<orginallist.length;i++)
                            {
                                if(orginallist[i].EachCaseRec.Status==selectCmp)
                                    filteredlist.push(orginallist[i]);
                            }
                        }
                        else 
                        {	//If status is Set to 'All'
                            if(selectCmp=='All')
                            {	//Filtering only by selected work type
                                for(var i=0;i<orginallist.length;i++)
                                {
                                    if(orginallist[i].EachCaseRec.Work_Type__c==selectedwork[0])
                                        filteredlist.push(orginallist[i]);
                                    
                                }
                                
                            }
                            else
                            {	//Filtering by both filter values
                                for(var i=0;i<orginallist.length;i++)
                                {
                                    if(orginallist[i].EachCaseRec.Work_Type__c==selectedwork[0] && orginallist[i].EachCaseRec.Status==selectCmp)
                                        filteredlist.push(orginallist[i]);
                                    
                                }
                            }
                        }
                        component.set("v.OpenCase", filteredlist);
                        component.set("v.OpenCount", filteredlist.length);
                    }
                }
                
            });
            $A.enqueueAction(action);
            
        }
    },
    
    //Method -8 : Open Case in new tab
    
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
    
    
    //Method -9: Clear customer update and open case in new tab
    
    openNewTabandClear:function(component, event, helper) {
        var ID = event.target.id;
        
        //Opening the tab in console
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
        
        //Removing the update notification
        
        var action = component.get("c.suppressCaseUpdate");
        action.setParams({
            "CaseID": ID
        });
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var appEvent = $A.get("e.c:SC_Akatec_MyOpenCases_Refresher"); // firing event to refresh my open table
                appEvent.fire();
                
            }
        });
        $A.enqueueAction(action);
        
    },
    
    //Method -10: Inline edit form modal logic
    openEditForm:function(component, event, helper) {
        var ID = event.target.id;
        component.set('v.isEditCaseOpen',true);
        component.set('v.EditCaseID',ID);
        
    },
    //Method -11: Closing Inline edit form modal
    closeEditModal:function(component, event, helper) {
        component.set("v.spinner","false");
        component.set('v.isEditCaseOpen',false);
    },
    handleSuccess:function(component, event, helper) {
        component.set("v.spinner","false");
        component.set('v.isEditCaseOpen',false);
        helper.showToastMessage(component, event, helper,'Done!','Your changes are saved!','success','dismissible');   
    },
    handleSubmit:function(component, event, helper) {
        component.set("v.spinner","true");
    },
    handleSelect: function (component, event, helper) {
        
        var selectedMenuItemValue = event.getParam("value");
        if(selectedMenuItemValue=='Change')
        {
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                "url": "/lightning/settings/personal/AdvancedUserDetails/home"
            });
            urlEvent.fire();
        }
        
    },
    handleOnError: function (component, event, helper) {
        component.set("v.spinner","false");
        helper.showToastMessage(component, event, helper,'Oops!','Uh-oh! Looks like something errored out!','error','dismissible');   
        
    },
    
    // ------End of inline edit methods for handling events -------------
    sort:function(component, event, helper) {
        
        var n = event.target.id;            
        var table, rows, switching, i, x, y, shouldSwitch, dir, switchcount = 0;
        table = document.getElementById("myOpenCasesTable");
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
        table = document.getElementById("myOpenCasesTable");
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