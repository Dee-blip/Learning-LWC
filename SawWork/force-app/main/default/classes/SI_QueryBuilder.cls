//Modified by ssawhney for CR 2012122 - Enable the search page to navigate directly to an Incident record if incident number is provided
public class SI_QueryBuilder extends EB_Filter
{

   public Map<String,String> LongTextAreaFields {get { if(LongTextAreaFields==null) {  LongTextAreaFields = new Map<String,String>();} return LongTextAreaFields;}set;}
   public override string queryGeneratorForOtherDT(EB_FilterObject.FieldObject fo)
   {
    String returnString = '';
        LongTextAreaFields.put(fo.api,fo.TextboxValue);
    
    
    
    if(fo.TextboxValue==''||fo.TextboxValue==null)
    {
         LongTextAreaFields.remove(fo.api);
    }
    
    return returnString;
   }
  
  public override PageReference clearFilter() 
  {
      strLikeSearch ='';
      SortField = SortOrder =null;
      LongTextAreaFields = new Map<String,String>();
      pageController.clearSearch(); 
      return null;
  
  }
  
  //Added by ssawhney for CR 2012122
  public override PageReference ApplyFilter() 
  {
      super.ApplyFilter();
      //redirect to the record directly if only one record is found
      if(pageController != null)
      {
          if(pageController instanceof SI_ServiceIncidentSearch)
          {
              SI_ServiceIncidentSearch controller = (SI_ServiceIncidentSearch) pageController;
              if(controller.getServiceIncidents().size() == 1)
              {
                 PageReference ref = new PageReference('/'+ controller.getServiceIncidents()[0].Id);
                 ref.setRedirect(true);
                 return ref;
              }
          }
      }
      return null;
  }
}