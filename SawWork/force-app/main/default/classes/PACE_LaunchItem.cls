/***
    PACE_LaunchItem
    @version 1.0
    @author Hitesh Chawda <hchawda@akamai.com>
    @Description : This Class is used for auto populating fields on creation of Catalog Update record from Program object
    @History
    --Developer           --Date            --Change
    Hitesh Chawda          28-09-2012       1881694
*/
global class PACE_LaunchItem {

// This is for prepopulating the program page
    Webservice static String Initialize_ProgramForCatalogUpdate(Id l_productManagerId, 
        String l_productManagerName, String l_productLineName, Id l_productLineId,String l_division, 
        Id l_program,String l_programName)
    {
        System.Debug('Entered to Initialize');
        System.Debug(l_programName);
        System.Debug(l_program);
        // Initialize static variables
        String prefix = '/' + Launch_Item__c.sObjectType.getDescribe().getKeyPrefix() + '/e?';
        String conceptPrefix = '/' + l_program;
        
        PageReference returnURL = new Pagereference (prefix);   

        PACE_Field_Keys__c mc = PACE_Field_Keys__c.getValues('PACE');

        // Set the "Record Type" to "PLM Task"  
        returnURL.getParameters().put(mc.L_Product_Manager_Id__c, l_productManagerId);      
        returnURL.getParameters().put(mc.L_Product_Manager_Name__c, l_productManagerName);      
            
        returnURL.getParameters().put(mc.L_Product_Line__c, l_productLineName);     
        returnURL.getParameters().put(mc.L_Product_Line_Id__c   , l_productLineId);     
        returnURL.getParameters().put(mc.L_Division__c, l_division);    
        returnURL.getParameters().put('Division', l_division);  
        returnURL.getParameters().put(mc.ProgramId__c, l_program);  
        returnURL.getParameters().put(mc.ProgramName__c, l_programName);    
        returnURL.getParameters().put('retURL', conceptPrefix); 
        System.Debug(mc.ProgramId__c);
        // Set the navigation parameters for the URL
        returnURL.setRedirect(true);
        return  returnURL.getUrl(); 
    }
    
    public static void updateProgramField(List<Launch_Item__c> liList)
    {
        List<PACE_Program__c> programList = new List<PACE_Program__c>();
        List<Id> programListId = new List<Id>();
        
        for(Launch_Item__c li : liList)
        {
			   programListId.add(li.Program__c);     
        }
        if(programListId.size() > 0)
        {
        	programList = [Select Id,Name, hasCatUpdateAttached__c from PACE_Program__c Where Id IN : programListId];
            if(programList.size() > 0)
            {
                for(PACE_Program__c programRecord :programList)
                    programRecord.hasCatUpdateAttached__c = True ;
            }
           
        }
        if(programList.size() > 0)
            update programList;
        
    }
}