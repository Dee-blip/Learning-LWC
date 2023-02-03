({
    unifiedHistRetriveNestedMapHelper : function(component,event,helper)
    {   
        var RecordId = component.get("v.recordId");
        var recordCount = component.get("v.rowCount");
        var targetObjectIdvalue = "a5U0R0000008R36UAE";
        //console.log('-->'+RecordId);
         console.log('-->'+recordCount);
        if(RecordId != null)
        {
            targetObjectIdvalue = RecordId;
        }
        
        var unifiedHistNested = component.get("c.getGroupedUnifiedHistoryByDate");
        unifiedHistNested.setParams({
            targetObjectIdvalue : targetObjectIdvalue,
            rowCount : recordCount
        });
        unifiedHistNested.setCallback(this,function(resp){
            var state = resp.getState();
            //console.log('STATE--->'+state);
            if( state === "SUCCESS")
            {  
                var respo = resp.getReturnValue();
                console.log("-->"+JSON.stringify(respo));
                var Datekeyset = [];
                
                for(let key in respo)
                {   
                    //Datekeyset.push({"key":key,"data":respo[key]});
                    //console.log('-->'+respo[key]);
                    var typekeyset = [];
                    
                    for(let key1 in respo[key])
                    {
                        // console.log(key+'-->'+key1+'-->'+respo[key][key1].length);
                        if(!respo[key][key1].length<=0)
                        {
                            typekeyset.push({"key":key1,"data":respo[key][key1]});
                        }   
                    }
                    Datekeyset.push({"key":key,"data":typekeyset});
                }
                
                //console.log('Coming History Data >>>'+JSON.stringify(Datekeyset));
                component.set("v.unifiedHistoryDateList",Datekeyset.sort(
                    function(a, b){
                        var keyA = new Date(a.key),
                            keyB = new Date(b.key);
                        // Compare the 2 dates
                        if(keyA > keyB) return -1;
                        if(keyA < keyB) return 1;
                        return 0;
                    }));
                component.set("v.unifiedHistoryObjTypeList",typekeyset);
                component.set("v.unifiedHistoryDateListSize",Datekeyset.length);
                //component.set("v.UnifiedMap",respo);
                //console.log('Stringify -->'+JSON.stringify(Datekeyset));
                //JSON.stringify(JSON.parse(respo))
                component.set("v.placeholder",false);
                //this.showToast(component, event, helper);
             }//SUCCESS
            else if(state === "RUNNING")
            {
                component.set("v.placeholder",true);
            }
            else if(state === "ERROR")
            {
                component.set("v.placeholder",false);
                var errors = resp.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
            //running the hide Helper
           
        });
        $A.enqueueAction(unifiedHistNested);
        
        
    },
    toggleCollapseHelper : function(component,event){
        var getEventSource = event.currentTarget;
        console.log("1 --> "+getEventSource);
        var dataEle = getEventSource.dataset.record;
        console.log("2 --> "+dataEle);
        console.log("v.selectedItem", "Component at index "+dataEle+" has value "+getEventSource.value);
        var getTarget = document.getElementById("collapsable"+dataEle);
        $A.util.toggleClass(getTarget,"slds-is-collapsed");
        console.log("3 -->"+getTarget);
    },
    showToast : function(component, event, helper) {
        try{
            var toastEvent = $A.get("e.force:showToast");
            if(toastEvent != "undefined")
            {
                //console.debug("-->"+toastEvent);
                toastEvent.setParams({
                    "title": "Message",
                    "message": "Application Loaded Successfully !"
                });
                
            }//if
        }        
        catch(e){
            console.log("[ERROR:] "+e);
        }
        
        toastEvent.fire();
    },
    
    openSingleFileHelper: function(component, event, ContentID) {
    $A.get('e.lightning:openFiles').fire({
        recordIds: [ContentID,ContentID],
        selectedRecordId: component.get("v.currentContentDocumentId")
    });
     },
    
    
})