@isTest(seeAllData=false)
public class GSM_GenericFormControllerTest {

        static testmethod void getSectionValues() {
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

                Map<Object, Object> mappOfFieldVsDefaultValues = new Map<Object, Object>();
                GSM_GenericFormController.FieldDescriptor eachSectionFields = new GSM_GenericFormController.FieldDescriptor();
                eachSectionFields.value = String.valueOf(oppty.Id);
                mappOfFieldVsDefaultValues.put('Opportunity__c', eachSectionFields);

                eachSectionFields = new GSM_GenericFormController.FieldDescriptor();
                eachSectionFields.value = String.valueOf(acc.Id);
                eachSectionFields.label = 'Label';
                eachSectionFields.isRequired = false;
                eachSectionFields.isUpdatable = false;
                eachSectionFields.overRidePickListVals = false;
                eachSectionFields.fieldType = 'REFERENCE';
                eachSectionFields.isReadOnly = false;
                eachSectionFields.placeHolder = 'PlaceHolder';
                eachSectionFields.helpText = 'Helptext';
                eachSectionFields.lookupFilterQuery = 'LookupFilter';
                mappOfFieldVsDefaultValues.put('AccountId', eachSectionFields);

                RecordType manSecRTp = [Select Id, Name from RecordType Where Name = 'Managed Security'];
                RecordType techRTP = [Select Id, Name from RecordType Where Name = 'Technical'];

                String returnVal = GSM_GenericFormController.getSectionValues('Case', mappOfFieldVsDefaultValues, 'Case', manSecRTp.Id);
                returnVal = GSM_GenericFormController.getSectionValues('Case', mappOfFieldVsDefaultValues, 'Case', techRTP.Id);
                mappOfFieldVsDefaultValues = new Map<Object, Object>();
                returnVal = GSM_GenericFormController.getSectionValues('SFDC_MDF__c', mappOfFieldVsDefaultValues, 'SFDC_MDF__c', '');

                GSM_GenericFormController.EachValue eachVal = new GSM_GenericFormController.EachValue();
                eachVal.label = 'TestLabel';
                eachVal.validFor = new List<Integer>();
                eachVal.validFor.add(1);
                eachVal.value = 'Test Value';

                GSM_GenericFormController.EachFieldValueWrapper eachFDWrap = new GSM_GenericFormController.EachFieldValueWrapper();
                eachFDWrap.values = new List<GSM_GenericFormController.EachValue>();
                eachFDWrap.values.add(eachVal);
                eachFDWrap.defaultValue = eachVal;
                eachFDWrap.controllerValues = new Map<String,String>();
                eachFDWrap.controllerValues.put('TestField', '0');
                eachFDWrap.controllerValues.put('TestField2', '1');

                GSM_GenericFormController.mapOfFieldsVsPicklistDescribe = new GSM_GenericFormController.PickListFieldWrapper();
                GSM_GenericFormController.mapOfFieldsVsPicklistDescribe.picklistFieldValues = new Map<String, GSM_GenericFormController.EachFieldValueWrapper>();
                GSM_GenericFormController.mapOfFieldsVsPicklistDescribe.picklistFieldValues.put('TestField', eachFDWrap);
                GSM_GenericFormController.mapOfFieldsVsPicklistDescribe.picklistFieldValues.put('TestField2', eachFDWrap);

                List<String> testRTBP = GSM_GenericFormController.getRecordTypeBasedPicklistVals('TestField');
                //String defaultVal = GSM_GenericFormController.getDefaultValueOfPicklist('TestField');

                List<String> listOfDependentFields = new List<String>();
                listOfDependentFields.add('TestField2');

                Map<String, Map<String, List<String>>> dependencyMap = GSM_GenericFormController.getDependencyMap('TestField', listOfDependentFields);

                GSM_GenericFormController.FieldDescriptor fd = new GSM_GenericFormController.FieldDescriptor();
                fd.isDependentField = false;
                fd.isDynamicLookup = false;
                fd.dependedntPicklistsMap = 'Map';
                fd.dynamicWhereClause = 'Dynamic Where';
                fd.listOfDependentFields = new List<String>();
                fd.dynamicLookupDependencyOn = '';

                GSM_GenericFormController.SectionDescriptor sd = new GSM_GenericFormController.SectionDescriptor();
                sd.editLayoutProperties = true;
                sd.sectionName = 'Section Name';
                sd.layoutPropertiesDetails = new GSM_GenericFormController.LayoutProperties();
                sd.layoutPropertiesDetails.caseAssignmentCheckboxRequired = true;
                sd.layoutPropertiesDetails.caseAssignmentCheckboxDefaultValue = true;
                sd.layoutPropertiesDetails.emailNotificationCheckboxRequired = true;
                sd.layoutPropertiesDetails.emailNotificationCheckboxDefaultValue = true;
        }

