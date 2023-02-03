// @author : Sonali Tandon -- standon@akamai.com
/* Developer: Ruchika Sharma 21/12/2015 3254591: SFDC-545 Maintain component Hierarchy and sorting
*/
public class NAPContentOverviewController {


public Id selectedPageId{get;set;}
public List<HierarchyItem> hierarchyItemList {get;set;}
public Map<Id,HierarchyItem> mapOfIdToHierarchyItem;
public Boolean flag {get;set;}
public String redirectTo {get;set;}

public Map<Id,List<Id>> mapOfParentToChildComponent;  
//CR 3254591: list to maintain component order based on order field in Nap page builder join
public List<Id>  hierarchyList;
public Map<Id,String> mapOfcomponentIdToComponentTitle; 
public Map<Id,String> mapOfcomponentIdToComponentType;     
public Map<Id, Integer> mapOfComponentIdToHierarchyIndex;
//CR 3254591: Security context not needed
// public Map<Id, NAP_Page_Security__c> mapOfIdToSecurityContext;

// inner wrapper class 
  public class HierarchyItem{

    public String componentTitle {get;set;}
    public Id componentId {get;set;}
    public String menuType {get;set;}
    public String componentValue {get;set;}
    //CR 3254591: Security context not needed
    //public Id securityId {get;set;}
    //public String securityDescription {get;set;}
    

