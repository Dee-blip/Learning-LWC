/*  Author      : Vamsee S
    Date        : 23th Jan 2017
    Purpose     : This class will contain helper methods for creating and updating mailer [CR : 3426181]
    Test Class  : CMC_TestClass
    -------------------------------------------------------------------------------------------------
    Vamsee      23/04/2018      ESESP-1094      Removed Do Not Contact Indirect Customers check 
    Vamsee      16/10/2018      ESESP-1752      Added Account Status check on Account Query
*/
public class CMC_MailerHelper {
    
    /* This method parse the json string and returns list of filter objects
     * JSON String format - [{API NAME : Value,API NAME : Value},{API NAME : Value,API NAME : Value}]
     * MailerId is to associate mailer filter with mailer.
     */
    public static List<CMC_Mailer_Filter__c> ParseFilterJSON(String JSONString, Id mailerId){
        List<CMC_Mailer_Filter__c> filterList =  new List<CMC_Mailer_Filter__c>();
        JSONParser parser = JSON.createParser(JSONString);
        Try{
            while (parser.nextToken() != null) {
                if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                    while (parser.nextToken() != null) {
                        if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                            CMC_Mailer_Filter__c filterObject = (CMC_Mailer_Filter__c)parser.readValueAs(CMC_Mailer_Filter__c.class);
                            filterObject.CMC_Filter_Mailer__c = mailerId;
                            if(String.isBlank(filterObject.Id)){
                                filterObject.Id = null;
                            }
                                
                            filterList.add(filterObject);
                        }
                    }
                }
            }   
        }
        catch(Exception ex){
            System.debug('--Exception in CMC_MailerHelper Class--');
            System.debug('Line Number :'+ex.getLineNumber());
            System.debug('Message :'+ex.getMessage());
            apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
        return filterList;
    }
    
    
    
    /* This method parse the raw email addresses by spliting on',' 
     * regex will validate each email addresses and separate the valid and invalid addresses
     * This method returns the List of valid and invalid emails based on paramaters
     */
    public static List<String> ValidateEmailAddresses(String rawEmailAddresses,Id mailerId,Boolean valid){
        List<String> rawEmailAddressList = new List<String>();
        List<String> validEmailAddresses = new List<String>();
        List<String> invalidEmailAddresses = new List<String>();
        Try{
            if(String.isBlank(rawEmailAddresses)){
                //if rawEmailAddresses is null then Emails will be stored as Attachment
                Attachment attachment = [Select Id, Body, ContentType from ATTACHMENT where ParentId =:mailerId AND Name != 'EmailPreview.html' Limit 1];
                String body = attachment.Body.toString();
                rawEmailAddressList = SplitStringForAttachment(body);
            }
            else{
                 rawEmailAddressList = rawEmailAddresses.split('[\n,\r]');
            }
            
            //Remove duplicates from the rawEmails and trim the email addresses
            Set<String> uniqueRawEmailset = new Set<String>();
            for(String eachString : rawEmailAddressList){
                uniqueRawEmailset.add(eachString.trim());
            }
            rawEmailAddressList.clear();
            rawEmailAddressList.addAll(uniqueRawEmailset);
            uniqueRawEmailset.clear();

            //Whether to exclude Akamai Email Addresses or not
            CMC_Settings__mdt  cmcSettings = [SELECT CMC_Exclude_Akamai_Email_Id__c FROM CMC_Settings__mdt WHERE DeveloperName = 'CMC'];
            // Regex to validate the Email Address
            String emailRegex = '([a-zA-Z0-9_\\-\\.+]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,10}|[0-9]{1,3})';
            Pattern emailPattern = Pattern.compile(emailRegex);
            for(String eachEmail : rawEmailAddressList){
                if(String.isNotBlank(eachEmail)){
                    //To remove special Characters in the email
                    if(!eachEmail.isAsciiPrintable())
                        eachEmail = eachEmail.replaceall('[^\\x00-\\x7F]', ''); 
                    
                    //Validate individual emails
                    Matcher emailMatcher = emailPattern.matcher(eachEmail);
                    if(cmcSettings.CMC_Exclude_Akamai_Email_Id__c && eachEmail.containsIgnoreCase('@akamai.com'))
                        invalidEmailAddresses.add(eachEmail);
                    else if(emailMatcher.matches())
                        validEmailAddresses.add(eachEmail);
                    else
                        invalidEmailAddresses.add(eachEmail);
                }
            }
        }
        Catch(Exception ex){
            System.debug('--Exception in CMC_MailerHelper Class--');
            System.debug('Line Number :'+ex.getLineNumber());
            System.debug('Message :'+ex.getMessage());
            apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
        rawEmailAddressList.clear();
        //If valid is true then return valid Email Addresses
        if(valid){
            invalidEmailAddresses.clear();
            return validEmailAddresses;
        }
        else{
            validEmailAddresses.clear();
            return invalidEmailAddresses;
        }
            
   }
    
    /* This method parse the raw email addresses by spliting on',' or ';'
     * regex will validate each email addresses and separate the valid and invalid addresses
     * This method returns the count of valid and invalid emails based on paramaters
     */
    public static List<Integer> GetEmailsCount(String rawEmailAddresses,Id mailerId){
        List<String> rawEmailAddressList = new List<String>();
        List<Integer> emailsCount = new List<Integer>();
        integer validEmailsCount = 0;
        integer invalidEmailsCount = 0;
        Try{
            if(String.isBlank(rawEmailAddresses)){
                //if rawEmailAddresses is null then Emails will be stored as Attachment
                Attachment attachment = [Select Id, Body, ContentType from ATTACHMENT where ParentId =:mailerId and Name != 'EmailPreview.html' Limit 1];
                String body = attachment.Body.toString();
                rawEmailAddressList = SplitStringForAttachment(body);
            }
            else{
                rawEmailAddressList = rawEmailAddresses.split('[\n,\r]');
            }
            
            //Remove duplicates from the rawEmails and trim the email addresses
            Set<String> uniqueRawEmailset = new Set<String>();
            for(String eachString : rawEmailAddressList){
                uniqueRawEmailset.add(eachString.trim());
            }
            rawEmailAddressList.clear();
            rawEmailAddressList.addAll(uniqueRawEmailset);
            uniqueRawEmailset.clear();
            //Whether to exclude Akamai Email Addresses or not
            CMC_Settings__mdt  cmcSettings = [SELECT CMC_Exclude_Akamai_Email_Id__c FROM CMC_Settings__mdt WHERE DeveloperName = 'CMC'];
            // Regex to validate the Email Address
            String emailRegex = '([a-zA-Z0-9_\\-\\.+]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,10}|[0-9]{1,3})';
            Pattern emailPattern = Pattern.compile(emailRegex);
            for(String eachEmail : rawEmailAddressList){
                if(String.isNotBlank(eachEmail)){
                    //To remove special Characters in the email
                    if(!eachEmail.isAsciiPrintable())
                        eachEmail = eachEmail.replaceall('[^\\x00-\\x7F]', ''); 
                    
                    //Validate individual emails
                    Matcher emailMatcher = emailPattern.matcher(eachEmail);
                    if(cmcSettings.CMC_Exclude_Akamai_Email_Id__c && eachEmail.containsIgnoreCase('@akamai.com'))
                        invalidEmailsCount++;
                    else if(emailMatcher.matches())
                        validEmailsCount++;
                    else
                        invalidEmailsCount++;
                }
            }
        }
        catch(Exception ex){
            System.debug('--Exception in CMC_MailerHelper Class--');
            System.debug('Line Number :'+ex.getLineNumber());
            System.debug('Message :'+ex.getMessage());
            apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
        rawEmailAddressList.clear();
        emailsCount.add(validEmailsCount + invalidEmailsCount);
        emailsCount.add(validEmailsCount);
        emailsCount.add(invalidEmailsCount);
        return emailsCount; 
   }
    
    
    /* This Method will generate the query for the filter objects
     */ 
    public static String generateQueryForFilters(List<CMC_Mailer_Filter__c> filterList, String filterLogic, Boolean Is_24x7_Contact_Type){
        //If fliterLogic is null the default filter logic should be applied
        If(String.isBlank(filterLogic)){
            filterLogic ='';
            for(integer i = 1;i<=filterList.size();i++){
                filterLogic = filterLogic + i + ' AND ';
            }
            filterLogic = filterLogic.removeEnd(' AND ');
        }
        //Map to store the Field label and API name
        Map<String, String> fieldAPIMap = new Map<String, String>();
        fieldAPIMap.put('Account ID','AKAM_Account_ID__c ');
        fieldAPIMap.put('Geography','TERR_HIER_1__c');
        fieldAPIMap.put('Support Level','Support_Level__c');
        fieldAPIMap.put('Tier','Customer_Tier__c');
        fieldAPIMap.put('Customer Name','Name');
        if(Is_24x7_Contact_Type == True)
            fieldAPIMap.put('Marketing Product Name','EB_Product__c');
        else
            fieldAPIMap.put('Marketing Product Name','Product__c');
        fieldAPIMap.put('Policy Domain Name','Name');
        
        //Map to store the operator and symbol
        Map<String, String> operatorSymbolMap = new Map<String,String>();
        operatorSymbolMap.put('Equal To','=');
        operatorSymbolMap.put('Not Equal To','!=');
        operatorSymbolMap.put('Contains','LIKE');
        operatorSymbolMap.put('Does Not Contain','LIKE');
        operatorSymbolMap.put('In','IN');
        
        Map<Integer, String> orderFilterMap = new Map<Integer, String> ();
        for(CMC_Mailer_Filter__c eachFilter: filterList){
            String temp;
            if(eachFilter.CMC_Filter_Condition__c == 'Does Not Contain')
                temp = '( NOT ' + fieldAPIMap.get(eachFilter.CMC_Filter_Field__c) + ' ' + operatorSymbolMap.get(eachFilter.CMC_Filter_Condition__c) +' \'%' +eachFilter.CMC_Filter_Value__c.trim()+ '%\')';
            else if(eachFilter.CMC_Filter_Condition__c == 'Contains')
                temp = '(' + fieldAPIMap.get(eachFilter.CMC_Filter_Field__c) + ' ' + operatorSymbolMap.get(eachFilter.CMC_Filter_Condition__c) +' \'%' + eachFilter.CMC_Filter_Value__c.trim()+ '%\')';
            else if(eachFilter.CMC_Filter_Condition__c == 'In'){
                String values;
                if(!String.isBlank(eachFilter.CMC_Filter_Value__c)){
                    values = splitString(eachFilter.CMC_Filter_Value__c);
                }else{
                    List<Attachment> attachmentList = [Select Body from Attachment where ParentId =:eachFilter.Id Limit 1];
                    if(attachmentList.size() == 1){
                        values = splitString(attachmentList[0].Body.toString());
                    }
                }
                temp = '(' + fieldAPIMap.get(eachFilter.CMC_Filter_Field__c) + ' ' + operatorSymbolMap.get(eachFilter.CMC_Filter_Condition__c) + ' (' + values + '))';
            }else{
                temp = '('+ fieldAPIMap.get(eachFilter.CMC_Filter_Field__c) + ' ' + operatorSymbolMap.get(eachFilter.CMC_Filter_Condition__c) +' \'' +eachFilter.CMC_Filter_Value__c.trim()+ '\')';
            }

            //For 24x7 contacts, If the Filter criteria is based on Marketing product name then data need to extract from EB_AccountProductMap__c
            if(Is_24x7_Contact_Type == True){

                if(eachFilter.CMC_Filter_Field__c == 'Marketing Product Name' && filterList.size() == 1){
                    temp = '(Id IN (SELECT EB_Account__c FROM EB_AccountProductMap__c WHERE CMC_Is_Account_Qualified__c = True AND ' + temp + '))';
                }
                else if(eachFilter.CMC_Filter_Field__c == 'Marketing Product Name'){
                    //List<EB_AccountProductMap__c> accountIdList = Database.query('SELECT EB_Account__c FROM EB_AccountProductMap__c WHERE CMC_Is_Account_Qualified = True AND '+temp);
                    String accountIdString = '';
                    String marketingProductQuery = 'SELECT CMC_Akam_Account_Id__c FROM EB_AccountProductMap__c WHERE CMC_Is_Account_Qualified__c = True AND '+temp;
                    For(EB_AccountProductMap__c eachAccount : Database.query(marketingProductQuery)){
                        if(!accountIdString.contains(eachAccount.CMC_Akam_Account_Id__c))
                            accountIdString += '\'' + eachAccount.CMC_Akam_Account_Id__c + '\','; 
                    }
                    temp = '(AKAM_Account_ID__c In ('+ accountIdString.removeEnd(',') + '))';
                    
                    
                }
            }
            else{

                if(eachFilter.CMC_Filter_Field__c == 'Marketing Product Name'){
                    String additionalProductQuery = '';
                    if(eachFilter.CMC_Filter_Condition__c == 'Equal To')
                        additionalProductQuery = '(Additional_Product__c INCLUDES (\'' +eachFilter.CMC_Filter_Value__c.trim()+ '\'))';
                    if(eachFilter.CMC_Filter_Condition__c == 'Not Equal To')
                        additionalProductQuery = '(Additional_Product__c EXCLUDES (\'' +eachFilter.CMC_Filter_Value__c.trim()+ '\'))';
                    if(eachFilter.CMC_Filter_Condition__c == 'In')
                        additionalProductQuery = temp.replace('Product__c IN', 'Additional_Product__c INCLUDES');
                    
                    if(additionalProductQuery != '' && eachFilter.CMC_Filter_Condition__c == 'Not Equal To')
                        temp = '(' + temp + ' AND ' + additionalProductQuery + ')';
                    else if(additionalProductQuery != '')
                        temp = '(' + temp + ' OR ' + additionalProductQuery + ')';
                }
            }
            orderFilterMap.put((integer)eachFilter.CMC_Filter_Order__c ,temp);
            
        }
        //Adding all the filters based on the filter logic. If Fliter logic contains numbers then replace it with corresponding Filter
        List<String> filterLogicChars = filterLogic.split('');
        String output = '';
        for(String eachChar:filterLogicChars){
            if(eachChar.isNumeric())
                output += orderFilterMap.get(Integer.valueOf(eachChar));
            else 
                output += eachChar;
        }

        return output;
    }
    
    /* This function will take input as comma separated values like one,two,three
     * Output will be '\'one\',\'two\',\'three\''
     */
    public Static String splitString(String input){
        String output ='';
        try{
            //If Account name or Product name contains comma ex - 'LAC Co., Ltd'
            Pattern p = Pattern.compile('"(.*?)"');
            Matcher m = p.matcher(input);
            while(m.find()){
                input = input.replace(m.group(), '');
                output = output + '\'' + m.group().remove('"').trim() + '\',';   
            }
            for(String eachValue: input.split('[,\\n]')){
                if(!String.isBlank(eachValue)){
                    output += '\'';
                    output += eachValue.trim();
                    output += '\',';
                }
            }
        }
        Catch(Exception ex){
            System.debug('--Exception in CMC_MailerHelper Class--');
            
           System.debug('Line Number :'+ex.getLineNumber());
            System.debug('Message :'+ex.getMessage());
            apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
        return output.removeEnd(',');
    }
    
    
    /* This method returns the number of accounts which are qualified for the filter logic
     */
    Public Static Integer GetAccountsCount(Id mailerId){
        Integer Count = 0;
        if(mailerId != Null){
            try{
                List<Attachment> attachmentList = [Select Id, Body, ContentType from ATTACHMENT where parentId =:MailerId AND Name = 'QueryString.txt' Limit 1];
                if(attachmentList.size() == 1){
                    String queryString = attachmentList[0].body.toString();  
                    queryString = queryString.replaceFirst('SELECT Id', 'SELECT COUNT()');

                    count = Database.countQuery(queryString);
                }
            }
            Catch(QueryException ex){
                apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()));
                System.debug('--Exception in CMC_MailerHelper Class--');
                System.debug('Line Number :'+ex.getLineNumber());
                System.debug('Message :'+ex.getMessage()); 
            }
        } 
        return Count;
    }

    /* This method will be used to delete the filters and attachment
     */
    Public Static Void cleanUpBeforeSave(Id mailerId, String type){
        Try{
            if(type == 'Filter'){
                List<CMC_Mailer_Filter__c> filterIdForDeletion = new List<CMC_Mailer_Filter__c>([SELECT Id FROM CMC_Mailer_Filter__c WHERE CMC_Filter_Mailer__c =:mailerId]);
                if(filterIdForDeletion.size() >0 && !filterIdForDeletion.isEmpty())
                    delete filterIdForDeletion;
            }
            if(type == 'Attachment'){
                List<Attachment> attachmentsForDelete = new List<Attachment>([SELECT Id FROM Attachment WHERE parentId =:mailerId AND Name != 'QueryString.txt']);
                if(attachmentsForDelete.size() >0 && !attachmentsForDelete.isEmpty())
                    delete attachmentsForDelete;
            }
            if(type == 'QueryString'){
                List<Attachment> attachmentsForDelete = new List<Attachment>([SELECT Id FROM Attachment WHERE parentId =:mailerId AND Name = 'QueryString.txt']);
                if(attachmentsForDelete.size() >0 && !attachmentsForDelete.isEmpty())
                    delete attachmentsForDelete;
            }
        }
        Catch(Exception ex){
            apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            System.debug('--Exception in CMC_MailerHelper Class--');
            System.debug('Line Number :'+ex.getLineNumber());
            System.debug('Message :'+ex.getMessage()); 
        }
        
    }
    
    /* This method will give the list of mailer accounts which are qualified 
     * This method will be called after Peer reviewer approved the mailer
     */ 
    Public Static void createAccount(String queryString, EB_AkaMailer__c mailerObject){
        CMC_Settings__mdt cmcSettings = [SELECT CMC_Default_Account_Id__c, CMC_Default_Contact_Id__c, CMC_Default_Policy_Domain_Id__c FROM CMC_Settings__mdt WHERE DeveloperName = 'CMC'];
        List<EB_AkaMAccount__c> mailerAccountList = new List<EB_AkaMAccount__c>();
        List<EB_MailerException__c> mailerExceptionList = new List<EB_MailerException__c>();
        EB_AkaMAccount__c mailerAccount;
        
        Try{
            //Default Account need to be included for manual emails and 24x7 contacts
            if(String.isBlank(queryString) || mailerObject.CMC_24x7_Contact_Types__c == True){
                Account defaultAccount = [SELECT Id FROM Account Where Akam_Account_Id__c =:cmcSettings.CMC_Default_Account_Id__c LIMIT 1];
                mailerAccount = new EB_AkaMAccount__c();
                mailerAccount.RecordTypeId = Schema.SObjectType.EB_AkaMAccount__c.getRecordTypeInfosByName().get('CMC').getRecordTypeId();
                mailerAccount.EB_Account__c = defaultAccount.Id;
                mailerAccount.EB_AkaMailer__c = mailerObject.Id;
                mailerAccountList.add(mailerAccount);
            }
            
            //Invalid Email addresses will be part of mailerException For manual Entered Email Addresses
            if(String.isBlank(queryString)){
                //EB_AkaMailer__c mailerObject = [SELECT Id, CMC_Manual_Email_Addresses__c FROM EB_AkaMailer__c WHERE Id =:mailerObject.Id];
                List<String> invalidEmailAddresses = CMC_MailerHelper.ValidateEmailAddresses(mailerObject.CMC_Manual_Email_Addresses__c,mailerObject.Id,false);
                //Create The exceptions Async
                CreateException(mailerObject.Id, invalidEmailAddresses, 'Emails');
                
                //Insert Mailer Account for Manually Entered Emails
                insert mailerAccountList;
            }
            //For 24x7 Contact Type
            else if(mailerObject.CMC_24x7_Contact_Types__c == True){
                queryString = queryString.replaceFirst('SELECT Id', 'SELECT Id, Akam_Account_Id__c,Name, (SELECT Id FROM Contacts WHERE Contact_Type__c INCLUDES (\'Technical Primary - 24X7\',\'Tech Secondary - 24X7\') AND IsEmailBounced = False)');
                List<String> accountIdsForException = new List<String>();
                List<Account> lAllAccount = Database.query(queryString);
                for(Account eachAccount : lAllAccount){
                    //Accounts with 24x7 Contacts will be part of Mailer Account
                     if(eachAccount.Contacts.size() > 0){
                         //This is to avoid the insertion of Akamai Assets account twice
                         if(eachAccount.Akam_Account_Id__c != cmcSettings.CMC_Default_Account_Id__c){
                            mailerAccount = new EB_AkaMAccount__c();
                            mailerAccount.RecordTypeId = Schema.SObjectType.EB_AkaMAccount__c.getRecordTypeInfosByName().get('CMC').getRecordTypeId();
                            mailerAccount.EB_Account__c = eachAccount.Id;
                            mailerAccount.EB_AkaMailer__c = mailerObject.Id;
                            mailerAccountList.add(mailerAccount);
                         }
                    }
                    //Accounts with no 24x7 Contacts will be part of Mailer Exception
                    else{
                        accountIdsForException.add(eachAccount.Id);
                    }
                }
                //Create The exceptions Async
                CreateException(mailerObject.Id, accountIdsForException, 'Accounts');
                
                //Insert Mailer Account for 24X7 Contacts
                insert mailerAccountList;
            }
            else if(mailerObject.AuthCon_Authorized_Contacts__c == True){
                //Map of Account id to Set of corresponding Policy Domain Ids used for Authrized Contacts.
                Map<Id, Set<Id>> mAccIdLPolicyDomainId = new Map<Id, Set<Id>>();
                String tempQueryString = 'SELECT Id, Account_Name__c, Account_Name__r.Akam_Account_Id__c, Service_Account__c, Service_Account__r.Akam_Account_Id__c';
                
                // Variable to store Authorized query
                string authorizedContactQuery = 'Select Id, Contact_Name__c, Contact_Name__r.IsEmailBounced from Authorized_Contacts__r where ';
                if(mailerObject.AuthCon_Emergency_Notification_Recipient__c == true)
                    authorizedContactQuery += 'Emergency_Email__c = true ';
                else if(mailerObject.AuthCon_Maint_Notification_Recipient__c == true)
                    authorizedContactQuery += 'Maintenance_Email__c = true ';
                
                authorizedContactQuery += ' AND Contact_Name__c != null AND Contact_Name__r.Email != null ';
                
                String values;
                for(CMC_Mailer_Filter__c eachFilter: mailerObject.CMC_Mailer_Filters__r){
                    if(eachFilter.CMC_Filter_Field__c == 'Marketing Product Name' && eachFilter.CMC_Filter_Condition__c != 'Not Equal To'){
                        if(!String.isBlank(eachFilter.CMC_Filter_Value__c)){
                            values = CMC_MailerHelper.splitString(eachFilter.CMC_Filter_Value__c);
                        }else{
                            List<Attachment> attachmentList = [Select Body from Attachment where ParentId =:eachFilter.Id Limit 1];
                            if(attachmentList.size() == 1){
                                values = CMC_MailerHelper.splitString(attachmentList[0].Body.toString());
                            }
                        }
                    }
                }
                if(!String.isBlank(values))
                    authorizedContactQuery += 'AND (Product_Interests__c includes (' +values+ ') OR Product_Interests__c = \'All\')';
                
                tempQueryString += ', (' +authorizedContactQuery+ ' ) ';
                
                //adding default PDs check to the Query string
                CMC_Settings__mdt cmcMetadatarec = [select Id,CMC_Default_Policy_Domain_Id__c from CMC_Settings__mdt where MasterLabel = 'CMC' limit 1];
                String lDefaultAkamPDId = '';
                for(String eachPd : cmcMetadatarec.CMC_Default_Policy_Domain_Id__c.split(',')){
                    lDefaultAkamPDId += '\'' +eachPd.trim()+ '\',';
                }
                lDefaultAkamPDId = lDefaultAkamPDId.removeEnd(',');

                if(!String.isBlank(lDefaultAkamPDId)){
                    if(mailerObject.CMC_All_Customers__c == False){
                        String queryStringForDefaultPD = 'WHERE (Policy_Domain_State__c = \'Active\') AND ((AKAM_Policy_Domain_ID__c IN (' + lDefaultAkamPDId + ')) OR (';
                        queryString = queryString.replace('WHERE (Policy_Domain_State__c = \'Active\') AND (', queryStringForDefaultPD);
                        queryString += ')';
                    }
                    else{
                        String queryStringForDefaultPD = 'WHERE (Policy_Domain_State__c = \'Active\') OR (AKAM_Policy_Domain_ID__c IN (' + lDefaultAkamPDId + '))';
                        queryString = queryString.replace('WHERE (Policy_Domain_State__c = \'Active\')', queryStringForDefaultPD); 
                    }
                }
                
                queryString = queryString.replaceFirst('SELECT Id', tempQueryString);
                queryString += ' limit 49000';

                
                //List of policy domains which has No or All Bounced Authorized Contacts to be created as Mailer Exceptions
                List<String> lPolicyDomainsWithNoAC = new List<String>();
                List<String> lPolicyDomainsWithAllBouncedAC = new List<String>();
                
                List<Policy_Domain__c> lAllPolicyDomain = Database.query(queryString);
                for(Policy_Domain__c eachPD : lAllPolicyDomain){
                    if(eachPD.Authorized_Contacts__r.size()>0){
                        Boolean isAllContactsBounced = True;
                        for(Authorized_Contact__c eachAC : eachPD.Authorized_Contacts__r){
                            if(!eachAC.Contact_Name__r.IsEmailBounced){
                                isAllContactsBounced = False;
                                break;
                            }
                        }
                        if(!isAllContactsBounced){
                            //Insert mailer Account for Account on PD
                            if(!mAccIdLPolicyDomainId.containsKey(eachPD.Account_Name__c)){
                                mailerAccount = new EB_AkaMAccount__c();
                                mailerAccount.RecordTypeId = Schema.SObjectType.EB_AkaMAccount__c.getRecordTypeInfosByName().get('CMC').getRecordTypeId();
                                mailerAccount.EB_Account__c = eachPD.Account_Name__c;
                                mailerAccount.EB_AkaMailer__c = mailerObject.Id;
                                mailerAccountList.add(mailerAccount);
                            }
                            //Insert mailer Account for Service Account on PD
                             if(eachPD.Service_Account__c !=null && !mAccIdLPolicyDomainId.containsKey(eachPD.Service_Account__c)){
                                mailerAccount = new EB_AkaMAccount__c();
                                mailerAccount.RecordTypeId = Schema.SObjectType.EB_AkaMAccount__c.getRecordTypeInfosByName().get('CMC').getRecordTypeId();
                                mailerAccount.EB_Account__c = eachPD.Service_Account__c;
                                mailerAccount.EB_AkaMailer__c = mailerObject.Id;
                                mailerAccountList.add(mailerAccount);
                             }
                            
                            //Adding to the map 
                            if(mAccIdLPolicyDomainId.get(eachPD.Account_Name__c) == Null)
                                mAccIdLPolicyDomainId.put(eachPD.Account_Name__c, new Set<Id>());
                            mAccIdLPolicyDomainId.get(eachPD.Account_Name__c).add(eachPD.Id);
                            if(eachPD.Service_Account__c !=null){
                                if(mAccIdLPolicyDomainId.get(eachPD.Service_Account__c) == Null)
                                    mAccIdLPolicyDomainId.put(eachPD.Service_Account__c, new Set<Id>());
                                mAccIdLPolicyDomainId.get(eachPD.Service_Account__c).add(eachPD.Id);
                            }
                            
                        }
                        else
                            lPolicyDomainsWithAllBouncedAC.add(eachPD.Id);
                    }
                    else{
                        lPolicyDomainsWithNoAC.add(eachPD.Id);
                    }
                }
                
                //Create The exceptions Async
                CreateException(mailerObject.Id, lPolicyDomainsWithAllBouncedAC, 'PolicyDomainsWithAllBouncedAC');
                CreateException(mailerObject.Id, lPolicyDomainsWithNoAC, 'PolicyDomainsWithNoAC');
                
                //Insert Mailer Account for Authorized Contacts
                insert mailerAccountList;
                //map of Account Id to Mailer Account Id
                Map<Id, Id> mAccIdMailerAccId = new Map<Id, Id>();
                //Populating map
                for(EB_AkaMAccount__c eachMailerAcc : mailerAccountList)
                    mAccIdMailerAccId.put(eachMailerAcc.EB_Account__c, eachMailerAcc.Id);
                
                //List to create records for junction object Mailer_Acc_Policy_Domain_Association__c 
                List<Mailer_Acc_Policy_Domain_Association__c> lMailerAccPDAssociation = new List<Mailer_Acc_Policy_Domain_Association__c>();
                for(Id eachAcc : mAccIdLPolicyDomainId.keySet())
                    for(Id eachPd : mAccIdLPolicyDomainId.get(eachAcc)){
                        Mailer_Acc_Policy_Domain_Association__c eachrec = new Mailer_Acc_Policy_Domain_Association__c();
                        eachrec.Mailer_Account__c = mAccIdMailerAccId.get(eachAcc);
                        eachrec.Policy_Domain__c  = eachPD;
                        eachrec.Mailer__c = mailerObject.Id;
                        lMailerAccPDAssociation.add(eachrec);
                    }
                if(lMailerAccPDAssociation.size()>0)
                   insert lMailerAccPDAssociation;
                
            }
            
        }
        Catch(Exception ex){
            apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'vam test'+ ex.getMessage())); 
            System.debug('--Exception in CMC_MailerHelper Class--');
            System.debug('Line Number :'+ex.getLineNumber());
            System.debug('Message :'+ex.getMessage()); 
        }
        
        //return mailerAccountList;
    }
     
    /* This method validate if customer-notifications@akamai.com is marked as bad.
     * This method will return "Valid" if contact is not marked as bad 
     */
    Public Static string ValidateContactEmail(){
        string result;
        Try{
            CMC_Settings__mdt  cmcSettings = [SELECT CMC_Default_Contact_Id__c FROM CMC_Settings__mdt WHERE DeveloperName = 'CMC'];
            Contact c = [Select EmailBouncedReason, Email from Contact where Akam_Contact_Id__c  =:cmcSettings.CMC_Default_Contact_Id__c ];
            if(c.EmailBouncedReason != null && c.EmailBouncedReason != '') {  
                result= c.Email + ' is marked as bad. Please update the email bounce information on the contact for the same and retry.';
            }
            else{
                result = 'Valid';
            }
        }
        Catch(Exception ex){
            System.debug('--Exception in CMC_MailerHelper Class--');
            System.debug('Line Number :'+ex.getLineNumber());
            System.debug('Message :'+ex.getMessage()); 
            apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage())); 
        }
        
        return result;
    }
    
    Public Static string GenerateQuery(EB_AkaMailer__c mailerObject){
        
        //Get the Account Status Sub Query
        CMC_Settings__mdt  cmcSettings = [SELECT Account_Status_Sub_Query__c FROM CMC_Settings__mdt WHERE DeveloperName = 'CMC'];

        String queryString = 'SELECT Id FROM Account WHERE '+ cmcSettings.Account_Status_Sub_Query__c +' (';
        if(mailerObject.CMC_Indirect_Customers__c == True)
            queryString = queryString + 'Indirect_Customer__c = True OR ';
        if(mailerObject.CMC_Direct_Customers__c == True)
            queryString = queryString + 'Direct_Customer__c = True OR ';
        if(mailerObject.CMC_Partners__c == True)
            queryString = queryString + 'IsPartnerCustom__c = True OR ';
        
        //Check for All customers or Selected Customers
        if(mailerObject.CMC_All_Customers__c == True){
            queryString = queryString.removeEnd('OR ');
            queryString = queryString + ')';
        } 
        else{
            String tempQueryString = CMC_MailerHelper.generateQueryForFilters(mailerObject.CMC_Mailer_Filters__r, mailerObject.CMC_Filter_Logic__c, mailerObject.CMC_24x7_Contact_Types__c);
            tempQueryString =  ') AND (' + tempQueryString + ')';
            queryString = queryString.removeEnd('OR ')+ ' ' + tempQueryString;
        }

        return queryString;         
    }
    
    Public Static string GenerateQueryForSOCC(EB_AkaMailer__c mailerObject){
        String queryString = 'SELECT Id FROM Policy_Domain__c WHERE (Policy_Domain_State__c = \'Active\') ';
        
        //Check for All customers or Selected Customers
        if(mailerObject.CMC_All_Customers__c == False){
            String tempQueryString = CMC_MailerHelper.generateQueryForFilters(mailerObject.CMC_Mailer_Filters__r, mailerObject.CMC_Filter_Logic__c, mailerObject.CMC_24x7_Contact_Types__c);
            queryString = queryString + 'AND (' + tempQueryString + ')';
        }

        return queryString;         
    }
    
    /* This method is to separate the transaction for Mailer Exception Insertion
     * This will reduce the time taken to create the mailer
     */
    
    @future
    Public Static void CreateException(Id mailerId, List<String> records, String exceptionType){
        if(records.size() > 0){
            Try{
                List<EB_MailerException__c> mailerExceptionList = new List<EB_MailerException__c>();
                if(exceptionType == 'Emails'){
                    Integer count =0;
                    for(String eachRecord : records){
                        count++;
                        if(count == 9999){
                            break;
                        }
                        EB_MailerException__c mailerException = new EB_MailerException__c();
                        mailerException.EB_Mailer__c = mailerId;
                        mailerException.EB_Type__c = 'Invalid Email';
                        mailerException.Exception_Message__c = eachRecord+' is invalid Email Address';
                        mailerException.CMC_Email_Address__c = eachRecord;
                        mailerException.CMC_Stage__c = 'Pre Mailer';
                        mailerExceptionList.add(mailerException);
                    }
                }
                else if(exceptionType == 'Accounts'){
                    for(Account eachAccount : [SELECT Name, AKAM_Account_ID__c, (SELECT Id FROM Contacts WHERE Contact_Type__c INCLUDES ('Technical Primary - 24X7','Tech Secondary - 24X7')) FROM Account Where Id IN :records]){
                            EB_MailerException__c mailerException = new EB_MailerException__c();
                            mailerException.EB_Mailer__c = mailerId;
                            mailerException.CMC_Akam_Account_Id__c = eachAccount.AKAM_Account_ID__c;
                            mailerException.CMC_Stage__c = 'Pre Mailer';
                            if(eachAccount.Contacts.size() == 0){
                                mailerException.EB_Type__c = 'No 24x7 Contact';
                                mailerException.Exception_Message__c = eachAccount.Name + ' has no 24x7 Primary/Secondary Contact';
                            }
                            else{
                                mailerException.EB_Type__c = 'All Bounced 24x7 Contacts';
                                mailerException.Exception_Message__c = eachAccount.Name + ' has all bounced 24x7 Primary/Secondary Contact';
                            }
                        
                            mailerExceptionList.add(mailerException);
                    }
                            
                }
                else if(exceptionType == 'PolicyDomainsWithNoAC' || exceptionType == 'PolicyDomainsWithAllBouncedAC'){
                    for(Policy_Domain__c eachPD : [SELECT Id, Name, AKAM_Policy_Domain_ID__c FROM Policy_Domain__c WHERE Id IN :records]){
                        EB_MailerException__c mailerException = new EB_MailerException__c();
                        mailerException.EB_Mailer__c = mailerId;
                        mailerException.AuthCon_Akam_Policy_Domain_Id__c = eachPD.AKAM_Policy_Domain_ID__c;
                        mailerException.CMC_Stage__c = 'Pre Mailer';
                        if(exceptionType == 'PolicyDomainsWithNoAC'){
                            mailerException.EB_Type__c = 'No Authorized Contact';
                            mailerException.Exception_Message__c = eachPD.Name + ' has No Authorized Contacts';
                        }
                        else if(exceptionType == 'PolicyDomainsWithAllBouncedAC'){
                            mailerException.EB_Type__c = 'All Bounced Authorized Contacts';
                            mailerException.Exception_Message__c = eachPD.Name + ' has All Bounced Authorized Contacts';
                        }
                        mailerExceptionList.add(mailerException);
                    }
                }
                insert mailerExceptionList;
            }
            Catch(Exception ex){
                System.debug('--Exception in CMC_MailerHelper Class--');
                System.debug('Line Number :'+ex.getLineNumber());
                System.debug('Message :'+ex.getMessage()); 
            }
                
        }
    }
    
    
    /* This method creates and updates the QueryString.txt File
     * Query string will be stored as Attachment on the mailer object
     */
    public Static void QueryStringAttachment(String queryString, Id MailerId){
        try{
            List<Attachment> attachmentList = [Select Id, Body, ContentType from ATTACHMENT where parentId =:MailerId AND Name = 'QueryString.txt' Limit 1];
            Attachment attachment;
            if(attachmentList.size() == 1){
                attachment = attachmentList[0];
            }
            else{
                attachment = new Attachment();
                attachment.parentId = MailerId;
                attachment.Name = 'QueryString.txt';
                attachment.ContentType = 'application/text';
            }
            attachment.body = Blob.valueOf(queryString);
            Upsert attachment;
        }
        Catch(Exception ex){
            apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            System.debug('--Exception in CMC_MailerHelper Class--');
            System.debug('Line Number :'+ex.getLineNumber());
            System.debug('Message :'+ex.getMessage()); 
        }
    }



    /* This method updates the attachment Ids on The filter
     * This is to provide Downloadable URL of the attachment since attachment related list is removed 
     * from the page layout
     */

    public Static void UpdateAttachmentIds(Id mailerId){
        Try{
            List<CMC_Mailer_filter__c> filterObjectList = [SELECT Id, CMC_Filter_Attachment__c, (SELECT Id FROM attachments)  FROM CMC_Mailer_filter__c WHERE CMC_Filter_Mailer__c =:mailerId AND CMC_Filter_Condition__c = 'In' AND CMC_Filter_Value__c = null];
            if(filterObjectList.size() > 0){
                For(CMC_Mailer_filter__c eachFilter : filterObjectList){
                    if(eachFilter.attachments.size() == 1)
                        eachFilter.CMC_Filter_Attachment__c = eachFilter.attachments[0].Id;
                }
                Update filterObjectList;
            }
        }
        Catch(Exception ex){
            apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            System.debug('--Exception in CMC_MailerHelper Class--');
            System.debug('Line Number :'+ex.getLineNumber());
            System.debug('Message :'+ex.getMessage()); 
        }
    }
    
    /* This method will split the string based on comma or new line
     * This method is to avoid the REGEX TOO COMPLICATED exception for big files.
     * This method process the string in batches
     */ 
    
    public static List<String> SplitStringForAttachment(String body){
        //Number of characters in each batch
        CMC_Settings__mdt  cmcSettings = [SELECT CMC_No_of_Char_for_file_processing__c FROM CMC_Settings__mdt WHERE DeveloperName = 'CMC'];
        integer batchSize = Integer.valueOf(cmcSettings.CMC_No_of_Char_for_file_processing__c);
        
        //Number of batches required to process the complete string   
        integer noOfBatches = Integer.valueOf(Math.floor(body.length()/batchSize));
        
        //List to store the emails after spliting
        List<String> rawEmailAddressList = new List<String>();
        
        Try{
            //Process each batch in a for loop
            for(Integer eachBatch = 0; eachBatch < noOfBatches + 1; eachBatch++){
                                    
                //If string size is greater the batchsize then split it otherwise process it in normal way
                if(body.length() > batchSize){
                    //Get the index of first comma and new line occurence after 'batchsize' characters
                    Integer newlineIndex = body.indexOf('\n', batchSize);
                    if(newlineIndex == -1)
                        newlineIndex = body.indexOf('\r', batchSize);
                    Integer commaIndex = body.indexOf(',', batchSize);
                    String tempBody;
                    //If both comma and new line are present then take the nearest one.
                    if(newlineIndex < commaIndex && newlineIndex != -1){
                        tempBody = body.substring(0, newlineIndex);
                        body = body.substring(newlineIndex+1);
                    }   
                    else if(newlineIndex > commaIndex && commaIndex != -1){
                        tempBody = body.substring(0, commaIndex);
                        body = body.substring(commaIndex+1);
                    }
                    //If both comma and new line are not available in the 'batchsize' characters then split the entire string
                    else if(newlineIndex == -1 && commaIndex == -1){
                        rawEmailAddressList.addall(body.split('[\n,\r]'));
                        break;
                        
                    }
                    //If only new line characters are present
                    else if(newlineIndex > commaIndex){
                        tempBody = body.substring(0, newlineIndex);
                        body = body.substring(newlineIndex+1);
                    }
                    //if only comma's are present
                    else if(newlineIndex < commaIndex){
                        tempBody = body.substring(0, commaIndex);
                        body = body.substring(commaIndex+1);
                    }
                    rawEmailAddressList.addAll(tempBody.split('[\n,\r]'));
                }
                else{
                    rawEmailAddressList.addall(body.split('[\n,\r]'));
                    break;
                }
                
            }
        }
        Catch(Exception ex){
            apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            System.debug('--Exception in CMC_MailerHelper Class--');
            System.debug('Line Number :'+ex.getLineNumber());
            System.debug('Message :'+ex.getMessage()); 
        }
        return rawEmailAddressList;
    
    }
}