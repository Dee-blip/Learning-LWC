public class AccSalesPlayAssociationTriggerClass {

     public static void insertOSPARecords(List<Account_Sales_Play_Association__c> ASPAList,
                                         Set<Id> salesPlayIds, Set<Id> accountIds) {
        Map<Id,Set<Id>> accSalesPlayMap = new Map<Id,Set<Id>>();
        Set<String> productIds = new Set<String>();
        Map<Id,List<Id>> salesPlayProductsMap = new Map<Id,List<Id>>();
        Set<Id> salesPlayRecIds;
        Map<Id,Id> opportunityAccountMap = new Map<Id,Id>();
        Map<Id,Set<String>> opportunityProductsMap = new Map<Id,Set<String>>();
        Set<String> oppProductIds;
        List<String> truncProdIds;
        Set<Id> accIds = new Set<Id>();
        Opportunity_Sales_Play_Association__c OSPARec;
        List<Opportunity_Sales_Play_Association__c> OSPAList = 
            new List<Opportunity_Sales_Play_Association__c>();
        Map<String,Id> existingOSPARecsMap = new Map<String,Id>();
        Map<String,Opportunity_Sales_Play_Association__c> ospaNewMap = 
            new Map<String,Opportunity_Sales_Play_Association__c>();
        for(Account_Sales_Play_Association__c ASPARec : [Select Id, Account__c, Sales_Play__c,
                                                         Sales_Play__r.Product_Id__c from
                                                         Account_Sales_Play_Association__c where
                                                         Sales_Play__c in :salesPlayIds and 
                                                         Account__c in :accountIds]) {
            salesPlayRecIds = new Set<Id>();
            if(accSalesPlayMap.get(ASPARec.Account__c) == null) {
                salesPlayRecIds.add(ASPARec.Sales_Play__c);
                accSalesPlayMap.put(ASPARec.Account__c,new Set<Id>());
                accSalesPlayMap.put(ASPARec.Account__c,salesPlayRecIds);
            } else {
                accSalesPlayMap.get(ASPARec.Account__c).add(ASPARec.Sales_Play__c); 
            }
            accIds.add(ASPARec.Account__c);
            if(ASPARec.Sales_Play__r.Product_Id__c != null)
            {
                salesPlayProductsMap.put(ASPARec.Sales_Play__c,ASPARec.Sales_Play__r.Product_Id__c.split(','));
                for(Id prId : ASPARec.Sales_Play__r.Product_Id__c.split(',')) 
                {
                    system.debug('ASPARec.Sales_Play__r.Product_Id__c = '+ASPARec.Sales_Play__r.Product_Id__c.split(',')); 
                    system.debug('prId = '+String.valueOf(prId).substring(0, 15));
                    productIds.add(String.valueOf(prId).substring(0, 15));
                }
            }
        }


        for(Opportunity_Sales_Play_Association__c ospa : [Select Id,Opportunity__c,Account__c,
                                                          Sales_Play__c 
                                                          from Opportunity_Sales_Play_Association__c 
                                                          where Account__c in :accountIds]) {
            existingOSPARecsMap.put(String.valueof(ospa.Opportunity__c)+String.valueof(ospa.Sales_Play__c),
                                    ospa.Id);
        }



        system.debug('productIds = ' + productIds);
        system.debug('accSalesPlayMap' + accSalesPlayMap);
        system.debug('salesPlayProductsMap' + salesPlayProductsMap);
        system.debug('existingOSPARecsMap' + existingOSPARecsMap);

        for(OpportunityLineItem oi : [Select OpportunityId,Opportunity.AccountId, Product2Id__c 
                                      from OpportunityLineItem where Product2Id__c in :productIds 
                                      AND Opportunity.AccountId in :accountIds AND 
                                      Opportunity.RecordType.Name != 'Administrative Opportunity']) 
        {
            opportunityAccountMap.put(oi.OpportunityId,oi.Opportunity.AccountId);   
            oppProductIds = new Set<String>();
            if(opportunityProductsMap.get(oi.OpportunityId) == null) {
                oppProductIds.add(oi.Product2Id__c);
                opportunityProductsMap.put(oi.OpportunityId,new Set<String>());
                opportunityProductsMap.put(oi.OpportunityId,oppProductIds);
            } else { 
                opportunityProductsMap.get(oi.OpportunityId).add(oi.Product2Id__c);
            }
            
        }

        system.debug('opportunityProductsMap' + opportunityProductsMap);
        system.debug('opportunityAccountMap' + opportunityAccountMap);
        if(opportunityAccountMap.size() > 0 && opportunityProductsMap.size() > 0) {
            for(Id oppId : opportunityAccountMap.keyset()) {
 
                Id AccountId = opportunityAccountMap.get(oppId);
                Set<String> opportunityProductIds = opportunityProductsMap.get(oppId);
                for (Id salesPlayId : accSalesPlayMap.get(AccountId)) {
                    if(!existingOSPARecsMap.containsKey(String.valueOf(oppId)+String.valueOf(salesPlayId))) {
                        List<Id> prodIds = salesPlayProductsMap.get(salesPlayId);
                        for(String oppPrdId : opportunityProductIds) {
                            if(prodIds != null && prodIds.contains(oppPrdId)) {
                                OSPARec = new Opportunity_Sales_Play_Association__c();
                                OSPARec.Opportunity__c = oppId;
                                OSPARec.Sales_Play__c = salesPlayId;
                                OSPARec.Account__c = AccountId;
                                ospaNewMap.put(String.Valueof(oppId)+String.Valueof(salesPlayId), OSPARec);
                                //OSPAList.add(OSPARec);
                                Break;
                            }
                        }
                    } else {
                        system.debug('OSPA Exists = ' +String.valueOf(oppId)+String.valueOf(salesPlayId));
                    }
                }
            }
        }

        if(ospaNewMap.size() > 0) {
            // SFDC-6596 Let other records pass if few fails in a Batch
            // Log in failures in Error log
            List<String> fieldsToLog = new List<String>();
            fieldsToLog.add('Account__c');
            fieldsToLog.add('Opportunity__c');
            String htmlbody = GsmUtilClass.doDatabaseInsertWithErrorEmail(ospaNewMap.values(), 
                                                            'AccSalesPlayAssociatiomTriggerCLass', 
                                                            'AccSalesPlayAssociatiomTriggerCLass', 
                                                            true,fieldsToLog);
           
            //Send email with Account IDs if any failures
            if(htmlbody != ''){
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                List<Messaging.SingleEmailMessage > mailList = new List<Messaging.SingleEmailMessage >();
                List<String> toListEmail = new List<String>();
                toListEmail.add(UserInfo.getUserEmail());
                message.setToAddresses(ToListEmail); 
                
                String emailText = 'Account SalesPlay insertion completed but Opportunity SalesPlay could not be created, see error <br/>'; 
                emailText = emailText+'Please rectify the error and try again<br/><br/>';
                
                String header = '<tr>';
                for(string field : fieldsToLog){
                    header = header+'<th>' + String.valueOf(field) + '</th>';
                }
                header = header+'<th>Error</th></tr>';
               
                emailText = emailText+ '<table style="border: 1px solid black; border-collapse : collapse;">'+header+htmlbody+'</table>';
                
                message.setHTMLBody (emailText);
                message.setSubject('Opportunity Sales Play Insertion Failed');
                mailList.add(message);
                Messaging.sendEmail(mailList);
            }
        }

    }

    public static void deleteOSPARecords(Set<Id> accountIds, Set<Id> salesPlayIds) {
        List<Opportunity_Sales_Play_Association__c> OSPADeleteRecs = 
            [Select Id from Opportunity_Sales_Play_Association__c
             where Account__c in :accountIds AND Sales_Play__c in :salesPlayIds];
        if(OSPADeleteRecs.size() > 0)
            Database.delete(OSPADeleteRecs);    
    }
}