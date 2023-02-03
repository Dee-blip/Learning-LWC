@isTest
public class SC_Community_Registration_bi_bu_test {
    static testmethod void createCommunityRegist(){
        SC_Community_Registration__c newReg = new SC_Community_Registration__c();
        newReg.First_Name__c = 'comUsereeeee';
        newReg.Last_Name__c = 'comhsdjheee';
        newReg.Email__c = 'comUsereeeee@comhsdjheee.com';
        newReg.LinkedIn_URL__c = 'https://linkedIn.com/comUsereeeee';
        insert newReg;
        test.startTest();
        	SC_Community_Registration__c updateReg = new SC_Community_Registration__c();
            updateReg.id = newReg.id;
        	updateReg.IsApproved__c = true;
        	update updateReg;
        test.stopTest();  
    }
}