@isTest(seeAllData=false)
private class L2Q_Case_DefaultValuesTest {
        static testmethod void getDefaultValues() {
                Account acc =  (Account)new SobjectBuilder(Account.sObjectType)
                              .eagerPopulate()
                              .put(Account.Type, 'Lead')
                              .create()
                              .getRecord();

                Opportunity oppty = (Opportunity)new SobjectBuilder(Opportunity.sObjectType)
                                    .eagerPopulate()
                                    .put(Opportunity.AccountId, acc.Id)
                                    .put(Opportunity.Deal_Type__c, 'Direct')
                                    .create()
                                    .getRecord();

                List<Opportunity> opptyList = new List<Opportunity>();
                opptyList.add(oppty);

                ApexPages.StandardSetController opptyController = new ApexPages.StandardSetController(opptyList);
                L2Q_Case_DefaultValues tempController = new L2Q_Case_DefaultValues(opptyController);
                System.AssertEquals(tempController.defaultValuesForCase, '');

                ApexPages.currentPage().getParameters().put('OpportunityId', oppty.Id);
                tempController = new L2Q_Case_DefaultValues(opptyController);
                Map<String, GSM_GenericFormController.FieldDescriptor> mappOfFieldVsDefaultValues = (Map<String, GSM_GenericFormController.FieldDescriptor>)JSON.deserialize(tempController.defaultValuesForCase, Map<String, GSM_GenericFormController.FieldDescriptor>.Class);
                System.AssertEquals(mappOfFieldVsDefaultValues.get('Opportunity__c').value, String.valueOf(oppty.Id));

                ApexPages.currentPage().getParameters().put('AccountId', acc.Id);
                tempController = new L2Q_Case_DefaultValues(opptyController);
                mappOfFieldVsDefaultValues = (Map<String, GSM_GenericFormController.FieldDescriptor>)JSON.deserialize(tempController.defaultValuesForCase, Map<String, GSM_GenericFormController.FieldDescriptor>.Class);
                System.AssertEquals(mappOfFieldVsDefaultValues.get('AccountId').value, String.valueOf(acc.Id));
                System.AssertEquals(mappOfFieldVsDefaultValues.get('Opportunity__c').value, String.valueOf(oppty.Id));
        }
}