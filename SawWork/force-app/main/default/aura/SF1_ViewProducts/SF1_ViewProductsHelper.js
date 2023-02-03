({
	closeModal : function(cmp){
        //Hide the task modal once editing is done
        //cmp.find("productsViewModal").close();
        cmp.destroy();


        
        // //Reset the temporary variables
        // cmp.set("v.rowIndex",-1);
        
        // //Reset the selectedTask
        // cmp.set("v.selectedTask",{'sobjectType':'ldt_Task__c','Stage__c':'','Name':'','Project__c':'','Start_Date__c':'','Description__c':'','Due_Date__c':''});
    }
})