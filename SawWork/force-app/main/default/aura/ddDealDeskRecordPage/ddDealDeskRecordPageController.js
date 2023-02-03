({
    onDealLoad : function(cmp, ev, hl) {
        console.log('comp rec', cmp.get('v.recordId'));
        
        var record = cmp.get('v.record');
        var isEditable = false;
        var errorMsg;
        var userId = $A.get("$SObjectType.CurrentUser.Id");

        if(record.GSS_Product__r.Name === 'Other') {
            errorMsg = '"Other" product deals are non-editable';
        }
        else if(record.Approval_Stage__c === 'Closed') {
            errorMsg = 'Deal is Closed, not editable';
        }
        else if(record.Approval_Stage__c === 'DDA' ) {
            if(userId === record.Requestor__c ) {
              isEditable = true;
            } else{ 
                errorMsg = 'Cannot edit deals created by other users';
            }
        }
        else    {
            errorMsg = 'Deal is not editable as it is in ' + record.Approval_Stage__c + ' stage. Only Deals in DDA stage are editable.';
        }
        cmp.set('v.isEditable', isEditable);
        cmp.set('v.errorMsg', errorMsg);        
    }
})