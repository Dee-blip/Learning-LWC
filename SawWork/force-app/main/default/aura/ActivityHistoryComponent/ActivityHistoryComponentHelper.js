// SFDC-2407 Added by Mayank Bansal 13th March 2018
({
    helperMethod : function() {
    }, setActivityTableColumns : function(component) {
        component.set('v.activityColumns', [
            {
                label: 'Subject',
                fieldName: 'Id',
                sortable: 'true',
                type: 'url',
                typeAttributes: {
                  label: {
                    fieldName: 'Subject'
                  }
                }
            },
            {
                label: 'Related To',
                fieldName: 'What',
                sortable: 'true',
                type: 'text',
            },
            {
                label: 'Task Type',
                fieldName: 'Type__c',
                sortable: 'true',
                type: 'text',
            },
            {
                label: 'Status',
                fieldName: 'Status',
                sortable: 'true',
                type: 'text',
            },
            {
                label: 'Priority',
                fieldName: 'Priority',
                sortable: 'true',
                type: 'text',
            },
            {
                label: 'Due Date',
                fieldName: 'ActivityDate',
                sortable: 'true',
                type: 'Date',
            },
            {
                label: 'Assigned To',
                fieldName: 'Owner',
                sortable: 'false',
                type: 'text',
            },
            {
                label: 'Last Modified Date/Time',
                fieldName: 'AKAM_Modified_Date__c',
                sortable: 'false',
                type: 'Date',
            },
        ]);
    },
     sortData: function(component, fieldName, sortDirection) {
        var data = component.get("v.activityData");
        var reverse = sortDirection !== 'asc';
        data.sort(this.sortBy(fieldName, reverse));
        component.set("v.activityData", data);
    },
      sortBy: function(field, reverse, primer) {
        var key = primer ?
          function(x) {
            return primer(x[field])
          } :
          function(x) {
            return x[field]
          };
        reverse = !reverse ? 1 : -1;
        return function(a, b) {
          return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    },
      setActivityTableData : function(component) {
        var action = component.get("c.getTaskRecords");
        component.set("v.activityData", null);
        action.setParam('akam_Lead_ID',component.get("v.recordId"));
        var userLocaleCountry = component.get("v.userLocaleCountry");
        var userLocaleLang = component.get("v.userLocaleLang");
        var locale = "en-US";
        if((userLocaleCountry != null && userLocaleCountry.length == 2) && (userLocaleLang != null && userLocaleLang.length == 2))
        locale = userLocaleLang +"-"+userLocaleCountry;
        console.log(locale);
        var tasksList = [];
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == 'SUCCESS') {
                var tasks = JSON.parse(response.getReturnValue());
                for (var index in tasks) {
                    if (index > Number(tasks.rowsToDisplay) - 1) {
                        break;
                    }
                   
                    var taskObj = {
                        Id: '/' + tasks[index].Id, 
                        Subject: tasks[index].Subject,
                        What: tasks[index].What.Name,
                        Status: tasks[index].Status,
                        Priority: tasks[index].Priority,
                        Type__c: tasks[index].Type__c,
                        ActivityDate: new Date(tasks[index].ActivityDate).toLocaleDateString(locale),
                        Owner: tasks[index].Owner.Name,
                        AKAM_Modified_Date__c: new Date(tasks[index].AKAM_Modified_Date__c).toLocaleString(locale)
                    }

                    tasksList.push(taskObj);
                };
                component.set("v.activityData", tasksList);
            }
        });
        $A.enqueueAction(action);
        
    }
})