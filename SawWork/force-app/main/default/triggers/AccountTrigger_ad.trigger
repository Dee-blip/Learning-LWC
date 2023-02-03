/**

    V1.0::Vikas Rajkumar 
    This code looks for records that are deleted as part of a merge 
    and then copies certain fields over into the Merged Accounts Object.
	
	History
		
		--Developer			--Date			--Description
		Ali					21/Jun/2012		CR 1753213 Remove Bus Ops exception for deleting accounts
											-> Adding code to ensure CRM Integration & Sys Admins can delete accounts and Bizz Ops can delete only on Account Merge.
		Ali KM				27/Jul/2012		CR 1521982 Credit check approval # deletion and fix related WF
											-> commenting out code that updates 'Credit check approval' as this field is no-longer used.			
*/

trigger AccountTrigger_ad on Account (after delete) {
    /*
    String accountDeleteEnabledProfileIds = GsmUtilClass.GetCustomSettingValue('AccountDelete', 'EnabledProfileId');
    String accountMergeEnabledProfileIds = GsmUtilClass.GetCustomSettingValue('AccountMerge', 'EnabledProfileId');
    //System.debug('accountDeleteEnabledProfileIds=' + accountDeleteEnabledProfileIds);
    //System.debug('accountMergeEnabledProfileIds=' + accountMergeEnabledProfileIds);
    
    for(Account acc: Trigger.old)
    {
        //System.debug('acc.MasterRecordId=' + acc.MasterRecordId);
        if(!accountDeleteEnabledProfileIds.contains(UserInfo.getProfileId()) && !(acc.MasterRecordId!=null && accountMergeEnabledProfileIds.contains(UserInfo.getProfileId())))
			acc.addError('Insufficient access. Please contact System Administrator for Account deletion.');    
        
        if(acc.MasterRecordId != null) {
            
            
            Merged_Account__c ma = new Merged_Account__c();
            
            User us;
            for(User u: [Select name,alias,email from User where id =:acc.ownerid]) {
                us = u;
            }
            
            Account master;
            for(Account m:[Select name,ownerid from Account where id=:acc.MasterRecordId]){
                master = m;
            }
            
            User parent_us;
            for(User u: [Select email from User where id =:master.ownerid]) {
                parent_us = u;
            }
            
            ma.Parent_Account__c = acc.MasterRecordId;
            ma.Merged_Into_Account_Name__c = master.Name;
            ma.name = acc.name;
            
            ma.Account_Owner__c = us.alias;
            ma.Merged_Account_Owner_Email__c = us.email;
            ma.Merged_Into_Account_Owner_Email__c = parent_us.email;
            
            ma.AKAM_Account_ID__c = acc.AKAM_Account_ID__c;
            ma.Customer_Add__c = acc.Customer_Add__c;
            ma.Customer_Drop__c = acc.Customer_Drop__c;
            ma.NPS__c = acc.CS_NPS__c;
            ma.Account_Status__c = acc.Account_Status__c; 
            
            String address = '';
            address = address + 'Primary Street : ' + acc.BillingStreet + '\n';
            address = address + 'Primary City : ' + acc.BillingCity + '\n';
            address = address + 'Primary State : ' + acc.BillingState + '\n';
            address = address + 'Primary Zip/Postal Code : ' + acc.BillingPostalCode + '\n';
            address = address + 'Primary Country : ' + acc.BillingCountry + '\n';
            ma.Primary_Address__c = address;
            ma.Target_List__c = acc.Target_Lists__c;
            ma.Vertical__c = acc.Vertical__c;
            
            String ccinfo = '';
            ccinfo = ccinfo + 'Credit Check Date : ' + acc.Credit_Check_Date__c  + '\n';
            ccinfo = ccinfo + 'Credit Check Status : ' + acc.Credit_Check_Status__c + '\n';         
            ccinfo = ccinfo + 'Credit Check Comments : ' + acc.Credit_Check_Comments__c + '\n';                     
            ccinfo = ccinfo + 'Credit Check Type : ' + acc.Credit_Check_Type__c + '\n';
            ccinfo = ccinfo + 'Credit Check Initial Review : ' + acc.Credit_Check_Initial_Review__c + '\n'; 
            ccinfo = ccinfo + 'PO Comment : ' + acc.PO_Comment__c + '\n';
            ccinfo = ccinfo + 'PO Required : ' + acc.PO_Required__c + '\n';
            ma.Credit_Check_Info__c = ccinfo;
            insert ma;
                    
        }
        
        
    } */

}