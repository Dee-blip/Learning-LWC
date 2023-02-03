/*=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE             DEVELOPER       JIRA        DESCRIPTION                               

|  ===========      =========       =======     =========== 

|  29-APR-2019      Aditya Sonam    ESESP-1818  This support class is used to create Autogen Cases for Premium 3.0

Test Class:   SC_Autogen_AllUseCase_TC                                                                                        
+=====================================================================================================*/
public class SC_Autogen_Premium_Three_Support {
    
    SC_Utility__mdt customMdtVal = [Select value__c from SC_Utility__mdt where DeveloperName = 'Autogen_Premium_3_0_Case_Interval' limit 1];
    dateTime thirtyThreeDaysBehind = system.Today().addDays(-Integer.valueOf(customMdtVal.value__c));
    dateTime thirtyThreeDaysAhead = system.Today().addDays(Integer.valueOf(customMdtVal.value__c));
    List<Autogen_Contract_Header_Detail__c> achdLineList = new List<Autogen_Contract_Header_Detail__c>();
    List<Autogen_Contract_Header_Detail__c> achdLineCLIOnboardList = new List<Autogen_Contract_Header_Detail__c>();
    Map<Id,List<Autogen_Contract_Header_Detail__c>> contractACHDMap = new Map<Id,List<Autogen_Contract_Header_Detail__c>>();
    Map<Id,String> mContractIdAccountName = new Map<Id,String>();
    Map<String, Set<String>> mContractProduct = new Map<String, Set<String>>();
    List<Case> childCaseList = new List<Case>();

    
    //Main Method
    public void main_Premium_Method(List<Autogen_Contract_Header_Detail__c> allReturnContractLines){
        
        for(Autogen_Contract_Header_Detail__c eachLine :allReturnContractLines){
            //Checking if CLI Created Date equals to last 48 hours. 
            if(eachLine.Parent_Contract_Detail__r.Createddate >= system.now()-2 ){
                
                //checking if CLI Effective Start Date is between (TODAY and last 33 calendar days).
                if(eachLine.Effective_Start_Date__c <= system.Today() && eachLine.Effective_Start_Date__c >= thirtyThreeDaysBehind){
                    createMapOfContractAndACHD(eachLine);
                    achdLineCLIOnboardList.add(eachLine);
                }
            }
            
            //CLI Effective Start is between (TOMORROW and next 33 calendar days)
            if(eachLine.Effective_Start_Date__c >= system.Today()+1 && eachLine.Effective_Start_Date__c <= thirtyThreeDaysAhead){
                createMapOfContractAndACHD(eachLine);
                achdLineCLIOnboardList.add(eachLine);
            }
        }
        
        if(!contractACHDMap.isEmpty()){
            for(Id eachContractId :contractACHDMap.keySet()){
                achdLineList.addALL(contractACHDMap.get(eachContractId));
            }
            createParentCase(achdLineList);
            achdLineList.clear();
            contractACHDMap.clear();
            mContractProduct.clear();
        }
        
    }
    
    //This method creates a map of contarct Id and its related Line Items which does not have duplicte product
    public void createMapOfContractAndACHD(Autogen_Contract_Header_Detail__c contractLineItem){ 
        
        //Check if the Map contractACHDMap has a key, if not then add key and intialize the list
        if(! contractACHDMap.containsKey(contractLineItem.Parent_Contract_Header__c)){
            contractACHDMap.put(contractLineItem.Parent_Contract_Header__c,new List<Autogen_Contract_Header_Detail__c>());
        }
        
        //Check if map mContractProduct has key or if key exists then line item contains products
        //This section will remove duplicate products(line item) for each contract
        if(! mContractProduct.containsKey(contractLineItem.Parent_Contract_Header__c) 
           || ! mContractProduct.get(contractLineItem.Parent_Contract_Header__c).contains(contractLineItem.Product__c)){
               contractACHDMap.get(contractLineItem.Parent_Contract_Header__c).add(contractLineItem);   
           }
        
        //Check if the Map mContractProduct has a key, if not then add key and intialize the list, else add product
        if(! mContractProduct.containsKey(contractLineItem.Parent_Contract_Header__c)){
            mContractProduct.put(contractLineItem.Parent_Contract_Header__c, new Set<String>());
        }
        mContractProduct.get(contractLineItem.Parent_Contract_Header__c).add(contractLineItem.Product__c);
        
    }
    