    public HierarchyItem(String componentTitle,Id componentId,Integer componentHierarchyIndex, String componentType /*,Id securityId, String securityDescription*/)
    {
      String spaceCount = '';
      for(Integer i = 0 ; i < componentHierarchyIndex; i++)
          spaceCount = spaceCount  + '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';

      this.componentTitle = spaceCount + componentTitle;
      this.componentValue = componentTitle;
      this.componentId    = componentId;
      this.menuType = componentType;
      //this.securityId = securityId;
      //this.securityDescription = securityDescription;
    }
    // Implement the compareTo() method

}


// populate picklist with list of pages
public List<SelectOption> getpageList(){

    List<SelectOption> listOfPageNames = new List<SelectOption>();
    //default value 
    listOfPageNames.add(new SelectOption('--None--','--None--')); 
    for(NAP_Page_Builder__c page : [Select Id, Title__c from NAP_Page_Builder__c where Component_Type__c = 'Page'])
        listOfPageNames.add(new SelectOption(page.Id,page.Title__c)); 

    return listOfPageNames;
}

// on click of 'Go' - display page hierarchy with all it's components
public PageReference displayComponents(){

  mapOfParentToChildComponent       = new Map<Id,List<Id>>();
  mapOfcomponentIdToComponentTitle  = new Map<Id,String>();
  mapOfcomponentIdToComponentType   = new Map<Id,String>();
  mapOfComponentIdToHierarchyIndex  = new Map<Id,Integer>();
  // mapOfcomponentIdToComponentOrder  = new Map<Id,Decimal>();
  hierarchyList = new List<Id>();
  
  System.debug('selectedPageId' + selectedPageId);
  
  String selectedPageIdString       =  String.valueOf(selectedPageId);
  List<String> listOfPageId         = new List<String>{selectedPageIdString};
  List<String> listOfMainMenuIds    = new List<String>();
  List<String> listOfSubMenuIds     = new List<String>();
  List<String> listOfDetailMenuIds  = new List<String>();

  // generate main menus
  listOfMainMenuIds    = generateMenu(listOfPageId,'Main Menu',0);
  // generate sub menus
  listOfSubMenuIds     = generateMenu(listOfMainMenuIds,'Sub Menu',1);
  //generate detail menus
  listOfDetailMenuIds  = generateMenu(listOfSubMenuIds,'Detail Menu',2);
  
  System.debug('mapOfParentToChildComponent :' + mapOfParentToChildComponent);
  System.debug('mapOfcomponentIdToComponentTitle : ' + mapOfcomponentIdToComponentTitle);
  System.debug('mapOfComponentIdToHierarchyIndex: ' + mapOfComponentIdToHierarchyIndex);

  // generateSecurityContext(listOfMainMenuIds);

  generateHierarchy();

  if(hierarchyItemList.size()>0)
      flag = true;
  else
      flag = false;

  return null;
}

public void generateHierarchy(){

  mapOfIdToHierarchyItem = new Map<Id,HierarchyItem>();
  hierarchyItemList = new List<HierarchyItem>();
  HierarchyItem item;

  // remove page id as it is already selected in picklist 
  mapOfParentToChildComponent.remove(selectedPageId);
  system.debug('mapOfParentToChildComponent: '+mapOfParentToChildComponent);

  for(Id parentId : hierarchyList)
  {   
      
      //CR 3254591: Security context not needed
      // if(mapOfIdToSecurityContext.containsKey(parentId))
      //   item = new HierarchyItem(mapOfcomponentIdToComponentTitle.get(parentId),parentId,mapOfComponentIdToHierarchyIndex.get(parentId),mapOfcomponentIdToComponentType.get(parentId), mapOfIdToSecurityContext.get(parentId).Id, mapOfIdToSecurityContext.get(parentId).Description__c,mapOfcomponentIdToComponentOrder.get(parentId));
      // else
    item = new HierarchyItem(mapOfcomponentIdToComponentTitle.get(parentId),parentId,mapOfComponentIdToHierarchyIndex.get(parentId),mapOfcomponentIdToComponentType.get(parentId)/*,null,''*/);
    
    mapOfIdToHierarchyItem.put(parentId,item);
      
      if(mapOfParentToChildComponent.containsKey(parentId))  
      {   
          for(Id childId : mapOfParentToChildComponent.get(parentId))
          {
            if(mapOfcomponentIdToComponentTitle.containsKey(childId) && mapOfComponentIdToHierarchyIndex.containsKey(childId))
            {
                //CR 3254591: Security context not needed
               // if(mapOfIdToSecurityContext.containsKey(childId))
               //    item = new HierarchyItem(mapOfcomponentIdToComponentTitle.get(childId),childId,mapOfComponentIdToHierarchyIndex.get(childId),mapOfcomponentIdToComponentType.get(childId), mapOfIdToSecurityContext.get(childId).Id, mapOfIdToSecurityContext.get(childId).Description__c,mapOfcomponentIdToComponentOrder.get(childId));
               // else
                  item = new HierarchyItem(mapOfcomponentIdToComponentTitle.get(childId),childId,mapOfComponentIdToHierarchyIndex.get(childId),mapOfcomponentIdToComponentType.get(childId)/*,null,''*/);
                
        system.debug('childId: '+childId+' item: '+item+' parentId: '+parentId);
                 mapOfIdToHierarchyItem.put(childId,item);
                 
                //SFDC-545: CR 3254591 - Detail Menu should come after Parent sub menu, Security Context should not be shown : rsharma
                 if(mapOfParentToChildComponent.containsKey(childId)){
                  
                    for(Id grandChildId: mapOfParentToChildComponent.get(childId)){
                      if(mapOfcomponentIdToComponentTitle.containsKey(grandChildId) && mapOfComponentIdToHierarchyIndex.containsKey(grandChildId))
                      {
                        //CR 3254591: Security context not needed
                        // if(mapOfIdToSecurityContext.containsKey(grandChildId))
                        //     item = new HierarchyItem(mapOfcomponentIdToComponentTitle.get(grandChildId),grandChildId,mapOfComponentIdToHierarchyIndex.get(grandChildId),mapOfcomponentIdToComponentType.get(grandChildId), mapOfIdToSecurityContext.get(grandChildId).Id, mapOfIdToSecurityContext.get(grandChildId).Description__c,mapOfcomponentIdToComponentOrder.get(grandchildId));
                        // else
                            item = new HierarchyItem(mapOfcomponentIdToComponentTitle.get(grandChildId),grandChildId,mapOfComponentIdToHierarchyIndex.get(grandChildId),mapOfcomponentIdToComponentType.get(grandChildId)/*,null,''*/);

                        mapOfIdToHierarchyItem.put(grandChildId,item);
                        
                      }
                    }//end of grandchildId for
                    
                }
            }

          } // end of childId for
      } 
    } // end of parentId for 

    hierarchyItemList.addAll(mapOfIdToHierarchyItem.values());
    
    System.debug('mapOfIdToHierarchyItem' + mapOfIdToHierarchyItem);

}

// common query generator 
public List<NAP_Page_Builder_Join__c> queryGenerator(List<String> parentIds, String childComponentType)
{
    //CR 3254591: Components should be in order defined in join object.
   String query = 'Select Order__c,NAP_Page_Builder_Child__c,NAP_Page_Builder_Parent__c,NAP_Page_Builder_Child__r.Title__c, NAP_Page_Builder_Parent__r.Title__c from NAP_Page_Builder_Join__c where NAP_Page_Builder_Parent__c in :parentIds AND NAP_Page_Builder_Child__r.Component_Type__c =\'' + childComponentType +'\''+' order by Order__c ASC' ;
   return Database.query(query);
  
}

// generic method to generate all parent - child menus 
public List<String> generateMenu(List<String> parentIds, String menuType, Integer menuHierarchyIndex)
{

   List <String> childIds                  = new List<Id>();
   List<NAP_Page_Builder_Join__c> menuList = new List<NAP_Page_Builder_Join__c>();
   menuList = queryGenerator(parentIds,menuType);
   
  if(menuList.size()>0)
  {
     for(NAP_Page_Builder_Join__c menuItem : menuList)
    {
      // map of parent id -> list of child ids 
      if (!mapOfParentToChildComponent.containsKey(menuItem.NAP_Page_Builder_Parent__c)){
                  mapOfParentToChildComponent.put(menuItem.NAP_Page_Builder_Parent__c, new  List<Id>{menuItem.NAP_Page_Builder_Child__c});
                  hierarchyList.add(menuItem.NAP_Page_Builder_Child__c);
          }
      else{
          mapOfParentToChildComponent.get(menuItem.NAP_Page_Builder_Parent__c).add(menuItem.NAP_Page_Builder_Child__c);
          hierarchyList.add(menuItem.NAP_Page_Builder_Child__c);
          }
      System.debug('NAP_Page_Builder_Parent__r.Title__c,NAP_Page_Builder_Child__r.Title__c' +menuItem.NAP_Page_Builder_Parent__r.Title__c+ menuItem.NAP_Page_Builder_Child__r.Title__c);
      
      mapOfcomponentIdToComponentTitle.put(menuItem.NAP_Page_Builder_Child__c,menuItem.NAP_Page_Builder_Child__r.Title__c);
      mapOfComponentIdToHierarchyIndex.put(menuItem.NAP_Page_Builder_Child__c,menuHierarchyIndex);
      mapOfcomponentIdToComponentType.put(menuItem.NAP_Page_Builder_Child__c,menuType);
      childIds.add(String.valueOf(menuItem.NAP_Page_Builder_Child__c));
    }
  }
  return childIds;
 
}

  //CR 3254591: Security context not needed
  // public void generateSecurityContext(List<String> listOfMainMenuIds)
  // {
  //   mapOfIdToSecurityContext = new Map<Id,NAP_Page_Security__c>();

  //   String query = 'Select Id,Security_Type_Id__c, Description__c, NAP_Page_Builder__c, Type__c from NAP_Page_Security__c where NAP_Page_Builder__c  IN : listOfMainMenuIds';
  //   List<NAP_Page_Security__c>  listOfSecurityContext = new List<NAP_Page_Security__c>();
  //   listOfSecurityContext = Database.query(query);

  //   for(NAP_Page_Security__c securityItem : listOfSecurityContext)
  //   {
  //       mapOfIdToSecurityContext.put(securityItem.NAP_Page_Builder__c,securityItem);
  //   }

  // }
   public PageReference pageRedirect(){

    Schema.SObjectType convertType = Schema.getGlobalDescribe().get(redirectTo);
    Schema.DescribeSObjectResult r = convertType.getDescribe();
    String objectPrefix = r.getKeyPrefix();
    System.debug(objectPrefix);
    
    PageReference pageURL = new PageReference('/' + objectPrefix + '/e?');

    pageURL.setRedirect(true);

    return pageURL;

  }



}