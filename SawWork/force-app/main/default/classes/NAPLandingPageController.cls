global class NAPLandingPageController {
    
    public String userName {get;set;}
    public String carouselImage {get;set;}
    public Boolean errorExists {get;set;}
    public String errorMessage {get;set;}
    
    public NAPLandingPageController(){
        errorExists = false;
      userName =  UserInfo.getFirstName();
      String errorCode = System.currentPagereference().getParameters().get('error_code');


      if(errorCode=='404')
      {
          errorMessage = 'Sorry! Such a page doesnt exist.';
          errorExists = true;
      }
      else if(errorCode=='401')
      {
          errorMessage = 'You do not have permission to view that page. If you should have access to that resource, please contact the Administrator for your Partner Account or the person that provided the link to have them provision access.';
          errorExists = true;
      }
      else if(errorCode=='403')
      {
          errorExists=true;
          errorMessage = 'You do not have sufficient privileges to download that file.';
      }
    }
        
    public class PermanentMenuItemWrapper
    {
        public String menuTitle;
        public String link;
    
            PermanentMenuItemWrapper(){
            
        }
    }
  
     public class CarouselItemWrapper
    {
        public String menuTitle;
        public String menuDescription;
        public String link;
        public String image;
        private Integer order;
        public Boolean active = false;
    
            CarouselItemWrapper(){
            
        }
    }
    public class PageMenuItemWrapper
    {
        public String menuTitle;
        public String menuDescription;
        public String link;
        public String image;
        public Id menuId;
        public Boolean active;
    
            PageMenuItemWrapper(){
            
        }
    }
    
    
    public String getMenuItems(){
        List<PageMenuItemWrapper> pagemenuItemWrapperList = new List<PageMenuItemWrapper>();
        
        for(NAP_Page_Builder__c  menuItem : [Select Id,Name,Title__c, Component_Type__c , Component_Order__c,Description__c,Link__c,Image__c from NAP_Page_Builder__c where Component_Type__c ='Page' ORDER BY Component_Order__c ASC ])
        {
                PageMenuItemWrapper wrapperItem             = new PageMenuItemWrapper();
                wrapperItem.menuTitle                       = menuItem.Title__c;
                wrapperItem.menuDescription                 = menuItem.Description__c;
                wrapperItem.image                           = menuItem.Image__c;
                wrapperItem.menuId                          = menuItem.Id;
                wrapperItem.active = NAPWatchman.allows(menuItem);
                wrapperItem.link = NAPURLService.getLink(menuItem);
                pagemenuItemWrapperList.add(wrapperItem);      
        }

        
        System.debug('Menu items::after ' + pagemenuItemWrapperList); 
        return JSON.serialize(pagemenuItemWrapperList); 

    }
    
    public String getPermanentMenuItems(){
    
    List<PermanentMenuItemWrapper> permanentMenuItemWrapperList = new List<PermanentMenuItemWrapper>();
        for(NAP_Page_Builder__c  permanentmenuItem : [Select Title__c, Component_Type__c , Component_Order__c,Link__c from NAP_Page_Builder__c where Component_Type__c ='Permanent Menu' ORDER BY Component_Order__c ASC ]){
            
            PermanentMenuItemWrapper wrapperItem = new PermanentMenuItemWrapper();
            wrapperItem.menuTitle = permanentmenuItem.Title__c;
            wrapperItem.link = permanentmenuItem.Link__c;
            permanentMenuItemWrapperList.add(wrapperItem);        
        }
        System.debug('Permanent Menu items' + permanentMenuItemWrapperList);     
        return JSON.serialize(permanentMenuItemWrapperList); 
    
    }
    
     public String getCarouselItems(){
        
    
        List<CarouselItemWrapper> carouselItemWrapperList = new List<CarouselItemWrapper>();
        
        //SFDC-1344
        List<NAP_Page_Builder__c> carouselPageBuilders = [Select Title__c, Image__c,Component_Type__c , Description__c,Component_Order__c,Link__c from NAP_Page_Builder__c where Component_Type__c ='Carousel' ORDER BY Component_Order__c ASC ];

        List<String> allCarouselImageList = new List<String>();
        for(NAP_Page_Builder__c eachCarouselPageBuilder : carouselPageBuilders)
        {
          allCarouselImageList.add(eachCarouselPageBuilder.Image__c);
        }

        List<Document> carouselImages = [Select Id,Name from Document where Name = :allCarouselImageList];

        Map<String,Id> imageToId = new Map<String,Id>();

        for(Document eachCarouselImage : carouselImages)
        {
            imageToId.put(eachCarouselImage.Name, eachCarouselImage.Id);
        }

        for(NAP_Page_Builder__c  carouselitem : carouselPageBuilders){
            
            CarouselItemWrapper wrapperItem = new CarouselItemWrapper();
            wrapperItem.menuTitle = carouselitem.Title__c;
            wrapperItem.link = carouselitem.Link__c;
            wrapperItem.menuDescription = carouselitem.Description__c;
            wrapperItem.order = Integer.valueOf(carouselitem.Component_Order__c)-1;
            for(Document eachCarouselImage : carouselImages)
            {
              if(eachCarouselImage.Name.equalsIgnoreCase(carouselitem.Image__c))
              {
                carouselImage = System.URL.getSalesforceBaseUrl().toExternalForm()+'/servlet/servlet.ImageServer?id=' + imageToId.get(eachCarouselImage.Name) + '&oid=' + UserInfo.getOrganizationId();
                wrapperItem.image = carouselImage;
                break;
              }
            }
            //End of changes for SFDC-1344
            carouselItemWrapperList.add(wrapperItem);        
        }
        if(carouselItemWrapperList.size()>0)
            carouselItemWrapperList[0].active = true;
        System.debug('Carousel items' + carouselItemWrapperList);     
        return JSON.serialize(carouselItemWrapperList); 
    
    }

    public String getBillBoardText()
    {
      return JSON.serialize(BillBoardFlashController.getPartnerBillboardText());
    }
    
}