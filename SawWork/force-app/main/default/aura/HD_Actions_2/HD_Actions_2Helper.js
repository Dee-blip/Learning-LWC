({
    collapseAll : function (component,buttonKey){
        /*closeTicket
 		sendEmail
		resolveTicket
        transferTicket
        assignTicket
        */
        var actionKeys = ["closeTicket",
                          "sendEmail",
                          "resolveTicket",
                          "transferTicket",
                          "assignTicket",
                          "cloneTicket",
                          "attachFile",
                          "linkItems",
                          "linkIncidents",
                          "changePriority",
                          "changeCategory",
                          "submitApproval",
                          "holdTicket",
                          "clientNote",
                          "reopenTicket",
                          "updateCCtxt",
                          "printTicket",
                          "emailConfig"
                         ];
        
        actionKeys.splice(actionKeys.indexOf(buttonKey),1);
        
        for(let i=0;i<actionKeys.length; i++){
            // console.log("insied loope" + actionKeys[i]);
            var cmp=component.find(actionKeys[i]);
            // console.log(cmp);
            
            $A.util.swapClass(cmp, "slds-is-expanded","slds-is-collapsed"); 
        }
        
        //$A.util.swapClass(cmp, "slds-is-collapsed","slds-is-expanded"); 
        
        
    },
    actionManagerHelper :  function(component,event,helper){
        
        var getActionMenuProvider = component.get("c.getClientDetailLightningMenu");
        getActionMenuProvider.setCallback(this,function(resp){
            var state = resp.getState();
            if(state === "SUCCESS")
            {
                
                //lets get the current incident detail
                var incident = component.get("v.incident");
                //console.log('incident-->' +JSON.stringify(incident));
                
                //
                var status = incident.BMCServiceDesk__Status_ID__c;
                //for EIS TICKET FLAG
                var is_EIS_TICKET = false;
                var category = incident.BMCServiceDesk__Category_ID__c;
                if(incident.HD_Parent_Tree__c != null)
                {
                    var parent_tree = incident.HD_Parent_Tree__c;
                    //if( (category.indexOf("Corporate IT") > -1) || (parent_tree.indexOf("Corporate IT") > -1))
                    if( (category.indexOf("Corporate IT") > -1) || (parent_tree.indexOf("Corporate IT") > -1))
                    {
                        
                        is_EIS_TICKET = true;
                    }
                    
                }//if(incident.HD_Parent_Tree__c != null)
                //else if(category.indexOf("Corporate IT") > -1)
                else if(category.indexOf("Corporate IT") > -1)
                {
                    is_EIS_TICKET = true;
                }
                //END for EIS TICKET FLAG
                
                
                var respo = resp.getReturnValue();
                //console.log('---> '+JSON.stringify(respo));
                for(let key in respo)
                {
                    //new code for Hidding
                    //adding hide by default
                    //console.log('---> default hide has been initiated !');
                    $A.util.addClass(component.find(respo[key].Label),"hide-menu"); 
                    
                    var dontshowtype = respo[key].Dont_show_for_incident_type__c;
                    
                    if(  incident.BMCServiceDesk__Type__c == respo[key].Dont_show_for_incident_type__c ){
                        continue;
                    }
                    
                    // console.log('Available for--> '+respo[key].Available_for_Status__c);
                    var availableActionsOnStatus = respo[key].Available_for_Status__c;
                    if(availableActionsOnStatus != null)
                    {
                        if(availableActionsOnStatus === 'All' || availableActionsOnStatus.indexOf(status)> -1)
                        {
                            //console.log('Available for --> '+respo[key].Label);
                            
                            
                            //console.log('---> '+respo[key].Display_in_Action_Component__c);
                            var currentMenu = component.find(respo[key].Label);
                            //console.log('---> '+currentMenu);
                            if(currentMenu != null)
                            {
                                //Final check with conditions for EIS Ticket
                                if(is_EIS_TICKET == true)
                                {
                                    if(respo[key].Available_for_EIS_Team__c == true)
                                    {
                                        //console.log('Class ---> Removed ');
                                        //This Add the Menu in action Component
                                        $A.util.removeClass(currentMenu,"hide-menu");
                                    }
                                    
                                }else if(is_EIS_TICKET == false)
                                {
                                    if(respo[key].Display_in_Action_Component__c == true && respo[key].Available_for_Category_Types__c == null)
                                    {
                                        //This Add the Menu in action Component
                                        $A.util.removeClass(currentMenu,"hide-menu");
                                    }//if
                                    else if(respo[key].Display_in_Action_Component__c == false && respo[key].Available_for_Category_Types__c != null)
                                    {
                                        var cattype = respo[key].Available_for_Category_Types__c;
                                        if(cattype.indexOf(incident.HD_IncidentGroup__c) > -1)
                                        {
                                            $A.util.removeClass(currentMenu,"hide-menu");
                                        }
                                        
                                    }//else
                                    
                                }//else
                                
                                
                            }//if(currentMenu != null)
                            
                        }//if(availableActionsOnStatus === 'All' || availableActionsOnStatus.indexOf(status)> -1)
                        
                    }//if(availableActionsOnStatus != null)
                    
                }//for
                
            }//if(state === "SUCCESS")
        });
        $A.enqueueAction(getActionMenuProvider);
        
        
    },
    getIncidentDetailhelper : function(component,event,helper){
        var RecordId = component.get("v.recordId");
        var targetObjectIdvalue = "a5UR0000000EAtEMAW";
        if(RecordId != null)
        {
            targetObjectIdvalue = RecordId;
        }
        var incident = component.get("c.getIncident");
        incident.setParams({
            id : targetObjectIdvalue
        });
        incident.setCallback(this,function(resp){
            var state = resp.getState();
            if(state === "SUCCESS")
            {
                //console.log('Incident --->'+JSON.stringify(resp.getReturnValue()) );
                component.set("v.incident",resp.getReturnValue());
            }//if(state === "SUCCESS")
            if( state === "ERROR")
            {
                console.log('EXP--[]'+resp.getReturnValue());
            }
            
        });
        $A.enqueueAction(incident);
    },
    
    getisAccessibleHelper : function(component,event,helper)
    {
        var RecordId = component.get('v.recordId');
        var isAccessible = component.get('c.isAccessibleRecord');
        var MyActionmsg = 'Actions are <b style="color:#c23934">disabled</b> as you/your team is not a owner of this ticket. Ticket owner should assign ticket to you or transfer to your group for actions to be enabled.';
        //OLD mSG: 'Selected actions are <b style="color:#c23934">Disabled</b>, since you do not have required <b>Edit Access</b> on ticket. Please contact your System Administrator for more details.';
        isAccessible.setParams({
            recordID: RecordId
        });
        isAccessible.setCallback(this,function(resp){
            var state = resp.getState();
            if(state === 'SUCCESS')
            {
                var  isaccessible = resp.getReturnValue();
                console.log('hasAcceess-->>>'+isaccessible );
                component.set('v.isaccessible',isaccessible);
                if( isaccessible === true )
                {
                    component.set('v.disableAccess',false);
                    component.set('v.ApprovaldisableAccess',false);
                }else if(isaccessible === false )
                {
                    component.set('v.disableAccess',true);
                    component.set('v.ApprovaldisableAccess',true);
                    component.set('v.MyActionMsg',MyActionmsg);
                    console.log('---> '+component.get('v.disableAccess'));

                }
                
            //enabling Approval menu
            this.getApprovalRecordStatus(component,event,helper);      
            }////if(state === "SUCCESS")
        });//
        $A.enqueueAction(isAccessible);
    },//
    
    getApprovalRecordStatus : function(component,event,helper)
    {
        var TargetId = component.get('v.recordId');
        var approvalRecordStatus = component.get('c.approvalRecordStatus');
        approvalRecordStatus.setParams({
            TargetRecordID: TargetId
        });
        approvalRecordStatus.setCallback(this,function(resp){
            var state = resp.getState();
            var MyActionmsgApproval = "Select an action from the list below, available options change as the ticket moves through it's life-cycle.";
            if(state === 'SUCCESS')
            {
                var  approvalRecordStatus = resp.getReturnValue();
                console.log('approval status-->>>'+approvalRecordStatus );   
                if(approvalRecordStatus === true )
                {
                    MyActionmsgApproval = 'Actions are <b style="color:#c23934">disabled</b> since the ticket is under <b>Approval</b>.';
                    
                    component.set('v.disableAccess',true);
                    component.set('v.ApprovaldisableAccess',false);
                    //case: where the record is submitted for approval and is not accessible
                    if(  component.get('v.isaccessible') === false )
                    {
                       component.set('v.ApprovaldisableAccess',true); 
                    }
                    
                }
                component.set('v.MyActionMsg',MyActionmsgApproval);
                
            }////if(state === "SUCCESS")
            
            
        });//
        $A.enqueueAction(approvalRecordStatus);
        
    }//
    
    
})