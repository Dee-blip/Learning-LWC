/***************************************************************************
* Name 			: ACD2_AccountDetails_ERC_WS
* Created By 	: Vamsee S
* Created Date 	: 07-Feb-2020
* Purpose 		: Case Details Webservice.
* Test Class	: ACD2_Webservices_Test
---------------------------------------------------
Last Modified BY 	Last Modified Date 		Purpose
---------------------------------------------------
Vamsee S 			07-Feb-2020 			Initial Development
****************************************************************************


Input Parameters 	: CallGUID(String), ERC(String)
Output Parameters	: isERCFound(String), AKAM_Account_Id(String), allEntitledProducts(List of Stings), 
					  isPremiumAccount(String), Account_Geo(String)

Use Cases:
----------
1. ERC -> 1 Account Found,(Premium Account)
(/services/apexrest/ACD2_AccountDetails_ERC_WS?ERC=2223)

2. ERC -> 1 Account Found, non Premium Account,  with entitledproducts
(/services/apexrest/ACD2_AccountDetails_ERC_WS?ERC=1111)

3. ERC -> 0 Accounts Found
(/services/apexrest/ACD2_AccountDetails_ERC_WS?ERC=111123)

4. ERC -> Multiple Accounts found
(/services/apexrest/ACD2_AccountDetails_ERC_WS?ERC=2362)
*/
@RestResource(urlMapping='/ACD2_AccountDetails_ERC_WS/*')
global class ACD2_AccountDetails_ERC_WS{
    
    global class AccountDetailsWrapper{ 
        string isERCFound;
        String AKAM_Account_Id;
        List<String> allEntitledProducts;
        String isPremiumAccount;
        String Account_Geo;
        
        global AccountDetailsWrapper(){
            isERCFound = 'false';
            AKAM_Account_Id = null;
            allEntitledProducts = new List<String>();
            isPremiumAccount = 'false';
            Account_Geo = null;
        }
    }
    
     @HttpGet
    global static AccountDetailsWrapper getListOutput() {
        
        Datetime requestReceivedTime = DateTime.now();
        RestRequest req = RestContext.request;
        
        String inparam = req.params.get('ERC');
        String callGUID = req.params.get('CallGUID');
        
        AccountDetailsWrapper accountDetailsObject = new AccountDetailsWrapper();        
        if(!String.isBlank(inparam)){
            Try
            {
                inparam = inparam.trim();
                
                List<Account> accountList = [SELECT Id, AKAM_Account_ID__c, Akatec_Geography__c FROM Account WHERE ERC_Numeric__c = :inparam];
    
                if(accountList.size() == 1){
                    accountDetailsObject.isERCFound = 'true';
                    accountDetailsObject.AKAM_Account_Id = accountList[0].AKAM_Account_ID__c;
                    accountDetailsObject.Account_Geo = accountList[0].Akatec_Geography__c;
                    accountDetailsObject.allEntitledProducts = ACD2_UtilClass.getAllProducts(new List<Id>{accountList[0].Id});
                    accountDetailsObject.isPremiumAccount = ACD2_UtilClass.isPremiumAccountCheck(new List<Id>{accountList[0].Id});
                }
                //Multiple Accounts with Same ERC
                else if(accountList.size() > 1){
                    List<Id> accountIdList = new List<Id>();
                    
                    //Get all The account IDs with the given ERC
                    for(Account eachAccount : accountList)
                        accountIdList.add(eachAccount.Id);
                    
                    accountDetailsObject.isERCFound = 'true';
                    accountDetailsObject.AKAM_Account_Id = null;
                    accountDetailsObject.Account_Geo = ACD2_UtilClass.getAkaTecGeo(accountList);
                    accountDetailsObject.allEntitledProducts = ACD2_UtilClass.getAllProducts(accountIdList);
                    accountDetailsObject.isPremiumAccount = ACD2_UtilClass.isPremiumAccountCheck(accountIdList);                 
                }
                
            }
            Catch(Exception e){
                ACD2_UtilClass.sendErrorMail(inparam, e.getMessage(),e.getStackTraceString(),'ACD 2.0 Exception in ACD2_AccountDetails_ERC_WS');
                ACD2_UtilClass.createLog(callGUID,'ACD2_AccountDetails_ERC_WS', 'ERC: '+inparam , 'Error Message: '+e.getMessage() + ' StackTrace: '+ e.getStackTraceString(), 'Exception', requestReceivedTime);
                return accountDetailsObject;
        
            }
        }
        
        ACD2_UtilClass.createLog(callGUID,'ACD2_AccountDetails_ERC_WS', 'ERC: '+inparam ,JSON.serialize(accountDetailsObject), 'Valid',requestReceivedTime);  
        return accountDetailsObject;
        
    }
    

}