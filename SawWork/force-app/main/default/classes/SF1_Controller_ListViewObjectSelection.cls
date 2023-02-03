public class SF1_Controller_ListViewObjectSelection {

    @AuraEnabled
    public static String[] getEnabledObjectsForListView()
    {
    	List<String> hSetting = new List<String>();
    	if(SF1_Enabled_ListViews__c.getInstance() != null && SF1_Enabled_ListViews__c.getInstance().Enabled_Objects__c != null && SF1_Enabled_ListViews__c.getInstance().Enabled_Objects__c != '')
    	{
        	for( String oName : SF1_Enabled_ListViews__c.getInstance().Enabled_Objects__c.split(','))
            {
                if(oName == 'SFDC_MDF__c')
                {
                    oName = 'Fund Request';
                }
                hSetting.add(oName);
            }

    	}
       
        return hSetting;

    }



}