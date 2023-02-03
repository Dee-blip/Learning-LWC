/**
* This class converts the quote line data of a quote into a list of apex object which are used to display the data on pdf and excel outputs
* Test Class: CPQ_SObjectDeepCloneTest
* @author Kirti Mishra, Shashank Hegade
* @version 1.0
*/
public without sharing class CPQ_SObjectDeepClone {

    public static List<String> removedProductNames = new List<String>();
    /**
     * @description clonesObject is a flow invocable class to clone the quote
     * @param  requests flow request class which holds all the reqquired info for cloning the quote
     * @return          returns the flow return class which holds the info like status and messages
     * @see             Request
     * @see             Response
     */
    @InvocableMethod(label='Deepclone object')
    public static List<Response> clonesObject(List<Request> requests) {
    
        List<Response> responseList = new List<Response>();
        Boolean completed = true;
        String error = '';
        Request curRequest = requests[0];
        Response response = new Response();
        String recordId = curRequest.recordId;
        String currencyType = curRequest.currencyType;
        System.debug('--recordId: '+recordId);
        
        Schema.DescribeSObjectResult[] describeResult = Schema.describeSObjects(new String[]{curRequest.parentSobjectType, curRequest.childSobjectType});
        
        //logic to deepclone parent, get all fields of the parent from describeResult methods
        List<String> parentFieldNames = new List<String>( describeResult[0].fields.getMap().keySet() );
        
        //query the parent record
        String parentQuery =
            ' SELECT ' +
            String.join( parentFieldNames, ',' ) +
            ' FROM ' +
            describeResult[0].getName() +
            ' WHERE ' +
            ' Id = :recordId ' +
            ' LIMIT 1 '
            ;
        
        // return generic list of sobjects or typecast to expected type
        List<SObject> parentRecords = Database.query( parentQuery );

        System.debug('--parentRecords: '+parentRecords );

        //clone child records
        List<String> childFieldNames = new List<String>( describeResult[1].fields.getMap().keySet() );
        
        String childQuery =
            ' SELECT ' +
            String.join( childFieldNames, ',' ) +
            ' FROM ' +
            describeResult[1].getName() +
            ' WHERE ' +
            ' SBQQ__Quote__c = :recordId '
            ;
        //==============MAKE RELATIONSHIP FIELDNAME DYNAMIC
        
        List<SObject> allChildRecords = Database.query( childQuery );

        //System.debug('--childRecords: '+childRecords);
        
        //deepclone the parent record returned - SObject.clone(preserveId, isDeeplClone)
        SObject cloneParentRecord = parentRecords[0].clone(false, true);

        // setup default start date and end date
        Date defaultBillingDate = Date.today().toStartOfMonth().addMonths(1);
        Date defaultEndDate = defaultBillingDate.addMonths(12).addDays(-1); 
        Date defaultExpiryDate = Date.today().addMonths(1);

        cloneParentRecord.put('CPQ_IsClonedQuote__c', true);
        cloneParentRecord.put('CPQ_Biliing_Effective_Date__c', defaultBillingDate);
        cloneParentRecord.put('SBQQ__EndDate__c', defaultEndDate);
        cloneParentRecord.put('CPQ_Primary__c', false);
        cloneParentRecord.put('SBQQ__Status__c','Draft');
        // cloneParentRecord.put('SBQQ__ExpirationDate__c', defaultExpiryDate);
        cloneParentRecord.put('CPQ_Locked__c', false);
        cloneParentRecord.put('CPQ_Order_Placed_On__c',null);
        cloneParentRecord.put('OwnerId', UserInfo.getUserId());  
        cloneParentRecord.put('SBQQ__Source__c', recordId);  

        
        //check if any lookup need to be updated
        if (curRequest.lookupUpdateField_1_name != null) {
            System.debug('--updating lookup1: '+curRequest.lookupUpdateField_1_name);
            System.debug('--updating lookup1: '+curRequest.lookupUpdateField_1_value);
            cloneParentRecord.put(curRequest.lookupUpdateField_1_name, curRequest.lookupUpdateField_1_value);
        }
        
        if (curRequest.lookupUpdateField_2_name != null) {
            System.debug('--updating lookup2: '+curRequest.lookupUpdateField_2_name);
            cloneParentRecord.put(curRequest.lookupUpdateField_2_name, curRequest.lookupUpdateField_2_value);
        }
        
        System.debug('--cloneParentRecord: '+cloneParentRecord);
        //insert parent record and get new Id
        Savepoint sp = Database.setSavepoint();
        try {
            insert cloneParentRecord;
        } catch (Exception e) {
            completed = false;
            error = e.getMessage();
            throw new InvocableActionException(e.getMessage());
        }
        
        System.debug(' --clone: '+cloneParentRecord.Id+' --cloneSource: '+cloneParentRecord.getCloneSourceId());
        if(currencyType == null){
            SBQQ__Quote__c clonedQuote = [ SELECT Id,Name, CurrencyIsoCode  
                                           FROM SBQQ__Quote__c 
                                           WHERE Id=:cloneParentRecord.Id 
                                           LIMIT 1];
            currencyType = clonedQuote.CurrencyIsoCode;
        }
        
        //Remove if there are any invalid products
        List<SObject> childRecords = CPQ_SObjectDeepClone.checkProductValidity(allChildRecords);

        //Return if any product is missing destination currency
        if( currencyType != null && !childRecords.isEmpty() && CPQ_SObjectDeepClone.checkCurencyAvailability(currencyType, childRecords)== false ){
            Database.rollback(sp);
            response.isSuccess = false;
            response.errors = System.Label.CPQ_Product_not_available_for_the_currency;
            responseList.add(response);
            return responseList;
        }
        else if(!childRecords.isEmpty()) {
            //deepclone the list of child records returned - List.deepClone(preserveId)
            List<SObject> cloneChildRecords = childRecords.deepClone(false);
            
            //before inserting, update the lookup relationship with new parent record created
            for(SObject rec : cloneChildRecords) {
                rec.put(Schema.SBQQ__QuoteLine__c.SBQQ__Quote__c, cloneParentRecord.Id);
                rec.put(Schema.SBQQ__QuoteLine__c.SBQQ__Discount__c, null);
                rec.put(Schema.SBQQ__QuoteLine__c.SBQQ__DiscountSchedule__c, null);
                rec.put(Schema.SBQQ__QuoteLine__c.SBQQ__DiscountTier__c , null);
                rec.put(Schema.SBQQ__QuoteLine__c.CurrencyIsoCode, currencyType);
                rec.put(Schema.SBQQ__QuoteLine__c.SBQQ__Source__c, rec.getCloneSourceId());
            }
            
            //insert child records and get new Ids
            try {
                insert cloneChildRecords;
            } catch (Exception e) {
                completed = false;
                error = e.getMessage();
                throw new InvocableActionException(e.getMessage());
            }
            System.debug(' --child clone: '+cloneChildRecords[0].Id+' --child cloneSource: '+cloneChildRecords[0].getCloneSourceId());
            
            //create a map of child records old-new Ids
            Map<String, String> childOldNewMap = new Map<String, String>();
            for(SObject rec : cloneChildRecords) {
                childOldNewMap.put(rec.getCloneSourceId(),rec.Id);
            }
            
            System.debug('--childOldNewMap: '+childOldNewMap);
            
            //update the self-references
            for(SObject rec : cloneChildRecords) {
                System.debug('--old: '+(String)rec.get(Schema.SBQQ__QuoteLine__c.SBQQ__RequiredBy__c));
                System.debug('--new: '+childOldNewMap.get((String)rec.get(Schema.SBQQ__QuoteLine__c.SBQQ__RequiredBy__c)));
                rec.put(Schema.SBQQ__QuoteLine__c.SBQQ__RequiredBy__c, 
                        childOldNewMap.get((String)rec.get(Schema.SBQQ__QuoteLine__c.SBQQ__RequiredBy__c)));
            }
            //==============MAKE SELF-RELATIONSHIP FIELDNAME DYNAMIC
            //==============Set database savepoints to rollback the transactions
            
            try {
                update cloneChildRecords;
            } catch (Exception e) {
                completed = false;
                error = e.getMessage();
                throw new InvocableActionException(e.getMessage());
            }
        }
        
        if (completed) {
            System.debug('success');
            response.isSuccess = true;
            response.errors = error;
            response.clonedParentId = cloneParentRecord.Id;
            if(!CPQ_SObjectDeepClone.removedProductNames.isEmpty()){
                response.message = System.Label.CPQ_clone_warning_message + '\n';
                response.message =  response.message + String.join(CPQ_SObjectDeepClone.removedProductNames, '\n');
            }
            else{
                response.message = System.Label.CPQ_clone_success;
            }
        } else {
            System.debug('error: '+error);
            response.errors = error;
            response.isSuccess = false;
            Database.rollback(sp);
        }
        responseList.add(response);
        System.debug(LoggingLevel.INFO, '--cloneParentRecord: '+cloneParentRecord);
        return responseList;
    }

    public class Request {
        @invocableVariable
        public String parentSobjectType;
        
        @invocableVariable
        public String recordId;
        
        @invocableVariable
        public String childSobjectType;
        
        @invocableVariable
        public String lookupUpdateField_1_name;
        
        @invocableVariable
        public String lookupUpdateField_1_value;
        
        @invocableVariable
        public String lookupUpdateField_2_name;
        
        @invocableVariable
        public String lookupUpdateField_2_value;

        @invocableVariable
        public String currencyType;
    
    }
    
    public class Response {
        @invocableVariable
        public Boolean isSuccess; 
        
        @invocableVariable
        public String errors;
        
        @invocableVariable
        public String clonedParentId; 
        
        @invocableVariable
        public String message; 
        
    }
    
    public class InvocableActionException extends Exception {}

    /**
     * @description checkProductValidity method is to check the products which are in the quote lines being cloned are in their latest form 
     * @param  lineItems quote lines items which are bing cloned
     * @return           new list of lines , outed lines are removed
     */

    public static List<SObject> checkProductValidity(List<SObject> lineItems){
            
        Set<Id> outdatedLineIds = new Set<Id>();
        List<SObject> returnItems = new List<SObject>();
        

        for( SObject item: lineItems){

           
            // main product in the bundle and modifed
            if((Boolean)item.get('CPQ_Product_Status__c') == true && item.get('SBQQ__RequiredBy__c') == null) {
                outdatedLineIds.add((string)item.get('Id'));
            }
            //sub-product in the bundle modified
            else if ((Boolean)item.get('CPQ_Product_Status__c') == true) {
                outdatedLineIds.add((string)item.get('SBQQ__RequiredBy__c'));
                outdatedLineIds.add((string)item.get('Id'));
            }
            //if it's part of outdated bundle 
            else if (outdatedLineIds.contains((string)item.get('SBQQ__RequiredBy__c'))){
                outdatedLineIds.add((string)item.get('Id'));
            }
        }

        if(outdatedLineIds.isEmpty()){
            return lineItems;
        }
        
        for (SObject item : lineItems) {

                if(!(outdatedLineIds.contains((string)item.Id) || outdatedLineIds.contains((string)item.get('SBQQ__RequiredBy__c')))){
                    returnItems.add(item);
                }
                else if((string)item.get('SBQQ__RequiredBy__c') == null){
                    CPQ_SObjectDeepClone.removedProductNames.add((string)item.get('SBQQ__ProductName__c'));
                }
            
        } 
        return returnItems;
        
    }
    /**
     * @description checkCurencyAvailability method is used to check if the products being cloned is in the suggested opportunity currency.
     * @param  currencyType currency of the opportunity which is used for cloning
     * @param  lineItems    quote line items being cloned
     * @return              returns True if the the products are available , else False
     */ 
    public static Boolean checkCurencyAvailability(String currencyType, List<SObject> lineItems){

        List<Id> relatedProductIdList = new List<Id>();

        for( SObject item: lineItems){
                relatedProductIdList.add((String)item.get('SBQQ__Product__c'));
        }

        Map<Id, Product2> standardPriceBookMap = new Map<Id,Product2>([SELECT Id,(SELECT CurrencyIsoCode FROM PricebookEntries) FROM Product2 WHERE Id  IN :relatedProductIdList ]);

        for(SObject item:lineItems ){
            List<PricebookEntry> productPriceBooks = standardPriceBookMap.get((String)item.get('SBQQ__Product__c')).PricebookEntries;
            Set<String> currencyValues = new Set<String>();
            for( PricebookEntry pbe : productPriceBooks){
                CurrencyValues.add(pbe.CurrencyIsoCode);
            }
            if(currencyValues.isEmpty() || !(currencyValues.contains(currencyType))){
                return false;
            }
        }

        return true;
    }



}