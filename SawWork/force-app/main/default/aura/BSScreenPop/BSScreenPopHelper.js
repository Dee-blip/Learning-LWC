({
	
   /*  navigateToDetail: function(recordId){
        var navEvt = $A.get("e.force:navigateToSObject");
        //navEvt.setParams({
        //    "recordId": recordId,
        //    "slideDevName": "detail"
        //});
        //navEvt.fire();
        //
        sforce.one.navigateToSObject(recordId,"detail"); 
    }
    
    */
    
    
    showToastMessage : function(title,message,messagetemplate,type) 
    {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : title,
            message: message,
            messageTemplate: messagetemplate,
            duration:'10000',
            key: 'info_alt',
            type: type,
            mode: 'dismissible'
        });
        toastEvent.fire();                

	},
    
    navigateToDetail: function(recordId){
        //var navEvt = $A.get("e.force:navigateToSObject");
        //navEvt.setParams({
        //    "recordId": recordId,
        //    "slideDevName": "detail"
        //});
        //navEvt.fire();
        console.log('attempting to navigate to '+recordId);
           var myEvent = $A.get("e.c:SendDataToVFPage");
            myEvent.setParams({
                operationName: 'navigate',
                recordId: recordId
            });
            myEvent.fire();
    }
    
    
})