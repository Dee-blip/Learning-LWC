({
    
    handleClick: function(component, event, helper)
    {   
        var isOpen = component.get("v.isOpen");
        component.set("v.isOpen", !isOpen);
        let savebutton=component.find("savebtn");
        if(isOpen){
            savebutton.set('v.disabled',false);
        }
        else{
            savebutton.set('v.disabled',true);
        }
        
    },
    
    copy: function(component, event, helper) {
        var target = event.getSource();
        var txtVal = target.get("v.value") ;
        var url=window.location.hostname+'/'+txtVal;
        helper.copyTextHelper(component,event,url);
    },
    refreshTable:function(component, event, helper) {
        
        helper.clearpoller(component,'refresh');
        component.set("v.loaded","true");
        var refresh = component.get('c.Applyallfilters');
        $A.enqueueAction(refresh);
    },
    Applyallfilters:function(component, event, helper) {
        //component.set("v.loaded","true");
        var btn=document.getElementById("applyButton").innerHTML="Refreshing..";
        document.getElementById("applyButton").className = "slds-button slds-button_success";
        var premiumvalue=component.find("premium").get("v.value");
        var priorityvalue=component.find("priority").get("v.value");
        var caseownervalue=component.find("CaseOwner").get("v.value");
        var severityvalue = component.find("CaseSeverityCheckbox").get("v.value");
        var type =  component.find("SearchType").get("v.value");
        var searchvalue = component.find('searchInput').get('v.value');
        if(searchvalue)
        {
            helper.showAllTasksonHome(component, event, helper, premiumvalue,priorityvalue,caseownervalue,severityvalue,searchvalue,type);
        }
        else
        {	
            helper.showAllTasksonHome(component, event, helper, premiumvalue,priorityvalue,caseownervalue,severityvalue,null,type);
        }
        
    },
    
    resetallfilters:function(component, event, helper){
        helper.clearpoller(component,'reset');
        
        component.set("v.loaded","true");
        component.find("priority").set("v.value", "All");
        component.find("CaseOwner").set("v.value", "All");
        component.find("premium").set("v.value", "All");
        component.set("v.value",['1','2','3']);
        component.find("searchInput").set("v.value", "");
        helper.showAllTasksonHome(component, event, helper, 'All','All','All','[1,2,3]');
    },
    
    closeNav:function(component, event, helper) {
        document.getElementById("mySidenav").style.width = "0px";
        
    },
    
    scriptsLoaded : function(component, event, helper) {
        
        component.set("v.loaded","true");
        document.getElementById("mySidenav").style.width = "0px";        
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        var action = component.get("c.getSavedGeo");
        action.setParams({
            "userID": userId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var final=response.getReturnValue();
                component.set("v.valuegeo",final);
                
            }          
        });
        $A.enqueueAction(action);
        helper.showAllTasksonHome(component, event, helper, 'All','All','All','[1,2,3]');
        
        //Adding event listener to check if browser tab has been switched
        document.addEventListener("visibilitychange", function() {
            if (document.visibilityState === 'visible') {
                console.log('came back!');
                document.getElementById("refreshbtn").click();  
            } else {
                var pollId=component.get("v.PollID");
                clearInterval(pollId);
                console.log('Stopping poller since user left ' + pollId);
            }
        });
        
        
        //Running the polling logic
        
        var pollId = window.setInterval(
            $A.getCallback(function() { 
                console.log("trying poller from init");
                var poller = component.get('c.Applyallfilters');
                $A.enqueueAction(poller);
                
            }), 60000
        );
        component.set('v.PollID', pollId);
        
    },
    
    
    getNavRecords :function(component, event, helper) {
        document.getElementById("mySidenav").style.width = "0px";
        var reclist= component.get("v.AllTaskList");
        var filteredlist=[];
        var ID = event.target.id;
        component.set("v.NotificationType",ID);
        if(ID!='overdue' && ID!= 'PendingApproval'){
            for(var i=0;i<reclist.length;i++)
            {
                if(reclist[i].CaseColor==ID)
                {filteredlist.push(reclist[i]);}
            }
        }
        else if(ID=='overdue')
        {
            for(var i=0;i<reclist.length;i++)
            {
                if(reclist[i].TimeColor=='Red')
                {filteredlist.push(reclist[i]);}
            }  
        }
            else
            {
                for(var i=0;i<reclist.length;i++)
                {
                    if(reclist[i].EachCaseRec.Sub_Type__c=='Runbook Review')
                    {filteredlist.push(reclist[i]);}
                }  
            }
        if(filteredlist.length>0){
            component.set("v.AllTaskOverdueList",filteredlist);
            document.getElementById("mySidenav").style.width = "270px";
        }
    },
    openCaseEditModal : function(component, event, helper) {
        var ID = event.target.id;
        component.set("v.CaseRecordID",ID);
        component.set("v.EditCaseModal","true");
        
    },
    closeEditModal:function(component, event, helper) {
        component.set("v.loaded","false"); 
        component.set("v.EditCaseModal","false");
        var ref = component.get('c.Applyallfilters');
        $A.enqueueAction(ref);
        
    },
    
    saveFilters: function(component, event, helper) {
        component.set("v.loaded","true");
        var res=component.find("CaseGeoCheckbox").get("v.value");
        
        if(res=='')
        {
            //helper.showToastMessage(component, event, helper,'An Empty Table?','You need to select atleast 1 geography','error','dismissible');   
            component.set("v.loaded","false"); 
        }
        else{
            helper.clearpoller(component,'save geo');
            var selectedGeo=res;
            var userId = $A.get("$SObjectType.CurrentUser.Id");
            var action = component.get("c.saveSelectedFilters");
            action.setParams({
                "userID": userId,
                "SelectedGeoFromUser":selectedGeo                
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    $A.enqueueAction(component.get('c.Applyallfilters'));
                }
                
            });
            $A.enqueueAction(action); 
        }
    },
    
    CloseModal:function(component, event, helper) {
        component.set("v.isCaseReleatedTasks","false");
        component.set("v.EditCaseModal","false");
        
    },
    
    handleSubmit:function(component, event, helper) {
        component.set("v.loaded","true");
    },
    
    handleOnError:function(component, event, helper) {
        component.set("v.loaded","false");
    },
    
    
    openNewTab:function(component, event, helper) {
        
        var ID = event.target.id; 
        var urlpara = '/'+ID;
        window.open(urlpara,'_blank');
    },
    openClassicTab:function(component, event, helper)
    {
        var ID = event.target.id; 
        var classicurlpara='/console#%2F'+ID;
        window.open(classicurlpara,'_blank');
    },
    renderPage: function(component, event, helper) {
        helper.renderPage(component);
    },
    openNewCase : function(component, event, helper) {
        
        window.open('/one/one.app#/sObject/Case/new','_blank');          
    },
    
})