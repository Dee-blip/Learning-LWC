trigger GDRAT_Territory_Sec_Assign_Trigger on Territory_Security_Assignment__c (before insert,before update) {

    GDRAT_Territory_Sec_Assign_president.createHandler(Territory_Security_Assignment__c.sObjectType);
}