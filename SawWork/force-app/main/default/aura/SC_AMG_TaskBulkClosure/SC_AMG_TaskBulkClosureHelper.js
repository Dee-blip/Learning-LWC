({
	getColumnDefinitions: function () {
         var columns  = 	[
            {
                type: 'button-icon',
                label: 'Edit',
                typeAttributes: {
                    iconName: 'utility:edit',
                    name: 'edit', 
                    title: 'Edit',
                    variant: 'container',
                    alternativeText: 'Edit',
                    disabled: false
                },
                initialWidth: 20
            },
            {type: 'button',label: 'Close Task', initialWidth: 90, typeAttributes: { label: 'Close', name: 'close', title: 'Close task.'}},
            { label: 'Subject', fieldName: 'Subject', type: 'text'},
            { label: 'Akam Modified Date', fieldName: 'AKAM_Modified_Date__c', type: 'date' , sortable: true },
            { label: 'Type', fieldName: 'Type__c', type: 'text'  },
            { label: 'Status', fieldName: 'Status', type: 'text' , sortable: true }
            
        ];

       
        return columns;
    },
    sortData: function (component, fieldName, sortDirection) 
    {
        var data = component.get("v.taskList");
        var reverse = sortDirection !== 'asc';
        var finalData = [];
        var sortedList = [];
        
        
        
        data.sort(this.sortBy(fieldName, reverse));
        component.set("v.taskList", data);
        
        
    },
    
    sortBy: function (field, reverse, primer) 
    {
        var key = primer ?
            function(x) {return primer(x[field])} :
        function(x) {return x[field]};
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    },
    
    getMoreTask: function(component , rows)
    {
        return new Promise($A.getCallback(function(resolve, reject) 
        {
            console.log('GET MORE CALLED ');
			
            var recordLimit = component.get("v.rowsToAdd");
            
            var action = component.get('c.getAllOpenTaskRelatedToCase');
            var recordOffset = component.get("v.currentCount");
            
            action.setParams(
                {
                    "caseId" : component.get('v.recordId'),
                    "recordLimit": recordLimit,
                    "recordOffset": recordOffset
                });
            
            action.setCallback(this, function(response) 
                               {
                                   var state = response.getState();
                                   if(state === "SUCCESS")
                                   {
                                       var resultData = response.getReturnValue();
                    console.log('Result Data : ' + resultData.length);
                                       resolve(resultData);
                                       recordOffset = recordOffset+recordLimit;
                                       component.set("v.currentCount", recordOffset);  
                                       var totalCount = component.get("v.totalNumberOfRows");
                                       if(recordOffset >= totalCount)
                                       	component.set("v.taskSize", totalCount); 
                                       else
                                        component.set("v.taskSize", recordOffset); 
                                   }                
                               });
            $A.enqueueAction(action);
        }));
    },
})