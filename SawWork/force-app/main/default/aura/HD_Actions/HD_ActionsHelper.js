({
    ActionMenuHelper : function(component,event) {
        
        var RecordId = component.get("v.recordId");
        var targetObjectIdvalue = "a5U2F0000000HG0UAM";//a5UR0000000AKNF //SLA :a5UR0000000AKOD
        if(RecordId != null )
        {
            targetObjectIdvalue = RecordId;
        }
        var getActionMenuProvider = component.get("c.Classobject");
        getActionMenuProvider.setParams({
            IncidentId : targetObjectIdvalue
        });
        getActionMenuProvider.setCallback(this,function(resp){
            var state = resp.getState();
            if(state === "SUCCESS")
            {
                var classobject = resp.getReturnValue();//A class object returned from DAO class
                var status = classobject.incident.BMCServiceDesk__Status_ID__c;// Getting status
                var category = classobject.incident.BMCServiceDesk__Category_ID__c;// Getting category
                var isaccessible = classobject.isAccessibleRecord;// Getting the accessibility from system context
                var  approvalRecordStatus = classobject.approvalRecordStatus; // Getting the Approval status
                console.log('V2 approvalRecordStatus field-->>>'+approvalRecordStatus);
                //for EIS TICKET FLAG
                var is_EIS_TICKET = false;
                
                //logic for Accessibility
                var MyActionmsg = 'Actions are <b style="color:#c23934">disabled</b> as you/your team is not a owner of this ticket. Ticket owner should assign ticket to you or transfer to your group for actions to be enabled.';
                var MyActionmsgApproval = 'Actions are <b style="color:#c23934">disabled</b> since the ticket is under <b>Approval</b>.';
                console.log('V2 isaccessible-->>>'+isaccessible);
                console.log('V2 approvalRecordStatus-->>>'+isaccessible);
                if( isaccessible === true )
                {
                   console.log('I am accessible >>>> :) '); 
                   if(approvalRecordStatus === true )
                   {
                    component.set('v.disableAccess',true);
                    component.set('v.MyActionMsg',MyActionmsgApproval);
                    console.log('I am inside >>>> :) approval');   
                   }
                    else
                    {
                        component.set('v.disableAccess',false);
                    }
                    

                }else if(isaccessible === false )
                {
                    component.set('v.disableAccess',true);
                    component.set('v.MyActionMsg',MyActionmsg);
            
                }//else
                
                //console.log('-->'+JSON.stringify(classobject));
                //Starting the logic for menu Rendering based on configuration
                
                        if(classobject.incident.HD_Parent_Tree__c != null )
                        {
                            var parent_tree = classobject.incident.HD_Parent_Tree__c;
                            //if( (category.indexOf("Corporate IT") > -1) || (parent_tree.indexOf("Corporate IT") > -1))
                            if( (category.indexOf("Corporate IT") > -1) || (parent_tree.indexOf("Corporate IT") > -1))
                            {
                                
                                is_EIS_TICKET = true;
                            }
                            
                        }//if(incident.HD_Parent_Tree__c != null)
                        else if(category.indexOf("Corporate IT") > -1)
                        {
                            is_EIS_TICKET = true;
                        }
            
                //END for EIS TICKET FLAG
                var finalMenu = [];//
                for(var key  in classobject.ActionManagerMenu)
                {
                    var dontshowtype = classobject.ActionManagerMenu[key].Dont_show_for_incident_type__c; 
                    if(  classobject.incident.BMCServiceDesk__Type__c == dontshowtype ){
                        continue;
                    }
                                    
                    var availableActionsOnStatus = classobject.ActionManagerMenu[key].Available_for_Status__c;
                    if(availableActionsOnStatus != null)
                    {
                        if(availableActionsOnStatus === 'All' || availableActionsOnStatus.indexOf(status)> -1)
                        {
                            
                            if(classobject.ActionManagerMenu[key].Include_Subtree__c && (classobject.ActionManagerMenu[key].Include_Subtree__c.indexOf(classobject.incident.HD_Parent_Category__c)>-1 ||  classobject.ActionManagerMenu[key].Include_Subtree__c.indexOf(classobject.incident.BMCServiceDesk__Category_ID__c )>-1))
                            {
                                if(classobject.ActionManagerMenu[key].Display_in_Action_Component__c)
                                {
                                   finalMenu.push(classobject.ActionManagerMenu[key]);
                                }
                                continue;
                                
                            }    
                            if(is_EIS_TICKET === true)//if the menu available for EIS
                            {
                                if(is_EIS_TICKET == classobject.ActionManagerMenu[key].Available_for_EIS_Team__c )
                                {
                                    finalMenu.push(classobject.ActionManagerMenu[key]);
                                }//if(is_EIS_TICKET == classobject.ActionManagerMenu[key].Available_for_EIS_Team__c )
                                
                                
                            }//if(is_EIS_TICKET == true)
                            else if(is_EIS_TICKET === false)//if Menu is not availble for EIS ie. it will avaiable for generic use
                            {
                                if(classobject.ActionManagerMenu[key].Display_in_Action_Component__c == true && classobject.ActionManagerMenu[key].Available_for_Category_Types__c == null)
                                {
                                    finalMenu.push(classobject.ActionManagerMenu[key]);
                                }else if(classobject.ActionManagerMenu[key].Display_in_Action_Component__c == false && classobject.ActionManagerMenu[key].Available_for_Category_Types__c != null)
                                {
                                    var cattype = classobject.ActionManagerMenu[key].Available_for_Category_Types__c;
                                    if(cattype.indexOf(classobject.incident.HD_IncidentGroup__c) > -1)
                                    {
                                        finalMenu.push(classobject.ActionManagerMenu[key]);
                                    }
                                }//else
                            }//else if(is_EIS_TICKET == false)
                            
                        }//if(availableActionsOnStatus === 'All' || availableActionsOnStatus.indexOf(status)> -1)                        
                    }//if(availableActionsOnStatus != null)          
                    
                }//for(var key  in classobject.ActionManagerMenu)
                
                
                //setting this variable at the end
                component.set("v.ActionMenuObjList",finalMenu);   
                
                
            }//if(state === "SUCCESS")            
            
        });        
        
        $A.enqueueAction(getActionMenuProvider);        
    },
    collapseAllAccordianHelper: function(component,activekeypress)
    {
        var menuItemsId =  component.get("v.ActionMenuObjList");
        var actionkeysarray = []; 
        for(var key in menuItemsId)
        {
            //console.log('key >> '+menuItemsId[key].Label+key);
            actionkeysarray.push(menuItemsId[key].Label+key);
        }
        //printing the array elements 
        //console.log('actionkeysarray >> '+actionkeysarray);
        actionkeysarray.splice(actionkeysarray.indexOf(activekeypress),1);
        //console.log('actionkeysarray splice >> '+actionkeysarray);
        //lets iterate and add and remove the classes
        for(var i=0;i<actionkeysarray.length; i++){
            // var cmp=component.find(actionkeysarray[i]);
            var allAccordionContent = document.getElementById(actionkeysarray[i]);
            //$A.util.swapClass(cmp, "slds-is-expanded","slds-is-collapsed"); //Invalid  in v41.0 API for Aura 
            $A.util.addClass(allAccordionContent,"slds-is-collapsed");
            $A.util.removeClass(allAccordionContent,"slds-is-expanded");
        }
    },
    
    calculateInactiveTime: function(component,event)
    {
        var startInactiveTime;
        var endInactiveTime;
        var flag = false;
        var idleTime;
        window.onblur = function() { 
            
            console.log('window blur'); 
            var startTime = component.get("v.startTime");
            if(startTime)
            {
                flag = true;
                startInactiveTime = new Date();
            }
        }
        window.onfocus = function() {
            
			if(flag)
            {
               flag = false; 
               var st = new Date(component.get("v.startTime"));
                                 
               if(startInactiveTime-new Date(component.get("v.startTime"))>0)
               {
                   endInactiveTime = new Date();
               	   idleTime =  parseInt((endInactiveTime- startInactiveTime)/1000);
               
               		component.set("v.idleTime",component.get("v.idleTime")+idleTime);
               }
            }
             
            
        }
    },
    
})