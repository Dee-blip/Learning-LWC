({    
    showAllTasksonHome : function(component, event, helper,UIpremiumvalue,UIpriorityvalue, UICaseOwnervalue,UISeverityvalue,searchboxvalue,type) 
    {
        var action = component.get('c.getSocHomeTask');
        //action.setBackground();
        action.setParams({
            "PriorityFilter":UIpriorityvalue ,
            "CaseOwnerFilter":UICaseOwnervalue,
            "premiumFilter": UIpremiumvalue,
            "SeverityFilter":UISeverityvalue,
            "searchvalue":searchboxvalue,
            "searchtype":type
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var t0 = performance.now();
                var orginallist=response.getReturnValue();
                var btn=document.getElementById("applyButton").innerHTML="Apply";
                document.getElementById("applyButton").className = "slds-button slds-button_brand";
                component.set('v.AllTaskList', orginallist); 
                //Handling Pagination logic
                component.set("v.maxPage", Math.ceil(orginallist.length/100));                
                component.set('v.AllTaskListCount',orginallist.length); 
                var pageNumber = component.get("v.pageNumber");
                if(pageNumber>Math.ceil(orginallist.length/100))
                {
                    pageNumber=1; component.set("v.pageNumber",pageNumber);
                }
                var pageRecords = orginallist.slice((pageNumber-1)*100, pageNumber*100);
                component.set("v.currentList", pageRecords);
                var t1 = performance.now();
                console.log("------------>Homeload took " + (t1 - t0) + " milliseconds to execute.")
                component.set("v.loaded","false");
                
                var t0 = performance.now();
                
                
                var OverdueCount=0,PurpleTasksCount=0,YellowTasksCount=0,WhiteTasksCount=0,PendingApprovalCount=0;
                //Calculate the summary dashboard count
                
                for(var i=0;i<orginallist.length;i++)
                {
                    if(orginallist[i].TimeColor=='Red')
                    {OverdueCount++;}
                    else if(orginallist[i].CaseColor=='#f78bf7')
                    {PurpleTasksCount++;}
                        else if(orginallist[i].CaseColor=='#ffd400')
                        {YellowTasksCount++;}
                            else if(orginallist[i].CaseColor=='white' && orginallist[i].EachCaseRec.Sub_Type__c!='Runbook Review')
                            {WhiteTasksCount++;}
                                else if(orginallist[i].CaseColor=='white' && orginallist[i].EachCaseRec.Sub_Type__c=='Runbook Review')
                                {PendingApprovalCount++;}
                }
                component.set('v.OverdueCount', OverdueCount); 
                component.set('v.PurpleTasksCount', PurpleTasksCount); 
                component.set('v.YellowTasksCount', YellowTasksCount); 
                component.set('v.WhiteTasksCount', WhiteTasksCount); 
                component.set('v.ApprovalCount',PendingApprovalCount);
                var t1 = performance.now();
                console.log("------------> minidash took " + (t1 - t0) + " milliseconds to execute.")
                
                
            }
        });
        $A.enqueueAction(action); 
    },
    
    renderPage: function(component) {
        var t0 = performance.now();
        var pageNumber = component.get("v.pageNumber");
        var allrecords=component.get("v.AllTaskList");
        var pageRecords = allrecords.slice((pageNumber-1)*100, pageNumber*100);
        component.set("v.currentList", pageRecords);
        var t1= performance.now();
        console.log("------------> Page change took " + (t1 - t0) + " milliseconds to execute.")
        
    },
    copyTextHelper : function(component,event,text) {
        var hiddenInput = document.createElement("input");
        hiddenInput.setAttribute("value", text);
        document.body.appendChild(hiddenInput);
        hiddenInput.select();
        document.execCommand("copy");
        document.body.removeChild(hiddenInput); 
        /*var orignalLabel = event.getSource().get("v.label");
        event.getSource().set("v.label" , 'copied');
        event.getSource().set("v.iconName",'utility:check');*/
    },
    
    clearpoller : function(component,where)
    {
        var pollId=component.get("v.PollID");
        clearInterval(pollId);        
        var pollId = window.setInterval(
            $A.getCallback(function() { 
                    console.log("running poller from "+where);
                    var poller = component.get('c.Applyallfilters');
                    $A.enqueueAction(poller);
             
            }), 60000
        );
        component.set('v.PollID', pollId);
        console.log("New poll ID : "+pollId);
    }
    
    
})