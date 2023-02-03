global class LeanDataReassignContactBatch implements Database.Batchable<sObject> {

    global Database.QueryLocator start(Database.BatchableContext BC) {
        //Can be any custom object or custom setting.
        //Basically where you want to store the where clause for which records to process
        List<Marketing_Settings__mdt> whereClauseSetting = [SELECT Id, Value__c FROM Marketing_Settings__mdt WHERE DeveloperName = 'LeanDataContactWhere' LIMIT 1];
        System.debug('whereClauseSetting');
        System.debug(whereClauseSetting);
        String query;

        //query for the set of contacts you want to process
        //Make sure to include all necessary fields in the query
        //For example the custom "company field"
        if(whereClauseSetting.size()>0){
            query = 'SELECT Id, ReassignContactBatchFailureCount__c, FirstName, LastName, Email, Phone,Company__c, MailingCity, MailingState, MailingCountry, MailingpostalCode  FROM Contact WHERE ' + whereClauseSetting[0].Value__c;
            String batchSize = MarketingUtilClass.getMarketingSettingsValue('LeanDataContactJobSize');
            query += ' limit '+batchSize;
        }
        System.debug('query'+query);
        return Database.getQueryLocator(query);
    }

    global String removeSpecialChars(String input){
        return input==null? null : input.replaceAll('"','').trim();
    }

    global void execute(Database.BatchableContext BC, List<Contact> contactList) {
        System.debug('contacts'+contactList);
        List<Contact> contactsToBeUpdated = new List<Contact>();
        for(Contact c : contactList){
            System.debug('Start of Contact');       
            String company=removeSpecialChars(c.Company__c);
            String firstName =removeSpecialChars(c.FirstName);
            String lastName =removeSpecialChars(c.LastName);
            String email =removeSpecialChars(c.Email);
            String mailingCity =removeSpecialChars(c.MailingCity);
            String mailingState =removeSpecialChars(c.MailingState);
            String mailingCountry =removeSpecialChars(c.MailingCountry);
            String mailingPostalCode =removeSpecialChars(c.MailingpostalCode);

            
            System.debug('company');
            System.debug(company);

            String phone;
            if(c.Phone != null){
                phone = c.Phone.replaceAll('^\\+1|^1|[-,!()+?_\\\' a-wy-zA-WY-Z."\']|(extension(.*)|ext(.*)|x(.*)|X(.*))$','');
            }

            System.debug('phone');
            System.debug(phone);

            //create map of parameters
            //matchedAccountFields is the fields returned from the matching api. If you want an additional field from the matched account add it to that list.
            Map<String, Object> matchedAccountParam = new Map<String,Object>{'category'=>'match', 'operation'=>'matchedAccount', 'version'=>'1', 'inputData'=>'{"FirstName":"' + firstName + '", "LastName":"' + lastName + '", "Email":"' + email + '", "Company":"' + company + '", "City":"' + mailingCity + '", "State":"' + mailingState + '", "Country":"' + mailingCountry + '", "PostalCode":"' + mailingPostalCode + '", "Description":"' +'Contact API' + '", "Phone":"' + phone + '"}', 'matchedAccountFields'=>'["Id","Name","Website","BillingCountry","BillingCity","BillingState","OwnerId"]'};
            System.debug('matchedAccountParam');
            System.debug(matchedAccountParam);
            //call matching api
            List<Account> matchedAccountList;
            try{
                Map<String, Object> matchedAccountsResult = LeanData.LeanDataAPI.findMatches('matchedAccount', matchedAccountParam);
                System.debug('matchedAccountsResult');
                System.debug(matchedAccountsResult);
                
                //populate matchedAccount if we get a result back from the api
               // if(matchedAccountsResult.get('matchedAccount') != null){
                    matchedAccountList = (List<Account>)matchedAccountsResult.get('matchedAccount');
                    System.debug('matchedAccountList');
                    System.debug(matchedAccountList);
                //}
                //populate new account lookup field if we get an account returned from the matching api
               // if(matchedAccountList != null && matchedAccountList.size()>0){
                    System.debug('matchedAccountList[0].Id');
                    System.debug(matchedAccountList[0].Id);
                    c.LeanData_Reporting_Matched_Account__c = matchedAccountList[0].Id;
                    System.debug('c');
                    System.debug(c);
                    contactsToBeUpdated.add(c);
                //}
            }
            catch(Exception e){
                if(c.ReassignContactBatchFailureCount__c > 0){
                    c.ReassignContactBatchFailureCount__c +=1;
                } else {
                    c.ReassignContactBatchFailureCount__c = 1;
                }
                c.validation_override__c=true;
                contactsToBeUpdated.add(c);
            } 
            System.debug('End of Contact');
        }
        
        update contactsToBeUpdated;

    }

    global void finish(Database.BatchableContext BC) {

    }
}