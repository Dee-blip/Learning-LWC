global class SawyerBatchClass implements Database.Batchable<sObject>, Database.Stateful
{
    global DMLResults results;
    global final sObjectType stype;
    global String query;
    global final Integer stepNumber;
    global final List<String> logObjects = new List<String>{'SawedLawg__c'
        , 'Mulesoft_Polling__c', 'Callout_Log__c', 'Beep__c'};

    private void init()
    {
        String sotype = logObjects.get(this.stepNumber);
        if(this.stepNumber<logObjects.size()-1)
        {
            query = new al.SoqlBuilder()
                .selectx(new List<String>(GSMSettings.getSetOfStrings('SawyerFields_'+sotype.replace('__c',''))))
                .fromx(sotype)
                .wherex(new al.AndCondition()
                        .add(new al.FieldCondition('IsDeleted').equals(false))
                        .add(new al.OrCondition()
                            .add(new al.FieldCondition('Fingerprint__c').equals(null))
                            .add(new al.FieldCondition('Beep__c').equals(null))))
                .orderByx(new al.OrderBy('CreatedDate').descending())
                .toSoql();
        }
        else
        {
            // last step is summarization
            query='select id from Beep__c';
        }
        System.Debug(LoggingLevel.Error, 'AGH_D soql'+query);
    }

    global SawyerBatchClass(Integer stepNumber)
    {
        this.stepNumber = stepNumber;
        init();
    }

    global SawyerBatchClass()
    {
        this.stepNumber = 0;
        init();
    }

    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(query);
    }


    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
            if(stepNumber<logObjects.size()-1)
            {
                Sawyer.fingerprint(scope);
            }
            else
            {
                // last step is summarization
                Sawyer.summarizeBeeps(scope);
            }
    }

    global void finish(Database.BatchableContext BC)
    {
        if(this.stepNumber<this.logObjects.size()-1)
        {
            SawyerBatchClass sbc = new SawyerBatchClass(this.stepNumber + 1);
            Database.executeBatch(sbc);
        }
    }

}