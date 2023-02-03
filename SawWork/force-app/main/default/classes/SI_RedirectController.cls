public class SI_RedirectController 
{
    public String IncidentName { get;  set;}
    public String getGetLocation() 
    {
       if(ApexPages.CurrentPage()!=null)
        {
            /* start of changes by vkrishna for CR 2065429  */
            try
            {
                IncidentName= ApexPages.CurrentPage().getParameters().get('Id');
                return '/apex/SI_ServiceIncidentSearch?id=' + IncidentName;       
            }
            /* end of changes by vkrishna for CR 2065429  */

            catch (exception ex)
            {
                return '';
            }            
        }
        return '';
    }
    /*
    public List<BMCServiceDesk__Incident__c> getIncidentList()
    {
        string temp  = getGetLocation();
        List<BMCServiceDesk__Incident__c> inclist = new List<BMCServiceDesk__Incident__c>();
        if(IncidentName!=null && IncidentName!='')
        {
            for(BMCServiceDesk__Incident__c incident : [select SI_Incident_Link__c from BMCServiceDesk__Incident__c where name like '%:IncidentName%'])
            {
                inclist.add(incident);
            }
        }
        return inclist;
    }
    */
}