        static testmethod void insertObject() {
                Map<String, Object> insertMap = new Map<String, Object>();
                Object value;
                String stringVal = '';
                // Add account Id

                Account accRec = utilTestClass.CreateAccount('Partner Supp Generic Acc');
                insert accRec;

                accRec.IsPartner = true;
                accRec.Validation_Override__c=true;
                update accRec;

                stringVal = String.valueOf(accRec.Id);
                value = (Object) stringVal;
                insertMap.put('Account__c', value);

                stringVal = 'Yes';
                value = (Object) stringVal;
                insertMap.put('SOE_or_PubSec_Event__c', value);

                stringVal = '2018-07-03';
                value = (Object) stringVal;
                insertMap.put('Activity_Date__c', value);

                stringVal = 'Yes';
                value = (Object) stringVal;
                insertMap.put('Activity_In_Plan__c', value);

                stringVal = 'Partner';
                value = (Object) stringVal;
                insertMap.put('Activity_Leader__c', value);

                stringVal = '123';
                value = (Object) stringVal;
                insertMap.put('Amount__c', value);

                stringVal = 'Akamai Followup';
                value = (Object) stringVal;
                insertMap.put('Campaign_Lead_Followup__c', value);

                stringVal = 'BRL';
                value = (Object) stringVal;
                insertMap.put('CurrencyIsoCode', value);

                stringVal = 'Akamai requires pre-approval by Akamai Senior Management and Global Compliance for all State-Owned Entity (SOE) programs. In the FR description field, please provide the following: 1. Overview of the SOE program/activity 2. Titles of attendees, participants, or recipients 3. Description and per capita spend of any offering associated with the SOE program including but not limited to: gifts, meals, entertainment, travel, sponsorships, passes, accommodations, political/charitable contributions, etc. – to (or at the request of) any employee of a Government entity or State-Owned Enterprise. NOTE: If approved, SOE compliance documentation will be required when submitting the Fund Claim such as: List of attendees, participants, or recipients with: 1. Name 2. Title 3. SOE Entity 4. Per capita spend 5. Type of offering(s) received (Gift, meal, entertainment, travel, etc.)';
                value = (Object) stringVal;
                insertMap.put('FR_SOE_Text__c', value);

                stringVal = 'Yes';
                value = (Object) stringVal;
                insertMap.put('Marketing_Plan__c', value);

                stringVal = 'FR Name Test';
                value = (Object) stringVal;
                insertMap.put('Name', value);

                stringVal = '1';
                value = (Object) stringVal;
                insertMap.put('Partner_Anticipated_Deals__c', value);

                stringVal = 'New Customer';
                value = (Object) stringVal;
                insertMap.put('Partner_Anticipated_Optys__c', value);

                stringVal = '50';
                value = (Object) stringVal;
                insertMap.put('Partner_Campaign_Contribution__c', value);

                stringVal = '1';
                value = (Object) stringVal;
                insertMap.put('Partner_Campaign_Lead_Count__c', value);

                stringVal = 'Camp';
                value = (Object) stringVal;
                insertMap.put('Partner_Campaign_Objective__c', value);

                stringVal = 'Camp';
                value = (Object) stringVal;
                insertMap.put('Partner_Campaign_Overview__c', value);

                stringVal = '1';
                value = (Object) stringVal;
                insertMap.put('Partner_Campaign_Reach__c', value);

                stringVal = 'Marketing Through';
                value = (Object) stringVal;
                insertMap.put('Partner_Campaign_Type__c', value);

                stringVal = '1';
                value = (Object) stringVal;
                insertMap.put('Partner_Anticipated_Deals__c', value);

                stringVal = '1';
                value = (Object) stringVal;
                insertMap.put('Partner_Deal_Registrations__c', value);

                stringVal = '1';
                value = (Object) stringVal;
                insertMap.put('Partner_Monthly_Revenue__c', value);

                stringVal = '1';
                value = (Object) stringVal;
                insertMap.put('Partner_Split_Justification__c', value);

                stringVal = '<p>None</p>';
                value = (Object) stringVal;
                insertMap.put('Private_Note__c', value);

                stringVal = '2018-07-31';
                value = (Object) stringVal;
                insertMap.put('Program_End_Date__c', value);

                stringVal = 'Dummy Loc';
                value = (Object) stringVal;
                insertMap.put('Program_Location__c', value);

                stringVal = 'Advertising';
                value = (Object) stringVal;
                insertMap.put('Program_Type__c', value);

                stringVal = 'Draft';
                value = (Object) stringVal;
                insertMap.put('Status__c', value);

                String returnVal = GSM_GenericFormController.insertObject(insertMap, 'SFDC_MDF__c','',false, false);
                //returnVal = GSM_GenericFormController.insertObject(insertMap, 'SFDC_MDF__c','',true, true);
                insertMap = new Map<String, Object>();

                returnVal = GSM_GenericFormController.insertObject(insertMap, 'Case','',true, true);

        }
}