/** Cron job which runs daily for USD conversions of oppty and oppty line items
 * Sonali Tandon 30th November 2015

 SFDC- 1453 Made code generic for MRR-USD MRR pairs on Opportunity and OpportunityLineItems 
**/
global class CronCurrencyToUsdConversionBatchClass implements Database.Batchable<sObject>, Database.Stateful
{
 

    public static Boolean nowRunningDataFix =false;
    global DMLResults results;
    global final String query;
    public Static Boolean dissableTriggerFlag=true; //SFORCE-146

     
     global CronCurrencytoUsdConversionBatchClass()
     {
 
        nowRunningDataFix = false;
        List<String> parameters = OpportunityUtilClass.buildSOQLParametersForUSDConversion('Opportunity');

        al.SoqlBuilder queryBuilder = new al.SoqlBuilder()
                                      .selectx(parameters)
                                      .fromx('Opportunity')
                                      .wherex(new al.AndCondition()
                                      .add(new al.FieldCondition('CloseDate').greaterThanOrEqualTo(new al.DateFormula().last(al.UnitOfTime.Month)))
                                      .add(new al.FieldCondition('StageName').notEquals('Closed Admin')));
        query = queryBuilder.toSoql();
        results= new DMLResults(); 
     }
     
     global Database.QueryLocator start(Database.BatchableContext BC)
     {
          return Database.getQueryLocator(query);
      }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        nowRunningDataFix = true; 
        System.Debug(LoggingLevel.ERROR,'checkpoint X: in execute' + scope);
        List<Opportunity> listOfOpenOpportunities = (List<Opportunity>)scope;

        if(listOfOpenOpportunities.size()>0)
        {
            List<Id> listOfOpportunityIds                                                       = new List<Id>();
            List<OpportunityLineItem> listOfOpportunityLineItemsAssociatedWithOpenOpportunities = new List<OpportunityLineItem>();
            List<sObject> listOfSObjects                                                       = new List<sObject>();
            List<sObject> listOfOpportunityObjects                                             = new List<sObject>();
            List<sObject> listOfProductObjects                                                 = new List<sObject>();

 
            // add all opportunities to Master Sobject list
            listOfSObjects.addAll((List<SObject>)listOfOpenOpportunities);
            
            for(Opportunity currentOpp: listOfOpenOpportunities)    
                listOfOpportunityIds.add(currentOpp.Id);  

            List<String> parameters = OpportunityUtilClass.buildSOQLParametersForUSDConversion('OpportunityLineItem');

            String soql =  new al.SoqlBuilder()
                           .selectx(parameters)
                           .fromx('OpportunityLineItem')
                           .wherex(new al.SetCondition('OpportunityId').inx(listOfOpportunityIds))
                           .toSoql();

            System.debug(LoggingLevel.ERROR,'OLI query' + soql);

            // get line items associated to  opportunities
            listOfOpportunityLineItemsAssociatedWithOpenOpportunities = Database.query(soql);

            // add all line items to master list 
            if(listOfOpportunityLineItemsAssociatedWithOpenOpportunities.size()>0)
                listOfSObjects.addAll((List<SObject>)listOfOpportunityLineItemsAssociatedWithOpenOpportunities);

            if(listOfSObjects.size()>0)
            {
              // perform conversion
              listOfSObjects = OpportunityUtilClass.genericPopulateUSDOnChangeOfFields(listOfSObjects,true);

              //SFORCE-146 Breaking the transection of oppty and product
              for(SObject objectInstance : listOfSObjects){

                    if(objectInstance.getSObjectType() == Opportunity.getSObjectType())
                            listOfOpportunityObjects.add(objectInstance); 
                     else
                          listOfProductObjects.add(objectInstance);
              }

              dissableTriggerFlag=false;
            if(listOfOpportunityObjects.size()>0)
              results.add(Database.update(listOfOpportunityObjects,false),listOfOpportunityObjects);
            if(listOfProductObjects.size()>0)
              results.add(Database.update(listOfProductObjects,false),listOfProductObjects);


            }
        }

    }
   
    global void finish(Database.BatchableContext BC)
    {

        results.withJobName('\'Dollar Value Convert\'').toAddress(GsmUtilClass.getGSMSettingValue('CronCurrToUsdBatch_ErrorMailId')).sendLogMail();
        results.withClassName('CronCurrencyToUsdConversionBatchClass').insertRecordsInErrorLog();

    }
 }