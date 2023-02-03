public without sharing class LeadHelper 
{
    public static Boolean populateLatestLeadOnContact = true;
    public static void populateLatestLeadOnContact(Map<Id,Id> mapContactToLead)
    {

        if(!populateLatestLeadOnContact)
            return;

        List<Contact> listOfContacts = new List<Contact>();
        listOfContacts = [Select Id,Associated_Lead__c, Validation_Override__c from Contact where Id in : mapContactToLead.keySet()];
        if(listOfContacts.size()>0)
        {
            for(Contact c : listOfContacts)
            {
                c.Associated_Lead__c = mapContactToLead.get(c.Id);
                c.Validation_Override__c = true;
            }

            update listOfContacts;
        }

        populateLatestLeadOnContact = false;

    }
}