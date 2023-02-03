({
    unifiedAction : function(component, event, helper) {
        var forPrintFlag = component.get('v.forPrint');
        if(forPrintFlag==true){component.set('v.record_range',1000);}
        var firstDiv = component.find('incHistoryDiv');
        var secondDiv = component.find('unifiedcontent');
        if(forPrintFlag==false){
            $A.util.addClass(firstDiv,'slds-card timeline');
            $A.util.addClass(secondDiv,'slds-border--bottom slds-border--top');
            }
        
        helper.unifiedHistRetriveNestedMapHelper(component,event,helper);
        
    },
    showMoreHist : function(component,event,helper){
        var record_range = component.get('v.record_range'); 
        var showmoreDom = component.find("showMore");
        record_range = record_range+5;
        var unifiedHistoryDateListSize = component.get('v.unifiedHistoryDateListSize');
        component.set('v.record_range',record_range);
        if(record_range >= unifiedHistoryDateListSize)
        {
            $A.util.addClass(showmoreDom,"slds-hide");
        }
        console.log('--->>>'+record_range+'-->>>'+unifiedHistoryDateListSize);
    },
    //below is code for Lightning:Spinner
    toggleSpinner: function (cmp, event) {
        var spinner = cmp.find("mySpinner");
        $A.util.toggleClass(spinner, "slds-hide");
    },
    toggleCollapse : function(cmp,event,helper){
        helper.toggleCollapseHelper(cmp,event);
    },
    refreshHistoryView: function(component,event,helper){
        //
        var RecordId = component.get("v.recordId");
        component.set("v.lastrefreshed","");
        var refreshedtimefor =   "date"+RecordId;
        //get the time when refreshed is clicked and store it in local storage
        var refreshTime = new Date();
        var refreshTimeHour =  refreshTime.getHours();
        var refreshTimeMinute =  refreshTime.getMinutes();
        var refreshTimeSeconds =  refreshTime.getSeconds();
        console.log(">>>>>> Hours: "+refreshTime.getHours()+" Minutes: "+refreshTime.getMinutes()+" Seconds:"+refreshTime.getSeconds());  
        window.localStorage.setItem(refreshedtimefor, refreshTime);
        
        //once stored get the local stored time  
        var currentincidentLastRefreshed = window.localStorage.getItem(refreshedtimefor);  
        var countrun = 1;
        var scheduler = setInterval(
            function(){
                var currentDate = new Date();
                var diff = currentDate.getTime() - refreshTime.getTime();
                
                var hours = Math.floor(diff / (1000 * 60 * 60));
                diff -= hours * (1000 * 60 * 60);
                
                var mins = Math.floor(diff / (1000 * 60));
                diff -= mins * (1000 * 60);
                
                console.log( hours + " hours : " + mins + " minutes : " );
                var message = "Last Refreshed "+hours+" Hour "+mins+" Min ago";
                if(hours > 0)
                {
                    message = "Last Refreshed "+hours+" Hour "+mins+" Min ago";
                }
                else
                {
                    message = "Last Refreshed "+mins+" Min ago";
                }
                component.set("v.lastrefreshed",message);
                console.log("Hello Running>> "+countrun+" times for "+currentincidentLastRefreshed); 
                if( countrun > 30)
                {
                    clearInterval(scheduler);
                }
                countrun++;
            }, 60000);  
        
        //    
        helper.unifiedHistRetriveNestedMapHelper(component,event,helper);
    }, 
    expandAll : function(component, event, helper) {
        var url = '/c/HD_ExpandedIncidentHistoryApp.app#'+component.get("v.recordId")+'?rowCount=5000';
        sessionStorage.setItem("sent", window.self); 
        window.open(url,'','top=100,left=100,height=750,width=1100');
    },
    openFile: function(component,event,helper)
    {   
        var target = event.target.id;
        helper.openSingleFileHelper(component,event,target);
        console.log(target);
     /*
    var createRecordEvent = $A.get("e.force:createRecord");
    createRecordEvent.setParams({
        "entityApiName": "BMCServiceDesk__Incident__c"
    });
    createRecordEvent.fire();
        */

    }


})