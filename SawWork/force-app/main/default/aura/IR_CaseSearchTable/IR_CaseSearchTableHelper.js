({
	getData : function(component, event, helper) {
        component.set('v.columns', [
            {label: 'Case Number', fieldName: 'CaseNumberUrl', type: 'url',  typeAttributes:  {label: { fieldName: 'CaseNumber' }, target: '_self'}, sortable: true, fixedWidth : 90},
            {label: 'Account Name', fieldName: 'Account.Name', type: 'text', sortable: true},
            {label: 'Parent Account', fieldName: 'IR_Original_Contract_Id__r.Parent_Account_Name__r.Name', type: 'text', sortable: true},
            {label: 'Original Contract', fieldName: 'IR_Original_Contract_Id__r.Name', type: 'text', sortable: true},
            {label: 'Reporting Region', fieldName: 'IR_Reporting_Region__c', type: 'text', sortable: true},
            {label: 'Invoice Number', fieldName: 'IR_Invoice_Number__c', type: 'text', sortable: true},
            {label: 'Invoice Date', fieldName: 'IR_Invoice_Date__c', type: 'date', sortable: true},
            {label: 'Description', fieldName: 'Description', type: 'text', fixedWidth : 300},
            {label: 'Owner', fieldName: 'Owner.name', type: 'text', sortable: true},
            {label: 'Status', fieldName: 'Status', type: 'text', sortable: true},
            {label: 'Manual Contract', fieldName: 'IR_Manual_Contract__c', type: 'text', sortable: true}
        ]);

        var action = component.get("c.fetchCases"); 
        var pageSize = component.get("v.pageSize").toString();
        var pageNumber = component.get("v.pageNumber").toString();
        var whereClause = (JSON.stringify(component.get('v.filter')) != "{}" && component.get('v.applyFilterClicked') == true) ?  helper.setWhereClause(component, helper) : '';
        action.setParams({
            'pageSize' : pageSize,
            'pageNumber' : pageNumber,
            'whereClause' : whereClause
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var resultData = response.getReturnValue();
                if(resultData.length < pageSize){
                    component.set("v.isLastPage", true);
                } else{
                    component.set("v.isLastPage", false);
                }
                resultData.forEach(function(record){
                  record.CaseNumberUrl = '/'+ record.Id ;
                })
                component.set("v.dataSize", resultData.length);
                component.set("v.data", resultData);
                //component.set("v.applyFilterClicked", false);
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error! Please contact administrator.");
                }
            }
						helper.showToast(component, event, helper, 'error', 'Something went wrong!  Please contact administrator.');
        });
        $A.enqueueAction(action);
	},

		showToast : function(component, event, helper, type, message) {
				var toastEvent = $A.get("e.force:showToast");
				toastEvent.setParams({
						title : (type == 'error' ? 'Error Message' : 'Success'),
						message: message,
						duration: '5000',
						key: 'info_alt',
						type: type,
						mode: 'pester'
				});
				toastEvent.fire();
		},

    sortData : function(component,fieldName,sortDirection){
        var data = component.get("v.data");
        //function to return the value stored in the field
        var key = function(a) { return a[fieldName]; }
        var reverse = sortDirection == 'asc' ? 1: -1;


        data.sort(function(a,b){
            var a = key(a) ? key(a).toLowerCase() : '';//To handle null values , uppercase records during sorting
            var b = key(b) ? key(b).toLowerCase() : '';
            return reverse * ((a>b) - (b>a));
        });
        component.set("v.data",data);
    },

    setDefaults : function(component){
        component.set('v.pageNumber', 1);
        component.set('v.pageSize', 25);
        component.set('v.isLastPage', false);
    },

    setWhereClause: function(component, helper){
        var whereClause = '';
        for(var key in component.get('v.filter')){
            var val = component.get('v.filter')[key];
            if(val == null ){
	            continue;
            }
            if(typeof val == 'string' && val != ""){
                whereClause += helper.buildCondition(key, val);
            } else if(typeof val == "object" && Object.values(val).length > 0){
                var key_1 = Object.keys(val)[0];
                var val_1 = Object.values(val)[0];
                if(typeof val_1 == 'string' && val_1 != "" ){
                   whereClause += helper.buildCondition(key+'.'+key_1, val_1);
                }else if(typeof val_1 == 'object' && Object.values(val_1).length > 0){
                    var key_2 = Object.keys(val_1)[0];
                    var val_2 = Object.values(val_1)[0];
                    if(typeof val_2 == 'string' && val_2 != ""){
                       whereClause += helper.buildCondition(key +'.'+key_1+'.'+key_2, val_2);
                    }
                }
            }
        }
        return whereClause;
    },

    buildCondition : function(key, val){
        var whereClause='';
        if(key == 'IR_Invoice_Date__c'){
            whereClause += ' and ' + key + " = "+ val;
        }
		else if(val.includes('*')){
            whereClause += ' and ' + key + " like '" + val.replace(/\u{2A}/ug, "%") +"'"; //replacing * with %
        }else{
            whereClause += ' and ' + key + " = '"+ val+"'";
        }
        return whereClause;
    }
})