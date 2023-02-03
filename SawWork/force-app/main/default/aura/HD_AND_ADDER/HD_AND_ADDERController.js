({
    titleBuilder : function(component, event, helper) {
        var objecttype = component.get("v.objectType");
        var headerTitle = "User update";
        
        console.log('**************************************');
        console.log('Adder 1 ---->'+JSON.stringify(objecttype));
        
        var unifiedJsonString = JSON. stringify(objecttype);
        var searchHistory = unifiedJsonString.search(/"key":"History"/g);
        var searchActionHistory = unifiedJsonString.search(/"key":"Action History"/g);
        var searchApproval = unifiedJsonString.search(/"key":"Approval History"/g);
        //Now searching inner string for more detail prediction. 
        var IsCreated =  unifiedJsonString.search(/"action":"Created."/g);
        var PendingApproval = unifiedJsonString.search(/"approval_overall_Status":"Pending"/g); 
        var Transfernote = unifiedJsonString.search(/"action":"<b>Transfer Note<\/b>"/g);
        var AssignedTicket =  unifiedJsonString.search(/"action":"Changed <b>Status<\/b> from UNASSIGNED to <b>ASSIGNED<\/b>."/g);
        var TicketClosed  = unifiedJsonString.search(/"action":"Changed <b>Status<\/b> from ASSIGNED to <b>CLOSED<\/b>."/g);
        var TicketResolved  = unifiedJsonString.search(/"action":"Changed <b>Status<\/b> from ASSIGNED to <b>RESOLVED<\/b>."/g);
        var ChangedOwner = unifiedJsonString.search(/Changed <b>Owner<\/b> from/g);
        var ChangedApprover = unifiedJsonString.search(/Changed <b>Approver<\/b>/g);
        
        var ClientNote = unifiedJsonString.search(/"action":"<b>Client Note<\/b>"/g);
        var StaffNote = unifiedJsonString.search(/"action":"<b>Notes<\/b>"/g);
        
        var DefaultRouting = unifiedJsonString.search(/Changed <b>Routing<\/b>/g);
        
        var EmailSent = unifiedJsonString.search(/"action":"<b>Email Sent<\/b>"/g);
        var EmailReceived = unifiedJsonString.search(/"action":"<b>Client Note<\/b>"/g);
        
        //console.log('Has History ----> '+searchHistory+' Has Action History ----> '+searchActionHistory+' Has Approval ----> '+searchApproval+' Has been created ----> '+IsCreated+' Has pending Approval ----> '+ PendingApproval);
        //console.log('**************************************');
        
        if(searchHistory > -1 && searchActionHistory > -1 && searchApproval >  -1   )
        {
            
            //console.log('IF 1');
            if( IsCreated > -1)
            {
                headerTitle = "Ticket has been Created with Notes added along with Approval submission";
            }
            else
            {
                headerTitle = "Ticket has been Updated and Notes has been Added with Approval submission";
            }
            
        }
        else if(searchHistory > -1 && searchActionHistory > -1 && searchApproval ==  -1)
        {
            //console.log('IF 2');
            
            if( IsCreated > -1)
            {
                headerTitle = "Ticket has been Created";
            }
            else if(Transfernote > -1)
            {
                headerTitle = "Ticket has been Transferred";
            }   
            
        }
            else if(searchHistory == -1 && searchActionHistory== -1 && searchApproval >  -1)
            {
                
                //console.log('IF 3');
                
                headerTitle = "Approvals";
                if(PendingApproval > -1)
                {
                    headerTitle +=" Pending...";
                }
            }
                else if(searchHistory > -1 && searchActionHistory == -1 && searchApproval ==  -1)
                {
                    //console.log('IF 4');
                    
                    if( IsCreated > -1)
                    {
                        headerTitle = "Ticket has been Created";
                    }
                    else if(AssignedTicket > -1){
                        headerTitle = "Ticket has been Assigned";
                    }
                    else if(ChangedOwner > -1){
                            headerTitle = "Owner Has been Changed";
                    }
                    else if( ChangedApprover > -1){
                            headerTitle = "Approver Has been Changed";
                    }
                    else if(TicketClosed > -1)
                    {
                        headerTitle = "Ticket has been closed";
                    }
                    else if( TicketResolved > -1)
                    {
                        headerTitle = "Ticket has been Resolved";
                    }
                    else if(DefaultRouting > -1)
                    {
                        headerTitle = "Routing has been Changed";
                    }
                    else
                    {
                        headerTitle = "Ticket Updated";
                    }
                        
                        
                }
                    else if(searchHistory == -1 && searchActionHistory > -1 && searchApproval ==  -1)
                    {
                        //console.log('IF 5');
                        
                        if(Transfernote > -1)
                        {
                            headerTitle = "Ticket has been Transferred";
                        }else if( ClientNote > -1)
                        {
                            headerTitle = "Client Note Added";
                        }else if( StaffNote > -1)
                        {
                            headerTitle = "Internal Note Added";
                        } else if( EmailSent > -1)
                        {
                            headerTitle = "Email Has been sent";
                        }
                        else if( EmailReceived > -1)
                        {
                            headerTitle = "Email Has been Received";
                        }
                        
                        
                        
                    }
                        else if(searchHistory > 0){
                            //console.log('IF 7');
                            
                            headerTitle = "Ticket has been updated !";
                        }
        //a final component setter for output
        //
        
        component.set("v.unifiedheading",headerTitle);
    }
})