    //Method to create case
    public void createParentCase(List<Autogen_Contract_Header_Detail__c> contractLineItem){
        List<Case> caseParentList = new List<Case>();
        Case c;
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        for(Autogen_Contract_Header_Detail__c eachItem :contractLineItem){
            string Service ='';
            if(eachItem.Product__c == 'M-LC-165819'){
                Service = 'Premium Service and Support 3.0';
            }
            else if(eachItem.Product__c == 'M-LC-165820'){
                Service = 'Premium Service and Support 3.0 - Tier 2';
            }
            else if(eachItem.Product__c == 'M-LC-165821'){
                Service = 'Premium Service and Support 3.0 - Tier 3';
            }
            //EM CSG Onboarding Case
            c = new Case();
            c.AccountId = eachItem.Parent_Contract_Header__r.Account_Name__c;
            c.Contract__c = eachItem.Parent_Contract_Header__c;
            c.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
            c.Origin = 'Autogen';
            c.Service__c = Service;
            c.Request_Type__c ='Customer Onboarding';
            c.Severity__c = '3';
            c.Status = 'Unassigned';
            c.Do_Not_Show_in_Portal__c = true;
            c.validation_override__c = true;
            c.Contract_Detail__c = eachItem.Parent_Contract_Detail__r.Name;
            c.Autogen_UseCase__c ='Premium 3.0';
            c.setOptions(dmo);
            //Subject change ESESP-2329
            c.Subject = Service+'::EM::CSG::Customer OnBoarding::'+eachItem.Parent_Contract_Header__r.Account_Name__r.Name;
            c.Description = 'Contract for new Premium 3.0 customer has been entered into the system. Please follow customer onboarding steps for this product located at https://ac.akamai.com/docs/DOC-50914';
            caseParentList.add(c);
            mContractIdAccountName.put(eachItem.Parent_Contract_Header__c,eachItem.Parent_Contract_Header__r.Account_Name__r.Name);
        }
        
        for(Autogen_Contract_Header_Detail__c eachLine :achdLineCLIOnboardList){
            eachLine.IS_CLI_Onboarded__c = true;
        }
        
        Insert caseParentList;
        for(Case eachCase : caseParentList){
            createChildCase(eachCase,mContractIdAccountName);
        }
        Insert childCaseList;
        update achdLineCLIOnboardList;
        caseParentList.clear();
        childCaseList.clear();
        achdLineCLIOnboardList.clear();
        mContractIdAccountName.clear();

    }
    
    public void createChildCase(Case parentCase,Map<Id,String> mapContractIdAccountName){

        for(integer i=0;i<3;i++){
            Case c ;
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.assignmentRuleHeader.useDefaultRule = true;
            //Akatec Onboarding Case
            if(i==0){
                system.debug('---Case i ---'+i+':::'+mapContractIdAccountName.get(parentCase.Contract__c));
                c = new Case();
                c.AccountId = parentCase.AccountId;
                c.Contract__c = parentCase.Contract__c;
                c.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
                c.Origin = 'Autogen';
                c.Sub_Type__c ='Service & Support Packages';
                c.Severity__c = '3';
                c.Status = 'Unassigned';
                c.Do_Not_Show_in_Portal__c = true;
                c.ParentId = parentCase.Id;
                c.validation_override__c = true;
                c.Contract_Detail__c = parentCase.Contract_Detail__c;
            	c.Autogen_UseCase__c ='Premium 3.0';
                c.setOptions(dmo);
                //Subject change ESESP-2329
                c.Subject = parentCase.Service__c+'::Akatec::Customer OnBoarding::'+mapContractIdAccountName.get(parentCase.Contract__c);
                c.Description = 'Contract for new Premium 3.0 customer has been entered into the system. Please follow customer onboarding steps for this product located at https://ac.akamai.com/docs/DOC-50914';
                childCaseList.add(c);
            }
            //Project Management - TPM CSG onboarding case  
            if(i==1){
                system.debug('---Case i ---'+i);
                c = new Case();
                c.AccountId = parentCase.AccountId;
                c.Contract__c = parentCase.Contract__c;
                c.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
                c.Origin = 'Autogen';
                c.Service__c = parentCase.Service__c;
                c.Request_Type__c ='Customer Onboarding';
                c.Severity__c = '3';
                c.Status = 'Unassigned';
                c.Do_Not_Show_in_Portal__c = true;
                c.validation_override__c = true;
                c.Contract_Detail__c = parentCase.Contract_Detail__c;
            	c.Autogen_UseCase__c ='Premium 3.0';
                c.setOptions(dmo);
                //Subject change ESESP-2329
                c.Subject = parentCase.Service__c+'::TPM::CSG::Customer OnBoarding::'+mapContractIdAccountName.get(parentCase.Contract__c);
                c.Description = 'Contract for new Premium 3.0 customer has been entered into the system. Please follow customer onboarding steps for this product located at https://ac.akamai.com/docs/DOC-50914';
                childCaseList.add(c);
            }
            //SD Onboarding Case
            if(i==2){
                system.debug('---Case i ---'+i);
                c = new Case();
                c.AccountId = parentCase.AccountId;
                c.Contract__c = parentCase.Contract__c;
                c.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
                c.Origin = 'Autogen';
                c.Service__c = parentCase.Service__c;
                c.Request_Type__c ='Customer Onboarding';
                c.Severity__c = '3';
                c.Status = 'Unassigned';
                c.ParentId = parentCase.Id;
                c.Do_Not_Show_in_Portal__c = true;
                c.validation_override__c = true;
                c.Contract_Detail__c = parentCase.Contract_Detail__c;
            	c.Autogen_UseCase__c ='Premium 3.0';
                c.setOptions(dmo);
                //Subject change ESESP-2329
                c.Subject = parentCase.Service__c+'::SD::Customer OnBoarding::'+mapContractIdAccountName.get(parentCase.Contract__c);
                c.Description = 'Contract for new Premium 3.0 customer has been entered into the system. Please follow customer onboarding steps for this product located at https://ac.akamai.com/docs/DOC-50914';
                childCaseList.add(c);
            }
        } 
    }
    
    //Method to send out error email
    public void senEmailForError(string emailSubject, string emailBody)
    {    
        // Fetch Support Email Address from Custom Setting - SC_SupportEmail__c
        SC_SupportEmail__c supEmailValues = SC_SupportEmail__c.getValues('1');
        
        // Setting To Address
        String[] toAdd = new String[] {};
            toAdd.add(supEmailValues.Support_Email_AutoGen__c);
        
        // Sending Email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAdd);
        mail.subject = emailSubject;
        mail.plainTextBody = emailBody;
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});        
    } 
}